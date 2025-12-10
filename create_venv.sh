#!/bin/bash

set -e  # Exit on error
set -u  # Exit on undefined variable

echo "🔧 Starting virtual environment setup..."
if [ -n "${UV_SYSTEM_PYTHON:-}" ]; then
    echo "♻️  UV_SYSTEM_PYTHON is set, unsetting..."
    unset UV_SYSTEM_PYTHON
else
    echo "ℹ️  UV_SYSTEM_PYTHON not set, skipping unset"
fi

# First we pin the python version to cp310 to avoid compatibility issues with some packages
echo "📌 Pinning Python version to 3.10..."
uv python pin cp310

# Create and activate virtual environment
echo "🏗️  Creating virtual environment..."
uv venv --python cp310

echo "⚡ Activating virtual environment..."
source .venv/bin/activate
echo "✨ Virtual environment activated"
echo "🐍 Using python at: $(which python)"

# Install Ruff globally
echo "🔍 Installing Ruff globally..."
uv tool install ruff@latest

# Install necessary packages
echo "📦 Installing PyTorch and dependencies..."
uv pip install torch torchvision nvidia-cudnn-cu11 "markupsafe>=2.1.2,<=2.1.5" xformers --index-url https://download.pytorch.org/whl/cu118

echo "⚙️  Installing build tools..."
uv pip install --upgrade pip setuptools ninja pybind11 cmake

echo "🎯 Installing nerfacc..."
uv pip install 'nerfacc @git+https://github.com/nerfstudio-project/nerfacc.git@v0.5.2' --no-build-isolation

echo "🔥 Installing tinycudann (this may take a while)..."
uv pip install 'tinycudann @git+https://github.com/NVlabs/tiny-cuda-nn.git#subdirectory=bindings/torch' --no-build-isolation

# Navigate to the project directory and install additional requirements
echo "📋 Installing gaussians2life requirements..."
cd custom/gaussians2life

if [ ! -f requirements.txt ]; then
    echo "❌ Error: requirements.txt not found in custom/gaussians2life"
    exit 1
fi

uv pip install -r requirements.txt --no-build-isolation

echo "🎨 Installing diff-gaussian-rasterization..."
if [ ! -d ./diff-gaussian-rasterization ]; then
    echo "❌ Error: ./diff-gaussian-rasterization directory not found"
    exit 1
fi
uv pip install ./diff-gaussian-rasterization --no-build-isolation

echo "🔢 Installing simple-knn..."
if [ ! -d ./simple-knn ]; then
    echo "❌ Error: ./simple-knn directory not found"
    exit 1
fi
uv pip install ./simple-knn --no-build-isolation

# Return to the original directory
cd ../..

# Compile unidepth
echo "🔨 Compiling UniDepth operations..."
if [ -d UniDepth/unidepth/ops/extract_patches ]; then
    cd UniDepth/unidepth/ops/extract_patches/
    if [ -f compile.sh ]; then
        bash compile.sh
    else
        echo "⚠️  Warning: compile.sh not found in UniDepth/unidepth/ops/extract_patches"
    fi
    cd ../../../..
else
    echo "⚠️  Warning: UniDepth directory not found, skipping compilation"
fi

# Verify installation
echo "🔍 Verifying installation..."
python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')" || echo "⚠️  Warning: PyTorch verification failed"

# Final message
echo "✅ Virtual environment setup complete!"
echo "💡 To activate: source .venv/bin/activate"