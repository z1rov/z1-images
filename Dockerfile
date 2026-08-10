FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    Z1_HOME=/z1 \
    Z1_USER=z1user \
    Z1_UID=1000 \
    Z1_GID=1000 \
    TERM=xterm-256color \
    SHELL=/bin/bash \
    LANG=en_US.UTF-8 \
    GOPATH="/root/go" \
    PATH="${PATH}:/usr/local/go/bin:/root/go/bin:/opt/tools/bin:/usr/local/bin"

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl wget git gnupg locate unzip\
    python3 python3-pip iproute2 iputils-ping nano tree\
    dnsutils net-tools procps locales tzdata ntpdate\
    less vim sudo openssh-client xclip\
    build-essential gcc libssl-dev libffi-dev \
    python3-dev \
    krb5-config libkrb5-dev libldap2-dev libsasl2-dev \
    samba-common-bin \
    xvfb x11vnc fluxbox wireguard-tools \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN set -e; \
    GO_VERSION="1.23.5"; \
    ARCH=$(uname -m); \
    case "${ARCH}" in \
        x86_64)  GOARCH="amd64" ;; \
        aarch64) GOARCH="arm64" ;; \
        *)       echo "Unsupported arch: ${ARCH}"; exit 1 ;; \
    esac; \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz" \
        -o /tmp/go.tar.gz; \
    rm -rf /usr/local/go; \
    tar -C /usr/local -xzf /tmp/go.tar.gz; \
    rm /tmp/go.tar.gz; \
    /usr/local/go/bin/go version

RUN apt-get update && apt-get install -y --no-install-recommends \
    zsh zsh-syntax-highlighting zsh-autosuggestions fzf \
    powerline fonts-powerline \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

COPY install/common.sh /z1/install/common.sh
RUN chmod +x /z1/install/common.sh

COPY install/p_binaries.sh /z1/install/p_binaries.sh
RUN chmod +x /z1/install/p_binaries.sh && apt-get update && bash -c 'source /z1/install/common.sh && source /z1/install/p_binaries.sh && p_binaries' && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY assets/ /z1/assets/
COPY assets/bin/ /opt/tools/bin/
RUN chmod +x /opt/tools/bin/*

COPY version/ /z1/version/

COPY runtime/ /z1/runtime/
ENV PATH="${PATH}:/root/.local/bin"

RUN find /z1 -name "*.sh" -exec chmod +x {} \; && \
    mkdir -p /opt/tools/bin /opt/tools/src /opt/tools/forja \
             /usr/share/rules /etc/wireguard

RUN updatedb

WORKDIR /z1
ENTRYPOINT ["/z1/runtime/init.sh"]
