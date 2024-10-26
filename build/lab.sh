#!/bin/bash

# 检查是否传入参数
if [ $# -eq 0 ]; then
    echo "usage: bash lab.sh {start|stop}"
    exit 1
fi

# 处理参数
case "$1" in
    start)
        JUPYTER_PORT=$((${SSH_PORT:-8000} + 8000))
        echo "正在启动 JupyterLab, 运行在端口: $JUPYTER_PORT ..."
        nohup jupyter lab --allow-root --no-browser --port=$JUPYTER_PORT --ip=0.0.0.0 --IdentityProvider.token='' --ServerApp.password='' --notebook-dir='/root' > /dev/null 2>&1 &
        if [ $? -eq 0 ]; then
            echo "JupyterLab 已启动，端口号为: $JUPYTER_PORT。"
        else
            echo "启动 JupyterLab 失败。"
        fi
        ;;
    stop)
        echo "正在停止 JupyterLab..."
        # 查找 JupyterLab 的进程并终止
        pkill -f "jupyter-lab"
        if [ $? -eq 0 ]; then
            echo "JupyterLab 已停止。"
        else
            echo "停止 JupyterLab 失败。JupyterLab 可能没有运行。"
        fi
        ;;
    *)
        echo "无效选项: $1"
        echo "usage: bash lab.sh {start|stop}"
        exit 1
        ;;
esac
