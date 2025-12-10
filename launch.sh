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

echo "📝 Config: $CONFIG"
echo "💭 Prompt: $PROMPT"

# Launch the main script
python launch.py \
    --config "$CONFIG" \
    --train \
    --gpu "$gpu" \
    system.prompt_processor.prompt="$PROMPT"