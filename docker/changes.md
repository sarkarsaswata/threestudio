# Changes Made to Support gaussians2life Project

## Dockerfile

**Purpose**: Build a container with CUDA 11.8 and install the gaussians2life project with all dependencies using `uv`.

**Key Changes**:

1. **Base Image**: Uses `nvidia/cuda:11.8.0-devel-ubuntu22.04` to match CUDA 11.8 requirement
2. **CUDA Architecture**: Set `TORCH_CUDA_ARCH_LIST="8.6"` and `TCNN_CUDA_ARCHITECTURES=86` for RTX A4000 GPU
3. **System Packages**: Added `ninja-build` for faster CUDA extension compilation
4. **UV Package Manager**: Installed `uv` for modern Python dependency management
5. **Project Setup**:
   - Copied entire threestudio project into container
   - Created virtual environment at .venv
   - Pre-installed PyTorch 2.0.1+cu118 from CUDA 11.8 index
6. **Commented Build Steps**: Prepared (but commented) installation commands for:
   - CUDA extensions (nerfacc, tiny-cuda-nn)
   - Local workspace extensions (diff-gaussian-rasterization, simple-knn)
   - DynamiCrafter model download

## compose.yaml

**Purpose**: Mount host project directory while preserving container's pre-built virtual environment.

**Key Changes**:

1. **Volume Mounting Strategy**:
   - Primary mount: Syncs entire `../` (threestudio) to container for live code editing
   - Anonymous volume: Masks `.venv` folder to prevent overwriting container's built environment with host's (missing) venv
2. **GPU Access**: Configured NVIDIA GPU reservation for CUDA workloads
3. **Interactive Mode**: Enabled `tty` and `stdin_open` for shell access

**Why the .venv masking?**  
The container builds CUDA extensions during image build. The anonymous volume ensures the host directory sync doesn't delete these pre-compiled binaries, allowing immediate use without rebuild.
