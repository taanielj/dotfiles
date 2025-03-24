FROM ubuntu:24.04

# Install minimal tools needed to bootstrap
RUN apt-get update --no-install-recommends && \
    apt-get upgrade -y && \
    apt-get install -y git sudo && \
    apt-get clean

# Create non-root user with passwordless sudo
RUN useradd -m -s /bin/bash test && \
    echo "test ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/test && \
    chmod 0440 /etc/sudoers.d/test

USER test

# Clone dotfiles
COPY --chown=test:test . /home/test/dotfiles
WORKDIR /home/test/dotfiles
ENV TERM=xterm-256color


CMD ["/bin/bash"]

