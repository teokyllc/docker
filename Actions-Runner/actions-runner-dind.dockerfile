FROM ubuntu:20.04

ARG TARGETPLATFORM
ARG RUNNER_VERSION
ARG DOCKER_CHANNEL=stable
ARG DOCKER_VERSION
ARG DUMB_INIT_VERSION
ARG BUILDX_VERSION
ENV BUILDX_VERSION=$BUILDX_VERSION
ARG VAULT_ADDR
ENV VAULT_ADDR=$VAULT_ADDR
ARG VAULT_TOKEN

RUN test -n "$TARGETPLATFORM" || (echo "TARGETPLATFORM must be set" && false)

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update -y \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:git-core/ppa \
    && add-apt-repository -y ppa:ansible/ansible \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
    ansible \
    apt-transport-https \
    build-essential \
    curl \
    ca-certificates \
    dnsutils \
    ftp \
    git \
    git-lfs \
    gnupg \
    iproute2 \
    iputils-ping \
    iptables \
    jq \
    libunwind8 \
    locales \
    lsb-release \
    netcat \
    net-tools \
    openssh-client \
    parallel \
    rsync \
    shellcheck \
    supervisor \
    software-properties-common \
    sudo \
    telnet \
    time \
    tzdata \
    unzip \
    upx \
    wget \
    zip \
    zstd

# Ansible modules
RUN ansible-galaxy collection install community.docker \
    &&  ansible-galaxy collection install kubernetes.core

# Actions Runner user
RUN adduser --disabled-password --gecos "" --uid 1000 runner \
    && groupadd docker \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

# Actions Runner
ENV RUNNER_ASSETS_DIR=/runnertmp
RUN export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "i386" ]; then export ARCH=x64 ; fi \
    && mkdir -p "$RUNNER_ASSETS_DIR" \
    && cd "$RUNNER_ASSETS_DIR" \
    && curl -f -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh \
    && apt-get install -y libyaml-dev

# AWS CLI
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -f awscliv2.zip

# Azure CLI
# RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/microsoft.gpg > /dev/null \
#     && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs)" | tee /etc/apt/sources.list.d/azure-cli.list \
#     && apt-get update \
#     && apt-get install -y azure-cli

# Docker
RUN export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && if [ "$ARCH" = "arm64" ]; then export ARCH=aarch64 ; fi \
    && if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "i386" ]; then export ARCH=x86_64 ; fi \
	&& if ! curl -f -L -o docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${ARCH}/docker-${DOCKER_VERSION}.tgz"; then \
		echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for '${ARCH}'"; \
		exit 1; \
	fi; \
    echo "Downloaded Docker from https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${ARCH}/docker-${DOCKER_VERSION}.tgz"; \
	tar --extract \
		--file docker.tgz \
		--strip-components 1 \
		--directory /usr/bin/ \
	; \
	rm docker.tgz; \
	dockerd --version; \
	docker --version

# Hashicorp
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt update \
    && apt-get install -y \
    packer \
    terraform \
    vault \
    && setcap -r /usr/bin/vault

# Helm
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update \
    && apt-get install helm

# Kubectl
RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install -y kubectl

# Java JDK
RUN apt-get install -y default-jdk default-jre

# NodeJS
# RUN curl -fsSL https://deb.nodesource.com/setup_19.x | bash - && \
#     && apt-get install -y nodejs

# Powershell
# RUN wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" \
#     && dpkg -i packages-microsoft-prod.deb \
#     && apt-get update \
#     && apt-get install -y powershell

# Python
RUN apt-get install -y python3 python3-pip \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip \
    && pip install kubernetes

# Yq
RUN wget https://github.com/mikefarah/yq/releases/download/v4.28.2/yq_linux_amd64 \
    && mv yq_linux_amd64 /usr/bin/yq \
    && chmod 777 /usr/bin/yq

ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache
RUN mkdir /opt/hostedtoolcache \
    && chgrp docker /opt/hostedtoolcache \
    && chmod g+rwx /opt/hostedtoolcache

# Trusted CA
RUN export VAULT_SKIP_VERIFY=true \
    && vault kv get -mount=kv -field=AD-CA cert > /usr/local/share/ca-certificates/teokyllc-root-ca.crt \
    && vault kv get -mount=kv -field=vault-int-ca cert > /usr/local/share/ca-certificates/teokyllc-vault-int-ca.crt \
    && update-ca-certificates

COPY entrypoint.sh logger.bash startup.sh update-status /usr/bin/
COPY supervisor/ /etc/supervisor/conf.d/
RUN chmod +x /usr/bin/startup.sh /usr/bin/entrypoint.sh
COPY docker-shim.sh /usr/local/bin/docker
COPY hooks /etc/arc/hooks/

# Download Dumb Init
RUN export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && if [ "$ARCH" = "arm64" ]; then export ARCH=aarch64 ; fi \
    && if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "i386" ]; then export ARCH=x86_64 ; fi \
    && curl -f -L -o /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_${ARCH} \
    && chmod +x /usr/local/bin/dumb-init

VOLUME /var/lib/docker

ENV HOME=/home/runner
ENV PATH="${PATH}:${HOME}/.local/bin"
ENV ImageOS=ubuntu20

RUN echo "PATH=${PATH}" > /etc/environment \
    && echo "ImageOS=${ImageOS}" >> /etc/environment

USER runner

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["startup.sh"]