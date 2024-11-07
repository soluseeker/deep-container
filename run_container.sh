#!/bin/bash

# arguments check
if [ -z "$1" ]; then
  echo "请传递容器名(deep-<name>) 格式为: bash run_container.sh <name>"
  exit 1
fi

NAME=$1
FILE="containers.txt"

# Check if the file exists, if not, create it
if [ ! -f "$FILE" ]; then
    touch "$FILE"
    echo "端口管理文件 $FILE 不存在，正在创建。"
fi

# Search for the port number corresponding to the name in the file
PORT=$(grep "^$NAME " $FILE | awk '{print $2}')

if [ -n "$PORT" ]; then
  # If the port number corresponding to the name is found
  echo "端口管理文件中存在该容器名历史记录，将使用对应端口号: $PORT。"
else
  # If the corresponding name is not found, check if the port number is incrementing
  echo "未在端口管理文件中找到该容器名，正在检查端口管理文件端口号递增情况..."
  PORTS=$(awk '{print $2}' $FILE | sort -n)
  
  # Check if it increments from 23
  EXPECTED_PORT=23
  MISSING_PORT=""

  for PORT in $PORTS; do
    if [ "$PORT" -ne "$EXPECTED_PORT" ]; then
      MISSING_PORT=$EXPECTED_PORT
      break
    fi
    EXPECTED_PORT=$((EXPECTED_PORT + 1))
  done

  if [ -z "$MISSING_PORT" ]; then
    # No missing port, add a new port
    PORT=$EXPECTED_PORT
    echo "$NAME $PORT" >> $FILE
    echo "未找到缺失端口，将添加新的端口: $PORT"
  else
    # Missing port found, use the missing port number
     PORT=$MISSING_PORT
    echo "$NAME $MISSING_PORT" >> $FILE
    echo "存在缺失端口，将使用该端口号: $PORT"
  fi
fi


# Workspace directory prefix
WORKSPACE_DIR_PREFIX="/data"
# Docker image name
DOCKER_IMAGE="cuda:12.4.1-cudnn-miniconda-ubuntu22.04"


# Define workspace directories
WORKSPACE_DIR="${WORKSPACE_DIR_PREFIX}/${NAME}"
WORKSPACE_SHARE_DIR="${WORKSPACE_DIR_PREFIX}/share/${NAME}"
WORKSPACE_PUB_DIR="${WORKSPACE_DIR_PREFIX}/share/public"
# Create mount directories
mkdir -p "${WORKSPACE_DIR}"
mkdir -p "${WORKSPACE_SHARE_DIR}"
# Docker run command
docker run -itd --gpus all --name "deep-${NAME}" --net=host -e SSH_PORT="${PORT}" -v "${WORKSPACE_DIR}":/root/workspace -v "${WORKSPACE_SHARE_DIR}":/root/share -v "${WORKSPACE_PUB_DIR}":/root/public ${DOCKER_IMAGE}

# Check if the port is already open
if firewall-cmd --zone=public --query-port="${PORT}/tcp"; then
  echo "端口 ${PORT}/tcp 已经开放，跳过防火墙设置"
else
  # If the port is not open, add it to the firewall and reload
  firewall-cmd --zone=public --add-port="${PORT}/tcp" --permanent
  firewall-cmd --reload
  echo "已为端口 ${PORT}/tcp 添加防火墙规则并重新加载防火墙"
fi

# Check if the port PORT+8000 is already open
JUPYTER_PORT=$((PORT + 8000))
if firewall-cmd --zone=public --query-port="${JUPYTER_PORT}/tcp"; then
  echo "端口 ${JUPYTER_PORT}/tcp 已经开放，跳过防火墙设置"
else
  # If the port is not open, add it to the firewall and reload
  firewall-cmd --zone=public --add-port="${JUPYTER_PORT}/tcp" --permanent
  firewall-cmd --reload
  echo "已为端口 ${JUPYTER_PORT}/tcp 添加防火墙规则并重新加载防火墙"
fi

# Output container port number
echo "容器已启动，端口号为: $PORT"
echo "Jupyter Notebook端口号为: $JUPYTER_PORT"
