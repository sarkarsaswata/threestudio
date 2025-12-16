#!/bin/bash

set -e  # Exit on error
set -u  # Exit on undefined variable

# set some environment variables
export PYTHONWARNINGS=ignore
export CUDA_LAUNCH_BLOCKING=1
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# Source the virtual environment
if [ -f .venv/bin/activate ]; then
    source .venv/bin/activate
    echo "✨ Virtual environment activated"
    echo "🐍 Using python at: $(which python && python -V)"
else
    echo "❌ Error: Virtual environment not found at .venv/bin/activate"
    exit 1
fi

# Verify CUDA is available
if ! python -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
    echo "⚠️  Warning: CUDA not available in PyTorch"
else
    echo "✅ CUDA is available in PyTorch"
    echo "✅ CUDA Device Count: $(python -c 'import torch; print(torch.cuda.device_count())')"
    echo "✅ Cuda version: $(nvcc --version | grep release)"
fi

# Set GPU device (can be overridden via environment variable)
gpu="${GPU_DEVICE:-0}"
echo "🚀 Using GPU device: $gpu"

# Set default config and prompt if not provided
CONFIG="${CONFIG:-custom/gaussians2life/configs/bear.yaml}"
PROMPT="${PROMPT:-bear statue turns its head, static camera}"
MODE="${MODE:-train}"

# Validate MODE
if [[ ! "$MODE" =~ ^(train|test|eval|export)$ ]]; then
    echo "❌ Error: MODE must be 'train', 'test', 'eval', or 'export'. Got: $MODE"
    exit 1
fi

echo "📝 Config: $CONFIG"
echo "💭 Prompt: $PROMPT"
echo "🎯 Mode: $MODE"

# Build the mode flag (map eval -> validate to match launch.py)
case "$MODE" in
    train)
        MODE_FLAG="--train"
        ;;
    test)
        MODE_FLAG="--test"
        ;;
    eval)
        MODE_FLAG="--validate"
        ;;
    export)
        MODE_FLAG="--export"
        ;;
esac

# Print the full command before launching
python_cmd="python launch.py --config \"$CONFIG\" $MODE_FLAG --gpu \"$gpu\" system.prompt_processor.prompt=\"$PROMPT\""
echo "🔧 Executing: $python_cmd"

# Launch the main script
python launch.py \
    --config "$CONFIG" \
    $MODE_FLAG \
    --gpu "$gpu" \
    system.prompt_processor.prompt="$PROMPT"

# Usage examples:
# Use defaults (train mode)
# ./launch.sh

# Override with environment variables
# MODE=test GPU_DEVICE=1 PROMPT="different prompt" CONFIG="path/to/config.yaml" ./launch.sh

# Examples:
# MODE=train ./launch.sh                    # Training mode (default)
# MODE=test ./launch.sh                     # Testing mode (--test)
# MODE=eval ./launch.sh                     # Evaluation mode (mapped to --validate)
# MODE=train GPU_DEVICE=1 PROMPT="custom prompt" ./launch.sh