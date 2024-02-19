# Dockerfile to create a container with Ubuntu 22.04
FROM ubuntu:22.04

USER root
# update the package list and clean up
RUN apt-get update \
    && apt-get upgrade -y \ 
    && apt-get install git sudo curl wget cmake gcc g++ -y \
    && apt-get clean

# add passwordless user test and passwordless sudo
RUN useradd -m -s /bin/bash test \
    && echo "test ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/test \
    && chmod 0440 /etc/sudoers.d/test

# force set user password to "password
RUN echo "test:password" | chpasswd

# switch to user test



COPY . /home/test/dotfiles
RUN chmod +x /home/test/dotfiles/install.sh
# RUN echo "alias install='bash /home/test/dotfiles/install.sh'" >> /home/test/.bashrc
USER test
RUN /home/test/dotfiles/install.sh


WORKDIR /home/test/dotfiles
ENV TERM=xterm-256color
ENTRYPOINT ["/usr/bin/tail", "-f", "/dev/null"]


