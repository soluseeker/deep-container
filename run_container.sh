#!/bin/bash

# 参数检查
if [ -z "$1" ]; then
  echo "请传递容器名参数 格式为: bash run_container.sh <name>"
  exit 1
fi

NAME=$1
FILE="containers.txt"

# 判断文件是否存在，如果不存在则创建
if [ ! -f "$FILE" ]; then
    touch "$FILE"
    echo "文件 $FILE 不存在，已创建。"
fi

# 在文件中搜索名字对应的端口号
PORT=$(grep "^$NAME " $FILE | awk '{print $2}')

if [ -n "$PORT" ]; then
  # 如果找到了名字对应的端口号
  echo "该容器名存在对应端口号: $PORT"
else
  # 如果没有找到对应的名字，检查端口号是否递增
  echo "容器名未找到，正在检查端口号递增情况..."
  PORTS=$(awk '{print $2}' $FILE | sort -n)
  
  # 检查是否从23开始递增
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
    # 没有缺失端口，添加新的端口
    PORT=$EXPECTED_PORT
    echo "$NAME $PORT" >> $FILE
    echo "未找到缺失端口，将添加新的端口: $PORT"
  else
    # 有缺失端口，补充缺失的端口号
     PORT=$MISSING_PORT
    echo "$NAME $MISSING_PORT" >> $FILE
    echo "存在缺失端口，将使用该端口号: $PORT"
  fi
fi


# 工作空间目录前缀
WORKSPACE_DIR_PREFIX="/data"
# Docker镜像名称
DOCKER_IMAGE="cuda:12.4.1-cudnn-devel-miniconda-jupyter-ubuntu22.04"


# 定义工作目录
WORKSPACE_DIR="${WORKSPACE_DIR_PREFIX}/${NAME}"
WORKSPACE_SHARE_DIR="${WORKSPACE_DIR_PREFIX}/share/${NAME}"
WORKSPACE_PUB_DIR="${WORKSPACE_DIR_PREFIX}/share/public"
# 创建挂载目录
mkdir -p "${WORKSPACE_DIR}"
mkdir -p "${WORKSPACE_SHARE_DIR}"
mkdir -p "${WORKSPACE_DIR}/workspace"
# Docker启动命令
docker run -itd --gpus all --name "deep-${NAME}" --net=host -e SSH_PORT="${PORT}" -v "${WORKSPACE_DIR}":/root/workspace -v "${WORKSPACE_SHARE_DIR}":/root/share -v "${WORKSPACE_PUB_DIR}":/root/public ${DOCKER_IMAGE}

# 检查端口是否已经开放
if firewall-cmd --zone=public --query-port="${PORT}/tcp"; then
  echo "端口 ${PORT}/tcp 已经开放，跳过防火墙设置"
else
  # 如果端口没有开放，则添加到防火墙并重载
  firewall-cmd --zone=public --add-port="${PORT}/tcp" --permanent
  firewall-cmd --reload
  echo "已为端口 ${PORT}/tcp 添加防火墙规则并重新加载防火墙"
fi

# 检查端口 PORT+8000 是否已经开放
JUPYTER_PORT=$((PORT + 8000))
if firewall-cmd --zone=public --query-port="${JUPYTER_PORT}/tcp"; then
  echo "端口 ${JUPYTER_PORT}/tcp 已经开放，跳过防火墙设置"
else
  # 如果端口没有开放，则添加到防火墙并重载
  firewall-cmd --zone=public --add-port="${JUPYTER_PORT}/tcp" --permanent
  firewall-cmd --reload
  echo "已为端口 ${JUPYTER_PORT}/tcp 添加防火墙规则并重新加载防火墙"
fi

# 输出容器端口号
echo "容器已启动，端口号为: $PORT"
echo "Jupyter Notebook端口号为: $JUPYTER_PORT"
