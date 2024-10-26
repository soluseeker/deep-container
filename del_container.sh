#!/bin/bash

# 检查是否传入了名字参数
if [ -z "$1" ]; then
    echo "Usage: bash del_container.sh <name> [--port] [--file] [--all]"
    exit 1
fi

# 获取第一个参数 xxx
NAME=$1
CONTAINER_NAME="deep-$NAME"

# 检查容器是否存在并删除
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME\$"; then
    echo "Deleting Docker container: $CONTAINER_NAME"
    docker rm -f "$CONTAINER_NAME"
else
    echo "Docker container $CONTAINER_NAME not found."
fi

# 标志变量，用于确认是否有传入选项
DELETE_PORT=false
DELETE_FILE=false

# 处理可选参数 --port, --file, --all
shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port)
            DELETE_PORT=true
            shift
            ;;
        --file)
            DELETE_FILE=true
            shift
            ;;
        --all)
            DELETE_PORT=true
            DELETE_FILE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# 删除 containers.txt 文件中的一行内容
if [ "$DELETE_PORT" = true ]; then
    PORT_FILE="containers.txt"
    if [ -f "$PORT_FILE" ]; then
        echo "Removing entry for $NAME from $PORT_FILE"
        sed -i "/^$NAME /d" "$PORT_FILE"
    else
        echo "$PORT_FILE not found."
    fi
fi

if [ "$DELETE_FILE" = true ]; then
    DATA_DIR="/data/$NAME"
    DATA_SHARE_DIR="/data/share/$NAME"
    if [ -d "$DATA_DIR" ]; then
        echo "Deleting folder: $DATA_DIR"
        rm -rf "$DATA_DIR"
    else
        echo "Directory $DATA_DIR not found."
    fi

    if [ -d "$DATA_SHARE_DIR" ]; then
        echo "Deleting folder: $DATA_SHARE_DIR"
        rm -rf "$DATA_SHARE_DIR"
    else
        echo "Directory $DATA_SHARE_DIR not found."
    fi
fi
