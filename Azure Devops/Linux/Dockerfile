FROM ubuntu:18.04

ARG ADO_PAT
ARG ADO_VERSION
ARG ADO_ORG=allan05
ARG AGENT_WORK_DIR=_work
ARG AGENT_POOL=MSF-Agent-Pool
ENV DEBIAN_FRONTEND=noninteractive

ENV DOTNET_CORE_VERSION=6.0
ENV HELM_VERSION=3.8.2
ENV KUBECTL_VERSION=1.23.0
ENV NODE_JS_VERSION=15.x

ENV TARGETARCH=linux-x64
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        jq \
        git \
        gnupg \
        iputils-ping \
        libcurl4 \
        libicu60 \
        libunwind8 \
        libssl1.0 \
        lsb-release \
        nfs-common \
        openjdk-11-jdk \
        python3 \
        python3-pip \
        rsync \
        software-properties-common \
        sudo \
        tar \
        telnet \
        unzip \
        vim \
        wget \
        zip

# ADO Agent
RUN useradd -u 1000 -M -s /sbin/nologin ado-agent \
  && mkdir /ado_agent \
  && wget https://vstsagentpackage.azureedge.net/agent/$ADO_VERSION/vsts-agent-linux-x64-$ADO_VERSION.tar.gz \
  && tar -xzvf vsts-agent-linux-x64-$ADO_VERSION.tar.gz \ 
  && chown -R ado-agent:root /ado_agent \
  && rm -f vsts-agent-linux-x64-$ADO_VERSION.tar.gz

# Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
 && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
 && apt-get update \
 && apt-get install -y docker-ce-cli

# Dotnet Core
RUN wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
 && dpkg -i packages-microsoft-prod.deb \
 && rm packages-microsoft-prod.deb \
 && apt-get update \
 && apt-get install -y dotnet-sdk-$DOTNET_CORE_VERSION

# Google GCloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
 && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - \
 && apt-get update -y \
 && apt-get install google-cloud-sdk -y

# Helm
RUN cd /tmp && wget https://get.helm.sh/helm-v$HELM_VERSION-linux-amd64.tar.gz \
 && tar -zxvf helm-v3* \
 && mv linux-amd64/helm /usr/bin/helm \
 && rm -rf linux-amd64

# Kubectl
RUN curl -LO https://dl.k8s.io/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl \
 && mv kubectl /usr/bin/kubectl

# MySQL Client
#RUN apt-get install -y mysql-client-5.7

# Node JS
#RUN curl -sL $NodeJsUrl | bash - \
#  && apt-get install -y nodejs

# Terraform
# RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
#   && apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
#   && apt-get install terraform -y


WORKDIR /ado_agent

RUN /bin/bash -c "echo ${ADO_PAT} > /ado_agent/.token"
ENV ADO_PAT=

COPY start.sh /ado_agent
RUN chmod +x start.sh

USER ado-agent
CMD ./start.sh
