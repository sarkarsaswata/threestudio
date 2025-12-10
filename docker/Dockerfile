# ------------------------------------------------------------
# Base CUDA development image
# ------------------------------------------------------------
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# ------------------------------------------------------------
# Arguments and Environment Setup
# ------------------------------------------------------------
ARG USER_NAME=dreamer
ARG GROUP_NAME=dreamers
# Default UID and GID set to 1008; modify as needed
ARG UID=1008
ARG GID=1008

# CUDA and compiler paths
ENV CUDA_HOME=/usr/local/cuda
ENV CC=/usr/bin/gcc-11
ENV CXX=/usr/bin/g++-11

# Clean unified PATH
ENV PATH=/home/${USER_NAME}/.local/bin:/root/.local/bin:${CUDA_HOME}/bin:${PATH}

# CUDA runtime and PyTorch build settings
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
ENV LIBRARY_PATH=${CUDA_HOME}/lib64/stubs:${LIBRARY_PATH}
ENV CUDA_LAUNCH_BLOCKING=1
ENV PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# Compute capability for RTX A4000
ENV TORCH_CUDA_ARCH_LIST="8.6"
ENV TCNN_CUDA_ARCHITECTURES="86"
ENV TCNN_HALF_PRECISION=1

# uv configuration
ENV UV_LINK_MODE=copy
ENV UV_VENV_CLEAR=1
ENV UV_HTTP_TIMEOUT=300
ENV PYTHONWARNINGS=ignore

# ------------------------------------------------------------
# System Dependencies
# ------------------------------------------------------------
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    tmux \
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

# ------------------------------------------------------------
# Pin gcc and g++ alternatives
# ------------------------------------------------------------
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 20 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 20

# ------------------------------------------------------------
# Create non-root user
# ------------------------------------------------------------
RUN groupadd -g ${GID} ${GROUP_NAME} \
    && useradd -ms /bin/bash -u ${UID} -g ${GROUP_NAME} ${USER_NAME}

# Prepare threestudio directory and fix permissions
RUN mkdir -p /home/${USER_NAME}/threestudio \
    && chown -R ${UID}:${GID} /home/${USER_NAME}

# ------------------------------------------------------------
# Install uv
# ------------------------------------------------------------
COPY --from=ghcr.io/astral-sh/uv:0.9.15 /uv /uvx /bin/

# ------------------------------------------------------------
# Switch to non-root user and set working directory
# ------------------------------------------------------------
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}/threestudio

# ------------------------------------------------------------
# Default command
# ------------------------------------------------------------
CMD ["/bin/bash"]
