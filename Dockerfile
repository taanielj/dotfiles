FROM ubuntu:24.04

# Install minimal tools needed to bootstrap
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user with passwordless sudo
RUN useradd -m -s /bin/bash ubuntu-dev && \
    echo "ubuntu-dev ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/test && \
    chmod 0440 /etc/sudoers.d/test

# pre-install some packages to skip some steps
RUN apt-get -y update && \
    apt-get -y install software-properties-common && \
    add-apt-repository -y ppa:zhangsongcui3371/fastfetch && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# pre-install dependencies for building python
RUN apt-get -y update && \ 
    apt-get -y install build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl git \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=ubuntu-dev:ubuntu-dev . /home/ubuntu-dev/dotfiles

USER ubuntu-dev

ENV TERM=xterm-256color

CMD ["/bin/bash"]

