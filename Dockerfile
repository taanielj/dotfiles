# Dockerfile to create a container with Ubuntu 22.04
FROM ubuntu:22.04

USER root
# update the package list and clean up
RUN apt-get update \
    && apt-get upgrade -y \ 
    && apt-get install git sudo curl wget cmake gcc g++ -y
    && apt-get clean

# add passwordless user taaniel and passwordless sudo
RUN useradd -m -s /bin/bash taaniel \
    && echo "taaniel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/taaniel \
    && chmod 0440 /etc/sudoers.d/taaniel

# force set user password to "password
RUN echo "taaniel:password" | chpasswd

# switch to user taaniel



COPY . /home/taaniel/dotfiles
RUN chmod +x /home/taaniel/dotfiles/install.sh
# RUN echo "alias install='bash /home/taaniel/dotfiles/install.sh'" >> /home/taaniel/.bashrc
USER taaniel
RUN sudo /home/taaniel/dotfiles/install.sh


WORKDIR /home/taaniel/dotfiles
ENV TERM=xterm-256color
ENTRYPOINT ["/usr/bin/tail", "-f", "/dev/null"]


