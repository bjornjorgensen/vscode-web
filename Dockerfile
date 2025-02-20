# Use Ubuntu Plucky as the base image
FROM ubuntu:devel

# Set environment variables for the runtime user and Java
ENV USERNAME=code-tunnel
ENV HOME=/home/code-tunnel
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV _JAVA_OPTIONS="-Djava.awt.headless=true"

# Upgrade system, install dependencies, and clean up in one RUN
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    apt-get install -y sudo curl python3 python3-pip python3-venv build-essential git wget gnupg && \
    apt-get install -y --no-install-recommends openjdk-21-jdk-headless openjdk-21-jre-headless && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create user and set up base home directory with custom UID 1001
RUN useradd -m -s /bin/bash -u 1001 code-tunnel && \
    chown -R code-tunnel:code-tunnel /home/code-tunnel && \
    chmod 700 /home/code-tunnel
# Allow code-tunnel to use sudo without password
USER root
RUN echo "code-tunnel ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/code-tunnel && \
    chmod 0440 /etc/sudoers.d/code-tunnel
# Switch to code-tunnel user and set working directory
USER code-tunnel
WORKDIR /home/code-tunnel

# Add installation of kubectl (removed helm installation)
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    sudo mv kubectl /usr/local/bin/kubectl
# Install Helm from binary release
ENV HELM_VERSION=v3.17.1
RUN curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    tar -zxvf helm-${HELM_VERSION}-linux-amd64.tar.gz && \
    sudo mv linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    rm -rf helm-${HELM_VERSION}-linux-amd64.tar.gz linux-amd64

# Download and install VS Code CLI
USER code-tunnel
RUN mkdir -p ${HOME}/temp-vscode && \
    wget "https://code.visualstudio.com/sha/download?build=insider&os=cli-alpine-x64" -O ${HOME}/temp-vscode/vscode_cli.tar.gz && \
    tar -xzf ${HOME}/temp-vscode/vscode_cli.tar.gz -C ${HOME}/temp-vscode && \
    FILE=$(find ${HOME}/temp-vscode -type f -iname "code-insiders" | head -n 1) && \
    [ -n "$FILE" ] || { echo "Executable code-insiders not found"; exit 1; } && \
    sudo mkdir -p /opt/vscode-cli && \
    sudo cp "$FILE" /usr/local/bin/code-insiders && \
    sudo chmod +x /usr/local/bin/code-insiders && \
    rm -rf ${HOME}/temp-vscode && \
    mkdir -p ${HOME}/.vscode-cli ${HOME}/.vscode-insiders/cli ${HOME}/.vscode-insiders/data ${HOME}/.vscode-insiders/extensions ${HOME}/.vscode-server ${HOME}/.vscode-server-insiders

USER code-tunnel
WORKDIR /home/code-tunnel
    
# Install Rust and verify
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rustup.sh && \
    sh rustup.sh -y && \
    rm rustup.sh && \
    echo 'export PATH=$HOME/.cargo/bin:$PATH' >> ${HOME}/.bashrc && \
    echo 'export PATH=$HOME/.cargo/bin:$PATH' >> ${HOME}/.profile && \
    . "$HOME/.cargo/env" && \
    rustc --version

# Update PATH for all sessions
ENV PATH=/home/code-tunnel/.cargo/bin:/home/code-tunnel:$PATH
ENV SHELL=/bin/bash

# Add startup script
USER root
COPY <<-"EOF" /usr/local/bin/startup.sh
#!/bin/bash
if [ -z "${CONNECTION_TOKEN}" ]; then
    echo "ERROR: CONNECTION_TOKEN environment variable is required"
    exit 1
fi
exec /usr/local/bin/code-insiders serve-web \
    --accept-server-license-terms \
    --connection-token "${CONNECTION_TOKEN}" \
    --host 0.0.0.0 \
    --port 8000
EOF
RUN chmod +x /usr/local/bin/startup.sh

USER code-tunnel
ENTRYPOINT ["/usr/local/bin/startup.sh"]

