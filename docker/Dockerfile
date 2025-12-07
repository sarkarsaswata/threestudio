# Base image with CUDA support
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# --- 1. Set Environment Variables and Arguments ---
ARG USER_NAME=dreamer
ARG GROUP_NAME=dreamers
ARG UID=1000
ARG GID=1000

# Set CUDA/Toolchain Environment Variables
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
ENV LIBRARY_PATH=${CUDA_HOME}/lib64/stubs:${LIBRARY_PATH}
ENV PATH=/home/${USER_NAME}/.local/bin:${PATH}

# Set compiler versions
ENV CC=/usr/bin/gcc-10
ENV CXX=/usr/bin/g++-10

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
    gcc-10 \
    g++-10 \
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

# --- 4. Create Entrypoint Script ---
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Make create_venv.sh executable if it exists\n\
if [ -f ~/threestudio/create_venv.sh ] && [ ! -x ~/threestudio/create_venv.sh ]; then\n\
    chmod +x ~/threestudio/create_venv.sh\n\
fi\n\
\n\
# Activate virtual environment if it exists\n\
if [ -f ~/threestudio/.venv/bin/activate ]; then\n\
    source ~/threestudio/.venv/bin/activate\n\
fi\n\
\n\
# Execute the command passed to docker run\n\
exec "$@"' > /home/${USER_NAME}/entrypoint.sh \
    && chmod +x /home/${USER_NAME}/entrypoint.sh

# --- 5. Define Entrypoint and Default Command ---
ENTRYPOINT ["/home/dreamer/entrypoint.sh"]
CMD ["/bin/bash"]