# Production Dockerfile for Packer Proxmox Builds
FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PACKER_VERSION=1.12.0 \
    ANSIBLE_VERSION=2.17 \
    PATH="$HOME/.local/bin:$PATH"

# Install base dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    gpg \
    software-properties-common \
    ca-certificates \
    git \
    openssh-client \
    jq \
    unzip \
    && update-ca-certificates

# Install Packer
RUN mkdir -m 0755 -p /etc/apt/keyrings/ && \
    curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/keyrings/hashicorp-packer.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/hashicorp-packer.gpg] https://apt.releases.hashicorp.com $(grep VERSION_CODENAME /etc/os-release | cut -d= -f2) main" | tee /etc/apt/sources.list.d/hashicorp-packer.list > /dev/null && \
    chmod 0644 /etc/apt/keyrings/hashicorp-packer.gpg && \
    apt-get update && \
    apt-get install -y packer

# Install Python3 and Ansible
RUN add-apt-repository --yes --update ppa:ansible/ansible && \
    apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    ansible-core \
    && ansible-galaxy collection install ansible.posix community.general

# Update pip, setuptools, and wheel to latest versions (security)
RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Cleanup
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /workspace

# Create config directory that can be mounted
VOLUME ["/workspace/config"]

# Copy project files (can be overridden with volume mount)
COPY . /workspace/

# Set default command
CMD ["/bin/bash"]
