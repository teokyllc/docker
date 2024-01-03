FROM ubuntu:20.04

ARG TARGETPLATFORM=linux/amd64
ARG RUNNER_VERSION
ARG RUNNER_CONTAINER_HOOKS_VERSION
ARG CHANNEL=stable
ARG DOCKER_VERSION
ARG DOCKER_COMPOSE_VERSION
ARG DUMB_INIT_VERSION
ARG YQ_VERSION
ARG ISTIOCTL_VERSION
ARG RUNNER_USER_UID=1001
ARG DOCKER_GROUP_GID=121

ENV DEBIAN_FRONTEND=noninteractive
RUN echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90_assume_yes

RUN apt update -y \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:git-core/ppa \
    && add-apt-repository -y ppa:ansible/ansible \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
    ansible \
    apt-transport-https \
    apt-utils \
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
    libmysqlclient-dev \
    libunwind8 \
    libxml2 \
    libxmlsec1 \
    libxmlsec1-dev \
    libyaml-dev \
    locales \
    lsb-release \
    netcat \
    net-tools \
    openssh-client \
    parallel \
    pkg-config \
    python3 \
    python3-pip \
    python3.8-dev \
    python3.8-venv \
    rsync \
    shellcheck \
    snapd \
    supervisor \
    software-properties-common \
    sudo \
    telnet \
    time \
    tzdata \
    unzip \
    upx \
    wget \
    vim \
    zip \
    zstd \
    && rm -rf /var/lib/apt/lists/*

# Runner user
ENV HOME=/home/runner
RUN adduser --disabled-password --gecos "" --uid $RUNNER_USER_UID runner \
    && groupadd docker --gid $DOCKER_GROUP_GID \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

# Runner
ENV RUNNER_ASSETS_DIR=/runnertmp
RUN export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "i386" ]; then export ARCH=x64 ; fi \
    && mkdir -p "$RUNNER_ASSETS_DIR" \
    && cd "$RUNNER_ASSETS_DIR" \
    && curl -fLo runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm -f runner.tar.gz \
    && ./bin/installdependencies.sh \
    && apt-get install -y libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

# Runner Hooks
RUN cd "$RUNNER_ASSETS_DIR" \
    && curl -fLo runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
    && unzip ./runner-container-hooks.zip -d ./k8s \
    && rm -f runner-container-hooks.zip

# Ansible modules
RUN ansible-galaxy collection install community.docker \
    &&  ansible-galaxy collection install kubernetes.core

# AWS CLI
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -f awscliv2.zip

# Docker
RUN set -vx; \
    curl -fLo docker.tgz https://download.docker.com/linux/static/${CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz \
    && tar zxvf docker.tgz \
    && install -o root -g root -m 755 docker/* /usr/bin/ \
    && rm -rf docker docker.tgz
ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache
RUN mkdir /opt/hostedtoolcache \
    && chgrp docker /opt/hostedtoolcache \
    && chmod g+rwx /opt/hostedtoolcache

# Docker Compose
RUN curl -fLo /usr/bin/docker-compose https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64 \
    && chmod +x /usr/bin/docker-compose

# Dumb Init
RUN curl -fLo /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 \
    && chmod +x /usr/bin/dumb-init

# Hashicorp
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt update \
    && apt-get install -y \
    packer \
    terraform

# Helm
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update \
    && apt-get install helm

# Istioctl
RUN curl -fLo istioctl.tar.gz https://github.com/istio/istio/releases/download/${ISTIOCTL_VERSION}/istioctl-${ISTIOCTL_VERSION}-linux-amd64.tar.gz \
    && tar -xzvf istioctl.tar.gz \
    && rm -f istioctl.tar.gz \
    && mv istioctl /usr/bin/istioctl \
    && chmod +x /usr/bin/istioctl

# Kubectl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add \
    && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> ~/kubernetes.list \
    && mv ~/kubernetes.list /etc/apt/sources.list.d \
    && rm -f ~/kubernetes.list \
    && apt-get update \
    && apt-get install -y kubectl

# Kubectl Plugins
RUN curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64 \
    && chmod +x ./kubectl-argo-rollouts-linux-amd64 \
    && mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# Java JDK
RUN apt-get install -y default-jdk default-jre

# MySQL
RUN apt-get remove --purge *mysql* -y \
    && rm -rvf /etc/init.d/mysql* /etc/mysql* /var/lib/mysql* \
    && apt-get install libaio1 libnuma1 libtinfo5 psmisc libmecab2 -y \
    && wget https://cdn.mysql.com/archives/mysql-5.7/mysql-server_5.7.35-1ubuntu18.04_amd64.deb-bundle.tar \
    && tar -xf mysql-server_5.7*.tar \
    && DEBIAN_FRONTEND=noninteractive dpkg --install mysql-common_5.7*.deb libmysqlclient*.deb mysql-server_5.7*.deb mysql-client_5.7*.deb mysql-community-server_5.7*.deb mysql-community-client_5.7*.deb

# NodeJS
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Python packages
RUN ln -sf /usr/bin/python3 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip
USER runner
RUN pip3 install kubernetes \
    && python3 -m pip install --user pipx \
    && pip3 install --upgrade pyyaml \
    && pip3 install --upgrade setuptools \
    && . ~/.profile \
    && python3 -m pipx ensurepath \
    && pipx install poetry
USER root

# Yq
RUN wget https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 \
    && mv yq_linux_amd64 /usr/bin/yq \
    && chmod +x /usr/bin/yq

# We place the scripts in `/usr/bin` so that users who extend this image can
# override them with scripts of the same name placed in `/usr/local/bin`.
COPY entrypoint.sh startup.sh logger.sh wait.sh graceful-stop.sh update-status /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh /usr/bin/startup.sh

# Copy the docker shim which propagates the docker MTU to underlying networks
# to replace the docker binary in the PATH.
COPY docker-shim.sh /usr/local/bin/docker

# Configure hooks folder structure.
COPY hooks /etc/arc/hooks/

VOLUME /var/lib/docker

# Add the Python "User Script Directory" to the PATH
ENV PATH="${PATH}:${HOME}/.local/bin"
ENV ImageOS=ubuntu20

RUN echo "PATH=${PATH}" > /etc/environment \
    && echo "ImageOS=${ImageOS}" >> /etc/environment

# No group definition, as that makes it harder to run docker.
USER runner

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["entrypoint.sh"]
