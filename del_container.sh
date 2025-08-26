#!/bin/bash

# --- 配置 ---
PORT_FILE="containers.txt"
DATA_PREFIX="/data"

# --- 函数定义 ---

# 显示使用方法
show_usage() {
    echo "使用方法: bash del_container.sh <name> [--port] [--file] [--all]"
    echo "  <name>:   容器名"
    echo "  --port:   删除端口记录并关闭防火墙端口"
    echo "  --file:   删除工作目录文件"
    echo "  --all:    执行 --port 和 --file 的所有操作"
}

# 关闭防火墙端口
close_firewall_port() {
    local port=$1
    if firewall-cmd --zone=public --query-port="${port}/tcp" >/dev/null 2>&1; then
        firewall-cmd --zone=public --remove-port="${port}/tcp" --permanent >/dev/null 2>&1
        echo "已关闭防火墙端口: ${port}/tcp"
        return 0 # 表示有变动
    fi
    return 1 # 表示无变动
}

# 处理端口和防火墙
handle_ports() {
    local name=$1
    [ ! -f "$PORT_FILE" ] && return

    local port=$(grep "^$name " "$PORT_FILE" | awk '{print $2}')
    if [ -n "$port" ]; then
        echo "找到容器 '$name' 的端口: $port"
        local changed=0
        close_firewall_port "$port" && changed=1
        close_firewall_port "$((port + 8000))" && changed=1
        close_firewall_port "$((port + 6000))" && changed=1

        [ "$changed" -eq 1 ] && firewall-cmd --reload >/dev/null 2>&1 && echo "防火墙规则已重新加载"

        echo "正在从 $PORT_FILE 中移除 '$name' 的记录"
        sed -i "/^$name /d" "$PORT_FILE"
    else
        echo "在 $PORT_FILE 中未找到 '$name' 的端口记录"
    fi
}

# 删除工作目录文件
handle_files() {
    local name=$1
    local data_dir="${DATA_PREFIX}/${name}"
    local share_dir="${DATA_PREFIX}/share/${name}"

    [ -d "$data_dir" ] && echo "正在删除目录: $data_dir" && rm -rf "$data_dir"
    [ -d "$share_dir" ] && echo "正在删除目录: $share_dir" && rm -rf "$share_dir"
}

# --- 主逻辑 ---

# 参数检查
if [ -z "$1" ]; then
    show_usage
    exit 1
fi

NAME=$1
CONTAINER_NAME="deep-$NAME"
shift # 移除容器名参数，方便后续处理

# 删除Docker容器
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME\$"; then
    echo "正在删除Docker容器: $CONTAINER_NAME"
    docker rm -f "$CONTAINER_NAME"
else
    echo "Docker容器 $CONTAINER_NAME 未找到"
fi

# 处理附加选项
DELETE_PORT=false
DELETE_FILE=false

for arg in "$@"; do
    case "$arg" in
        --port) DELETE_PORT=true ;;
        --file) DELETE_FILE=true ;;
        --all) DELETE_PORT=true; DELETE_FILE=true ;;
        *) echo "未知选项: $arg"; show_usage; exit 1 ;;
    esac
done

[ "$DELETE_PORT" = true ] && handle_ports "$NAME"
[ "$DELETE_FILE" = true ] && handle_files "$NAME"

echo "操作完成"
