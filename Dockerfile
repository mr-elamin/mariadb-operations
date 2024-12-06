# Dockerfile
FROM ubuntu:24.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packages
RUN apt-get update && apt-get install -y \
    apache2-utils \
    apt-transport-https \
    base-files \
    bash \
    bash-completion \
    bsdutils \
    ca-certificates \
    ceph \
    ceph-common \
    curl \
    dash \
    default-jdk \
    diffutils \
    efibootmgr \
    findutils \
    gnupg \
    gpg \
    grep \
    grub-efi-amd64 \
    grub-efi-amd64-signed \
    gzip \
    hostname \
    init \
    linux-generic \
    login \
    lsb-release \
    ncurses-base \
    ncurses-bin \
    nfs-common \
    openssh-server \
    podman \
    pwgen \
    radosgw \
    shim-signed \
    socat \
    sudo \
    ubuntu-minimal \
    ubuntu-server \
    ubuntu-server-minimal \
    ubuntu-standard \
    unzip \
    util-linux \
    net-tools \
    iputils-ping \
    dnsutils \
    traceroute \
    tcpdump \
    whois \
    mariadb-client \
    iperf3 \
    speedtest-cli \
    netperf \
    iperf \
    redis-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add Docker repository and install Docker packages
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt-get update && apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl and kubeadm version 1.31.1
RUN curl -LO "https://dl.k8s.io/release/v1.31.1/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/ \
    && curl -LO "https://dl.k8s.io/release/v1.31.1/bin/linux/amd64/kubeadm" \
    && chmod +x kubeadm \
    && mv kubeadm /usr/local/bin/

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Velero CLI
RUN curl -LO https://github.com/vmware-tanzu/velero/releases/download/v1.15.0/velero-v1.15.0-linux-amd64.tar.gz \
    && tar -xvf velero-v1.15.0-linux-amd64.tar.gz \
    && mv velero-v1.15.0-linux-amd64/velero /usr/local/bin/ \
    && rm -rf velero-v1.15.0-linux-amd64 velero-v1.15.0-linux-amd64.tar.gz

# Install Cilium CLI
RUN CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt) \
    && CLI_ARCH=amd64 \
    && if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi \
    && curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum} \
    && sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum \
    && tar xzvf cilium-linux-${CLI_ARCH}.tar.gz -C /usr/local/bin \
    && rm cilium-linux-${CLI_ARCH}.tar.gz cilium-linux-${CLI_ARCH}.tar.gz.sha256sum

# Enable SSH service
RUN systemctl enable ssh

# Create the /run/sshd directory
RUN mkdir -p /run/sshd

# Copy the startup script
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh && chown root:root /usr/local/bin/startup.sh

# Copy the MariaDB operation scripts to /opt/scripts and make them executable
COPY mariadb-connect-to-database.sh /opt/scripts/
COPY mariadb-create-database-namespaced.sh /opt/scripts/
COPY mariadb-drop-database-namespaced.sh /opt/scripts/
COPY mariadb-list-backup.sh /opt/scripts/
COPY mariadb-show-databases.sh /opt/scripts/
COPY mariadb-create-backup.sh /opt/scripts/
COPY mariadb-create-database.sh /opt/scripts/
COPY mariadb-drop-database.sh /opt/scripts/
COPY mariadb-restore-backup.sh /opt/scripts/
RUN chmod +x /opt/scripts/mariadb-connect-to-database.sh \
    /opt/scripts/mariadb-create-database-namespaced.sh \
    /opt/scripts/mariadb-drop-database-namespaced.sh \
    /opt/scripts/mariadb-list-backup.sh \
    /opt/scripts/mariadb-show-databases.sh \
    /opt/scripts/mariadb-create-backup.sh \
    /opt/scripts/mariadb-create-database.sh \
    /opt/scripts/mariadb-drop-database.sh \
    /opt/scripts/mariadb-restore-backup.sh

# Download the yq binary, make it executable, rename it to yq, and copy it to /usr/bin
RUN curl -L https://github.com/mikefarah/yq/releases/download/v4.44.5/yq_linux_amd64 -o /usr/bin/yq \
    && chmod +x /usr/bin/yq

# Expose SSH port
EXPOSE 22

# Set the working directory
WORKDIR /root

# Set the default user to root
USER root

# Start SSH service with the startup script
CMD ["/usr/local/bin/startup.sh"]