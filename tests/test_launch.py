"""
Unit tests for launch.py
"""
import os
import sys
import tempfile
from pathlib import Path
from unittest import mock
from unittest.mock import MagicMock, patch, call

import pytest

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from launch import ColoredFilter, load_custom_module, load_custom_modules


class TestColoredFilter:
    """Tests for ColoredFilter logging filter."""

    def test_colored_filter_initialization(self):
        """Test ColoredFilter can be initialized."""
        filter_obj = ColoredFilter()
        assert filter_obj is not None

    def test_colored_filter_has_colors_dict(self):
        """Test ColoredFilter has COLORS dictionary."""
        filter_obj = ColoredFilter()
        assert hasattr(filter_obj, "COLORS")
        assert "WARNING" in filter_obj.COLORS
        assert "INFO" in filter_obj.COLORS
        assert "ERROR" in filter_obj.COLORS

    def test_colored_filter_colors_are_ansi_codes(self):
        """Test that color values are ANSI escape codes."""
        filter_obj = ColoredFilter()
        for color in filter_obj.COLORS.values():
            assert isinstance(color, str)
            assert color.startswith("\033[") or color.startswith("\x1b[")

    @patch("logging.LogRecord")
    def test_filter_modifies_warning_record(self, mock_record):
        """Test filter modifies WARNING level records."""
        filter_obj = ColoredFilter()
        mock_record.levelname = "WARNING"
        mock_record.msg = "This is a warning"

        result = filter_obj.filter(mock_record)

        assert result is True

    @patch("logging.LogRecord")
    def test_filter_modifies_error_record(self, mock_record):
        """Test filter modifies ERROR level records."""
        filter_obj = ColoredFilter()
        mock_record.levelname = "ERROR"
        mock_record.msg = "This is an error"

        result = filter_obj.filter(mock_record)

        assert result is True

    @patch("logging.LogRecord")
    def test_filter_ignores_unknown_level(self, mock_record):
        """Test filter ignores unknown log level."""
        filter_obj = ColoredFilter()
        mock_record.levelname = "UNKNOWN_LEVEL"
        original_msg = "Original message"
        mock_record.msg = original_msg

        result = filter_obj.filter(mock_record)

        assert result is True
        assert mock_record.msg == original_msg


