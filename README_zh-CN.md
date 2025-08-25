# 深度学习容器管理脚本
[English](README.md)

本项目提供了一套用于在服务器上构建和管理深度学习专用 Docker 容器的脚本。它简化了创建具有特定 CUDA 版本、管理端口和处理存储的可复现环境的过程。

## ✨ 核心功能

- **自定义 Docker 镜像构建**：构建预装了 Miniconda、JupyterLab 和基本开发工具的深度学习环境。
- **动态 CUDA 版本支持**：使用单个脚本即可创建具有不同 CUDA 版本（例如 12.4, 12.1, 11.8）的容器。
- **自动化端口管理**：为每个容器自动分配和管理 SSH 及服务端口，防止冲突。
- **防火墙集成**：自动为容器端口配置防火墙规则（使用 `firewall-cmd`）。
- **简化的容器生命周期管理**：易于使用的脚本来创建、删除和管理容器。
- **持久化存储**：自动创建并挂载工作区目录，用于持久化存储数据。
- **健壮的 JupyterLab 管理**：容器内包含一个脚本，可以安全地启动、停止和检查 JupyterLab 服务状态。

## 环境准备

在开始之前，请确保您的主机上已安装以下软件：
- **Docker 引擎**: [安装指南](https://docs.docker.com/engine/install/)
- **NVIDIA GPU 驱动**: 适用于您 GPU 的最新驱动。
- **NVIDIA Container Toolkit**: [安装指南](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- **firewalld**: 脚本使用 `firewall-cmd` 来管理防火墙规则。

## 📂 目录结构

```
.
├── build/
│   ├── Dockerfile           # 用于构建深度学习基础镜像的 Dockerfile。
│   ├── init_container.sh    # 容器的入口脚本（启动 SSH）。
│   └── lab.sh               # 在容器内管理 JupyterLab 的脚本。
├── run_container.sh         # 创建并运行一个新容器的脚本。
├── del_container.sh         # 删除容器并清理资源的脚本。
└── README.md                # 本文档文件。
```

## 🚀 快速开始

### 1. 构建 Docker 镜像

项目提供的 `Dockerfile` 用于构建一个完整的深度学习环境。您需要自行构建 `run_container.sh` 脚本将使用的镜像。

例如，构建一个用于 CUDA 12.4.1 的镜像：

```bash
# 导航到项目根目录
cd /path/to/deep-container

# 构建并标记镜像
# Dockerfile 使用 'nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04' 作为基础镜像
cd build
docker buildx build -t cuda:12.4.1-cudnn-miniconda-ubuntu22.04 .
```

*注意: `run_container.sh` 脚本期望使用特定的镜像标签（例如 `cuda:12.4.1-cudnn-miniconda-ubuntu22.04`, `cuda:11.8.0-cudnn-miniconda-ubuntu22.04` 等）。您需要自己构建这些镜像，或者如果它们已存在于镜像仓库中，则从仓库拉取。*

### 2. 创建一个新容器

`run_container.sh` 脚本简化了新容器的创建过程。

**使用方法:**
```bash
bash run_container.sh <name> [cuda_version]
```

- `<name>`: 容器的唯一名称。最终容器将被命名为 `deep-<name>`。
- `[cuda_version]`: (可选) 所需的 CUDA 版本。默认为 `12.4`。支持的版本包括 `12.4`, `12.1`, `12.0`, `11.8`, `11.7`。

**示例:**

```bash
# 使用默认 CUDA 版本 (12.4) 创建一个名为 'my-project' 的容器
bash run_container.sh my-project

# 使用 CUDA 11.8 创建一个名为 'legacy-project' 的容器
bash run_container.sh legacy-project 11.8
```

脚本将执行以下操作：
1.  分配一个唯一的 SSH 端口（从 23 开始）。
2.  在 `/data/<name>` 和 `/data/share/<name>` 创建持久化的工作区目录。
3.  根据 CUDA 版本选择合适的 Docker 镜像。
4.  启动名为 `deep-<name>` 的容器。
5.  为 SSH、JupyterLab 和 TensorBoard 打开必要的防火墙端口。

### 3. 删除一个容器

`del_container.sh` 脚本用于移除容器并可选地清理相关资源。

**使用方法:**
```bash
bash del_container.sh <name> [--port] [--file] [--all]
```
- `<name>`: 要删除的容器名称。
- `--port`: 从 `containers.txt` 中移除端口记录，并关闭相关的防火墙端口。
- `--file`: 删除容器的工作区目录 (`/data/<name>` 和 `/data/share/<name>`)。
- `--all`: 执行所有清理操作 (`--port` 和 `--file`)。

**示例:**

```bash
# 仅删除名为 'deep-my-project' 的 Docker 容器
bash del_container.sh my-project

# 删除容器并关闭防火墙端口
bash del_container.sh my-project --port

# 删除容器及其所有文件
bash del_container.sh my-project --file

# 删除容器及所有相关资源
bash del_container.sh my-project --all
```

## 🖥️ 容器内部操作

### 连接到容器

容器运行后，您可以通过 SSH 连接到它。脚本在创建容器时会输出分配的 SSH 端口。

```bash
ssh root@<server_ip> -p <assigned_ssh_port>
```
默认密码是 `123456`。强烈建议在首次登录后更改密码。

### 管理 JupyterLab

容器内的 `/root/lab.sh` 脚本用于管理 JupyterLab 服务。

**使用方法:**
```bash
# 启动 JupyterLab 服务
bash /root/lab.sh start

# 停止 JupyterLab 服务
bash /root/lab.sh stop

# 查看 JupyterLab 的运行状态
bash /root/lab.sh status
```
- JupyterLab 端口会自动计算为 `<ssh_port> + 8000`。
- 服务在后台运行，日志存储在 `/var/log/jupyter.log` 文件中。
