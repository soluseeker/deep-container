FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

USER root

# --- 基本环境配置 ---
# 设置持久环境变量
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    TZ=Asia/Shanghai

# 设置构建时参数
ARG DEBIAN_FRONTEND=noninteractive

# --- 安装系统依赖 ---
RUN sed -i 's@/archive.ubuntu.com/@/mirrors.tuna.tsinghua.edu.cn/@g' /etc/apt/sources.list && \
    apt update && apt install -y \
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
    libgl1-mesa-glx && \
    # 清理APT缓存
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# --- 安装Miniconda ---
ENV PATH="/root/miniconda/bin:${PATH}"
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -u -p /root/miniconda && \
    rm /tmp/miniconda.sh && \
    /root/miniconda/bin/conda init bash && \
    # 配置conda源
    cat <<-EOF > ~/.condarc && \
channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
EOF
    conda clean -i

# --- 安装JupyterLab ---
RUN conda install -c conda-forge jupyterlab -y && \
    jupyter lab --generate-config && \
    conda clean -i

# --- 系统和SSH配置 ---
RUN # 创建工作目录
    mkdir -p /root/workspace /root/share /root/public /var/run/sshd && \
    # 配置SSH
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/session required pam_loginuid.so/#session required pam_loginuid.so/g' /etc/pam.d/sshd && \
    echo "root:123456" | chpasswd && \
    # 设置时区
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # 继承宿主机环境变量
    echo 'for item in $(cat /proc/1/environ | tr "\0" "\n"); do export $item; done' >> /etc/profile

# --- 拷贝脚本并设置权限 ---
COPY ./init_container.sh /usr/local/bin/init_container.sh
COPY ./lab.sh /root/lab.sh
RUN chmod +x /usr/local/bin/init_container.sh /root/lab.sh

ENTRYPOINT ["/usr/local/bin/init_container.sh"]
