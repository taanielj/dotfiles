# FROM ubuntu:24.04
FROM debian:bookworm
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


# pre-install dependencies for building python
RUN apt-get -y update && \ 
    apt-get -y install build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl git \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --chown=ubuntu-dev:ubuntu-dev . /home/ubuntu-dev/dotfiles

USER ubuntu-dev
# set remote url from ssh to https
RUN cd /home/ubuntu-dev/dotfiles && \
    git remote set-url origin https://github.com/taanielj/dotfiles

ENV TERM=xterm-256color

CMD ["/bin/bash"]

