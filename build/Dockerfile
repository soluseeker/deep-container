FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

USER root

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 LANGUAGE=C.UTF-8
# Change software source
RUN sed -i 's@/archive.ubuntu.com/@/mirrors.tuna.tsinghua.edu.cn/@g' /etc/apt/sources.list

# Install necessary tools
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y \
  sudo \
  wget \
  curl \
  vim \
  git \
  build-essential \
  cmake \
  checkinstall \
  pkg-config \
  openssh-server \
  zip \
  unzip \
  p7zip \
  tmux \
  htop \
  iftop \
  iotop \
  tzdata \
  libxmu6 \
  libsm6 \
  libxext-dev \
  libxrender1 \
  libgl1-mesa-glx


# Install miniconda and change source
RUN mkdir -p ~/miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda/miniconda.sh
RUN bash ~/miniconda/miniconda.sh -b -u -p ~/miniconda
RUN rm -rf ~/miniconda/miniconda.sh
RUN ~/miniconda/bin/conda init bash
ARG PATH=/root/miniconda/bin:$PATH

RUN echo "\
channels:\n\
  - defaults\n\
show_channel_urls: true\n\
default_channels:\n\
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main\n\
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r\n\
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2\n\
custom_channels:\n\
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud\n\
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud\n" > ~/.condarc

RUN conda clean -i

# install jupyterlab
RUN conda install -c conda-forge jupyterlab -y && jupyter lab --generate-config
# Create workspace directory
RUN mkdir /root/workspace
# Create shared directory
RUN mkdir /root/share
# Create public directory
RUN mkdir /root/public
# SSH settings
RUN mkdir /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/session requried pam_loginuid.so/#session required pam_loginuid.so/g' /etc/pam.d/sshd
RUN echo "root:123456" | chpasswd

# Clean up all temp files
RUN apt clean && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/*

# Set timezone
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY ./init_container.sh /usr/local/bin/init_container.sh
COPY ./lab.sh /root/lab.sh

RUN chmod +x /root/lab.sh
RUN chmod +x /usr/local/bin/init_container.sh

ENTRYPOINT ["/usr/local/bin/init_container.sh"]
