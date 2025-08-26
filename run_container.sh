#!/bin/bash

# --- 配置 ---
DEFAULT_CUDA_VERSION="12.8"
CONTAINERS_FILE="containers.txt"
WORKSPACE_PREFIX="/data"
BASE_PORT=23

# --- 函数定义 ---

# 显示使用方法
show_usage() {
    echo "使用方法: bash run_container.sh <name> [cuda_version]"
    echo "  <name>:         容器名 (例如: my-container)"
    echo "  [cuda_version]: CUDA版本 (可选, 默认: $DEFAULT_CUDA_VERSION)"
    echo "  支持的版本: 12.8, 12.6, 12.4, 12.1, 11.8"
}

# 根据CUDA版本获取Docker镜像名称
get_docker_image() {
    case $1 in
        "12.8") echo "cuda:12.8.1-cudnn-miniconda-ubuntu24.04" ;;
        "12.6") echo "cuda:12.6.3-cudnn-miniconda-ubuntu24.04" ;;
        "12.4") echo "cuda:12.4.1-cudnn-miniconda-ubuntu22.04" ;;
        "12.1") echo "cuda:12.1.1-cudnn-miniconda-ubuntu22.04" ;;
        "11.8") echo "cuda:11.8.0-cudnn-miniconda-ubuntu22.04" ;;
        *) echo "" ;;
    esac
}

# 获取或分配端口号
get_or_assign_port() {
    local name=$1
    [ ! -f "$CONTAINERS_FILE" ] && touch "$CONTAINERS_FILE"

    # 查找现有端口
    local existing_port=$(grep "^$name " "$CONTAINERS_FILE" | awk '{print $2}')
    if [ -n "$existing_port" ]; then
        echo "$existing_port"
        return
    fi

    # 分配新端口 - 找到第一个可用端口
    local used_ports=$(awk '{print $2}' "$CONTAINERS_FILE" | sort -n)
    local new_port=$BASE_PORT
    for port in $used_ports; do
        [ "$port" -eq "$new_port" ] && new_port=$((new_port + 1)) || break
    done

    echo "$name $new_port" >> "$CONTAINERS_FILE"
    echo "$new_port"
}

# 开放防火墙端口
open_firewall_port() {
    local port=$1
    if firewall-cmd --zone=public --query-port="${port}/tcp" >/dev/null 2>&1; then
        echo "端口 ${port}/tcp 已开放"
    else
        firewall-cmd --zone=public --add-port="${port}/tcp" --permanent >/dev/null 2>&1
        firewall-cmd --reload >/dev/null 2>&1
        echo "已为端口 ${port}/tcp 添加防火墙规则"
    fi
}

# --- 主逻辑 ---

# 参数解析
if [ -z "$1" ]; then
    show_usage
    exit 1
fi
NAME=$1
CUDA_VERSION=${2:-$DEFAULT_CUDA_VERSION}

# 获取Docker镜像
DOCKER_IMAGE=$(get_docker_image "$CUDA_VERSION")
if [ -z "$DOCKER_IMAGE" ]; then
    echo "错误: 不支持的CUDA版本 '$CUDA_VERSION'" >&2
    show_usage
    exit 1
fi
echo "使用CUDA版本: $CUDA_VERSION"
echo "Docker镜像: $DOCKER_IMAGE"

# 获取端口
PORT=$(get_or_assign_port "$NAME")
echo "为容器 '$NAME' 分配SSH端口: $PORT"

# 创建工作目录
WORKSPACE_DIR="${WORKSPACE_PREFIX}/${NAME}"
WORKSPACE_SHARE_DIR="${WORKSPACE_PREFIX}/share/${NAME}"
WORKSPACE_PUB_DIR="${WORKSPACE_PREFIX}/share/public"
mkdir -p "${WORKSPACE_DIR}" "${WORKSPACE_SHARE_DIR}"

# 启动容器
echo "正在启动容器 deep-${NAME}..."
docker run -itd --gpus all --ipc=host --net=host --restart=always \
    --name "deep-${NAME}" \
    -e SSH_PORT="${PORT}" \
    -v "${WORKSPACE_DIR}":/root/workspace \
    -v "${WORKSPACE_SHARE_DIR}":/root/share \
    -v "${WORKSPACE_PUB_DIR}":/root/public \
    ${DOCKER_IMAGE}

# 配置防火墙
JUPYTER_PORT=$((PORT + 8000))
LOGGING_PORT=$((PORT + 6000))
open_firewall_port "$PORT"
open_firewall_port "$JUPYTER_PORT"
open_firewall_port "$LOGGING_PORT"

# 输出最终信息
echo -e "\n容器 'deep-${NAME}' 已成功启动!"
echo "  SSH 端口: $PORT"
echo "  Jupyter 端口: $JUPYTER_PORT"
echo "  TensorBoard 端口: $LOGGING_PORT"
