FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ARG USER_NAME=dreamer
ARG GROUP_NAME=dreamers
ARG UID=1000
ARG GID=1000

# Set compute capability for nerfacc and tiny-cuda-nn
# For NVIDIA RTX A4000, use 8.6 (and 86)
ENV TORCH_CUDA_ARCH_LIST="8.6"
ENV TCNN_CUDA_ARCHITECTURES="86"

ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
ENV LIBRARY_PATH=${CUDA_HOME}/lib64/stubs:${LIBRARY_PATH}

# Install system dependencies as root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
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
    python3-pip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -g ${GID} ${GROUP_NAME} \
    && useradd -ms /bin/bash -u ${UID} -g ${GID} ${USER_NAME}

# Switch to non-root user for everything else
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/${USER_NAME}/.local/bin:${PATH}"

# Copy the entire project (needed for building extensions)
COPY --chown=${USER_NAME}:${GROUP_NAME} . /home/${USER_NAME}/threestudio

# Set working directory to gaussians2life
WORKDIR /home/${USER_NAME}/threestudio/custom/gaussians2life

# Create UV venv with Python 3.10
RUN uv venv --python 3.10 .venv

# Install pip into the venv using uv
RUN uv pip install --python .venv/bin/python pip 

# Set venv in PATH
ENV PATH="/home/${USER_NAME}/threestudio/custom/gaussians2life/.venv/bin:${PATH}"

# Install build tools in venv
RUN uv pip install --python .venv/bin/python --upgrade pip setuptools ninja

# Install PyTorch with CUDA 11.8 into the venv
RUN uv pip install --python .venv/bin/python --index-url https://download.pytorch.org/whl/cu118 \
    torch==2.0.1+cu118 torchvision==0.15.2+cu118

# Install CUDA extensions (disable build isolation so they can import torch)
# RUN uv pip install --python .venv/bin/python --no-build-isolation git+https://github.com/KAIR-BAIR/nerfacc.git@v0.5.2
# RUN uv pip install --python .venv/bin/python --no-build-isolation git+https://github.com/NVlabs/tiny-cuda-nn.git#subdirectory=bindings/torch

# # Install project requirements
# RUN uv pip install --python .venv/bin/python -r requirements.txt

# # Install local CUDA extensions
# RUN uv pip install --python .venv/bin/python ./diff-gaussian-rasterization
# RUN uv pip install --python .venv/bin/python ./simple-knn

# # Optional: Download DynamiCrafter model
# RUN uv pip install --python .venv/bin/python huggingface_hub && \
#     mkdir -p guidance/dynamicrafter/pretrained_models && \
#     .venv/bin/huggingface-cli download Doubiiu/DynamiCrafter_512 model.ckpt \
#         --local-dir guidance/dynamicrafter/pretrained_models && \
#     mv guidance/dynamicrafter/pretrained_models/model.ckpt \
#        guidance/dynamicrafter/pretrained_models/dynamicrafter-512.ckpt

# Set working directory back to threestudio root
WORKDIR /home/${USER_NAME}/threestudio

CMD ["/bin/bash"]