# Base image with CUDA support
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# --- 1. Set Environment Variables and Arguments ---
ARG USER_NAME=dreamer
ARG GROUP_NAME=dreamers
ARG UID=1000
ARG GID=1000

# Set CUDA/Toolchain Environment Variables
# For NVIDIA RTX A4000, use 8.6 (and 86); adjust as needed for other GPUs
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
ENV LIBRARY_PATH=${CUDA_HOME}/lib64/stubs:${LIBRARY_PATH}
ENV PATH=/home/${USER_NAME}/.local/bin:${PATH}
ENV PATH=/root/.local/bin:${PATH}

# Set compiler versions
ENV CC=/usr/bin/gcc-11
ENV CXX=/usr/bin/g++-11

# Set specific environment variables for TCNN/Torch build
ENV TORCH_CUDA_ARCH_LIST="8.6"
ENV TCNN_CUDA_ARCHITECTURES="86"
ENV TCNN_HALF_PRECISION=1

# uv link mode == copy
ENV UV_LINK_MODE="copy"
# Set longer timeout for large packages (300 seconds = 5 minutes)
ENV UV_HTTP_TIMEOUT=300
# suppress python warnings
ENV PYTHONWARNINGS=ignore

# --- 2. Install System Dependencies ---
# Install system dependencies as root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    gcc-11 \
    g++-11 \
    git \
    libegl1-mesa-dev \
    libgl1-mesa-dev \
    libgles2-mesa-dev \
    libglib2.0-0 \
    libjpeg-dev \
    libopencv-dev \
    libpng-dev \
    libsm6 \
    libtbb-dev \
    libxext6 \
    libxrender1 \
    ninja-build \
    pkg-config \
    python-is-python3 \
    python3.10-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

# --- 3. Setup Non-Root User and UV ---
# Create non-root user
RUN groupadd -g ${GID} ${GROUP_NAME} \
    && useradd -ms /bin/bash -u ${UID} -g ${GROUP_NAME} ${USER_NAME}

# Download the latest installer of uv
COPY --from=ghcr.io/astral-sh/uv:0.9.15 /uv /uvx /bin/

ENV UV_LINK_MODE=copy
ENV UV_VENV_CLEAR=1

# Switch to non-root user and set initial workdir
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}/threestudio

# --- 4. Define Default Command ---
CMD ["/bin/bash"]