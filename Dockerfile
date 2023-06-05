FROM nvidia/cuda:12.1.1-base-ubuntu22.04

RUN apt update && apt -y full-upgrade

RUN apt install -y nano sudo
RUN apt install -y python3 python3-pip

SHELL ["/bin/bash", "-c"]
ENV SHELL=/bin/bash

# Usuario no root
ARG USERNAME=localgpt
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Proyecto base
RUN mkdir -p /datos/source && chown $USERNAME:$USERNAME /datos/source

# Instalación base - Solo el fichero requirements para aprovechar la cache
USER $USERNAME:$USERNAME
COPY requirements.txt /datos/source
RUN cd /datos/source && pip install -r requirements.txt

# Resto de ficheros (puede no usar cache)
COPY . /datos/source

# Hacemos una ingesta inicial para que descargue los modelos
# CUIDADO! Debemos mapear luego ese directorio en docker-compose para que no use el local
#RUN cd /datos/source && python3 ingest.py