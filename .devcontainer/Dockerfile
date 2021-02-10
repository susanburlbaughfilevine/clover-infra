# Terraform makes their own Docker containter but its built on AlpineLinux right now support for Alpine in VS Code is in beta so I build my own docker file with Terraform in it. We can try just using there container when it has full support.
#FROM hashicorp/terraform:light
#some of this is based on the offical terraform docker image. https://github.com/hashicorp/terraform/blob/master/scripts/docker-release/Dockerfile-release
#this is an example of how to auto install the latest version. https://gist.github.com/danisla/0a394c75bddce204688b21e28fd2fea5
# FROM ubuntu:latest
FROM mcr.microsoft.com/dotnet/core/sdk:3.1
RUN apt update && \
    apt upgrade -y && \
    apt install -y curl gnupg unzip git wget
# Install .net core and PS core
RUN wget -q https://packages.microsoft.com/config/ubuntu/19.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update -y && \
    apt-get install -y apt-transport-https && \
    apt-get update -y 
    # Type 'pwsh' to start powershell
# The version number can be changed here when we need to upgrade
ARG TERRAFORM_VERSION=0.12.16
RUN curl -O https://raw.githubusercontent.com/hashicorp/terraform/master/scripts/docker-release/releases_public_key && \
    curl -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    curl -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig && \
    curl -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    # gpg --import releases_public_key && \
    # gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    # grep linux_amd64 terraform_${TERRAFORM_VERSION}_SHA256SUMS >terraform_${TERRAFORM_VERSION}_SHA256SUMS_linux_amd64 && \
    # sha256sum -c --strict terraform_${TERRAFORM_VERSION}_SHA256SUMS_linux_amd64 && \
    # unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin && \
    rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS*