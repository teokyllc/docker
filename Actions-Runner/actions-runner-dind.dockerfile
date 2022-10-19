FROM ubuntu:20.04

ARG RUNNER_VERSION=2.298.2
ARG DOCKER_VERSION=20.10.18
ARG DUMB_INIT_VERSION=1.2.5

ARG RUNNER_NAME
ARG RUNNER_ORG=teokyllc
ARG RUNNER_TOKEN
ENV RUNNER_NAME=$RUNNER_NAME
ENV RUNNER_ORG=$RUNNER_ORG
ENV RUNNER_TOKEN=$RUNNER_TOKEN

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update -y \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:git-core/ppa \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    ca-certificates \
    dnsutils \
    ftp \
    git \
    git-lfs \
    iproute2 \
    iputils-ping \
    iptables \
    jq \
    libunwind8 \
    locales \
    netcat \
    net-tools \
    openssh-client \
    parallel \
    python3-pip \
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
    zstd \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip \
    && rm -rf /var/lib/apt/lists/*

# Runner user
RUN adduser --disabled-password --gecos "" --uid 1000 runner \
    && groupadd docker \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

# Docker download
RUN if ! curl -f -L -o docker.tgz "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz"; then \
		echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}'"; \
		exit 1; \
	fi; \
    echo "Downloaded Docker from https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz"; \
	tar --extract --file docker.tgz --strip-components 1 --directory /usr/bin/ ; \
	rm docker.tgz; \
	dockerd --version; \
	docker --version

# Runner download
ENV RUNNER_ASSETS_DIR=/runner
RUN mkdir -p "$RUNNER_ASSETS_DIR" \
    && cd "$RUNNER_ASSETS_DIR" \
    && curl -f -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh \
    && apt-get install -y libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache
RUN mkdir $RUNNER_TOOL_CACHE \
    && chgrp docker $RUNNER_TOOL_CACHE \
    && chmod g+rwx $RUNNER_TOOL_CACHE

# We place the scripts in `/usr/bin` so that users who extend this image can override them with scripts of the same name placed in `/usr/local/bin`.
COPY entrypoint.sh logger.bash startup.sh update-status /usr/bin/
COPY supervisor/ /etc/supervisor/conf.d/
RUN chmod +x /usr/bin/startup.sh /usr/bin/entrypoint.sh
COPY docker-shim.sh /usr/local/bin/docker

# Configure hooks folder structure.
COPY hooks /etc/arc/hooks/

# Dumb-init
RUN curl -f -L -o /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 \
    && chmod +x /usr/local/bin/dumb-init

VOLUME /var/lib/docker

ENV HOME=/home/runner

# Add the Python "User Script Directory" to the PATH
ENV PATH="${PATH}:${HOME}/.local/bin"
ENV ImageOS=ubuntu20

RUN echo "PATH=${PATH}" > /etc/environment \
    && echo "ImageOS=${ImageOS}" >> /etc/environment

# No group definition, as that makes it harder to run docker.
USER runner

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["startup.sh"]