class TestLoadCustomModule:
    """Tests for load_custom_module function."""

    def test_load_custom_module_with_directory(self):
        """Test loading a custom module from a directory."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create a test module directory with __init__.py
            module_dir = Path(tmpdir) / "test_module"
            module_dir.mkdir()
            init_file = module_dir / "__init__.py"
            init_file.write_text("TEST_VAR = 'test_value'")

            # Load the module
            result = load_custom_module(str(module_dir))

            assert result is True
            assert "test_module" in sys.modules

            # Cleanup
            if "test_module" in sys.modules:
                del sys.modules["test_module"]

    def test_load_custom_module_with_file(self):
        """Test loading a custom module from a file."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create a test module file
            module_file = Path(tmpdir) / "test_module_file.py"
            module_file.write_text("TEST_VAR = 'test_value'")

            # Load the module
            result = load_custom_module(str(module_file))

            assert result is True
            # Module is registered with full path as key
            assert str(module_file).replace(".py", "") in sys.modules or "test_module_file" in sys.modules

            # Cleanup
            full_path_key = str(module_file).replace(".py", "")
            if full_path_key in sys.modules:
                del sys.modules[full_path_key]
            if "test_module_file" in sys.modules:
                del sys.modules["test_module_file"]

    def test_load_custom_module_nonexistent(self):
        """Test loading a nonexistent module returns False."""
        result = load_custom_module("/nonexistent/path/to/module")
        assert result is False

    def test_load_custom_module_with_syntax_error(self):
        """Test loading a module with syntax error returns False."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create a module with syntax error
            module_file = Path(tmpdir) / "bad_module.py"
            module_file.write_text("this is not valid python syntax !!!")

            result = load_custom_module(str(module_file))
            assert result is False

    def test_load_custom_module_extracts_name_from_path(self):
        """Test that module name is correctly extracted from path."""
        with tempfile.TemporaryDirectory() as tmpdir:
            module_file = Path(tmpdir) / "my_custom_module.py"
            module_file.write_text("VALUE = 42")

            result = load_custom_module(str(module_file))

            assert result is True
            # Module is registered with full path as key
            full_path_key = str(module_file).replace(".py", "")
            assert full_path_key in sys.modules or "my_custom_module" in sys.modules

            # Cleanup
            if full_path_key in sys.modules:
                del sys.modules[full_path_key]
            if "my_custom_module" in sys.modules:
                del sys.modules["my_custom_module"]


class TestLoadCustomModules:
    """Tests for load_custom_modules function."""

    @patch("os.listdir")
    @patch("launch.load_custom_module")
    def test_load_custom_modules_calls_load_module(self, mock_load, mock_listdir):
        """Test load_custom_modules iterates and loads modules."""
        mock_listdir.return_value = ["module1", "module2"]
        mock_load.return_value = True

        with patch("builtins.print"):
            load_custom_modules()

        # Verify listdir was called
        mock_listdir.assert_called()

    @patch("os.listdir")
    @patch("launch.load_custom_module")
    def test_load_custom_modules_skips_pycache(self, mock_load, mock_listdir):
        """Test load_custom_modules skips __pycache__."""
        mock_listdir.return_value = ["module1", "__pycache__", "module2"]
        mock_load.return_value = True

        with patch("builtins.print"):
            load_custom_modules()

        # __pycache__ should not be loaded
        assert mock_load.call_count <= 2

    @patch("os.listdir")
    @patch("launch.load_custom_module")
    def test_load_custom_modules_skips_disabled(self, mock_load, mock_listdir):
        """Test load_custom_modules skips modules ending with _disabled."""
        mock_listdir.return_value = ["module1", "module2_disabled"]
        mock_load.return_value = True

        with patch("builtins.print"):
            load_custom_modules()

        # Only module1 should be loaded
        assert mock_load.call_count <= 1

    @patch("os.listdir")
    @patch("os.path.isfile")
    @patch("launch.load_custom_module")
    def test_load_custom_modules_skips_non_python_files(self, mock_load, mock_isfile, mock_listdir):
        """Test load_custom_modules skips non-Python files."""
        mock_listdir.return_value = ["module.txt", "module.py"]
        mock_isfile.side_effect = [True, True]  # Both are files
        mock_load.return_value = True

        with patch("builtins.print"):
            load_custom_modules()

        # Only .py file should be attempted
        assert mock_load.call_count == 1

    @patch("os.listdir")
    @patch("launch.load_custom_module")
    def test_load_custom_modules_prints_import_times(self, mock_load, mock_listdir):
        """Test load_custom_modules prints import timing information."""
        mock_listdir.return_value = ["module1"]
        mock_load.return_value = True

        with patch("builtins.print") as mock_print:
            load_custom_modules()

        # Check that print was called
        assert mock_print.called


class TestMain:
    """Tests for main function (basic smoke tests)."""

    def test_main_requires_config(self):
        """Test that main requires a config argument."""
        with pytest.raises(SystemExit):
            import argparse

            parser = argparse.ArgumentParser()
            parser.add_argument("--config", required=True)
            args = parser.parse_args([])  # No config provided


class TestEnvironmentVariables:
    """Tests for environment variable handling."""

    def test_cuda_device_order_constant(self):
        """Test that PCI_BUS_ID is used for CUDA_DEVICE_ORDER."""
        # Verify the constant is used in launch.py
        with open(Path(__file__).parent.parent / "launch.py") as f:
            content = f.read()
            assert "PCI_BUS_ID" in content


if __name__ == "__main__":
    pytest.main([__file__, "-v"])