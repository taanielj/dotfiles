# Dockerfile to create a container with Ubuntu 22.04
FROM ubuntu:22.04

USER root
# update the package list and clean up
RUN apt-get update \
    && apt-get upgrade -y \ 
    && apt-get install git sudo -y \
    && apt-get clean

# add passwordless user taaniel and passwordless sudo
RUN useradd -m -s /bin/bash taaniel \
    && echo "taaniel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/taaniel \
    && chmod 0440 /etc/sudoers.d/taaniel

# switch to user taaniel
USER taaniel
WORKDIR /home/taaniel
RUN git clone https://github.com/taanielj/dotfiles.git


ENTRYPOINT ["/bin/bash"]

# to run this local dockerfile
# docker build -t custom-ubuntu:22.04 .
# docker run -it --rm custom-ubuntu:22.04
