#!/bin/bash

# --- 配置 ---
PID_FILE="/var/run/jupyter.pid"
LOG_FILE="/var/log/jupyter.log"

# 显示使用方法
show_usage() {
    echo "使用方法: bash lab.sh {start|stop|status}"
    echo "  start:  启动 JupyterLab 服务"
    echo "  stop:   停止 JupyterLab 服务"
    echo "  status: 查看 JupyterLab 服务状态"
}

# 启动JupyterLab
start() {
    if [ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") > /dev/null; then
        echo "JupyterLab 已经在运行 (PID: $(cat "$PID_FILE"))"
        exit 0
    fi

    JUPYTER_PORT=$(( ${SSH_PORT:-23} + 8000 ))
    echo "正在启动 JupyterLab, 端口: $JUPYTER_PORT ..."

    nohup jupyter lab --allow-root --no-browser --ip=0.0.0.0 \
        --port=$JUPYTER_PORT \
        --IdentityProvider.token='' \
        --ServerApp.password='' \
        --notebook-dir='/root' > "$LOG_FILE" 2>&1 &

    echo $! > "$PID_FILE"

    sleep 2 # 等待一会确保服务启动
    if ps -p $(cat "$PID_FILE") > /dev/null; then
        echo "JupyterLab 已成功启动 (PID: $(cat "$PID_FILE"))"
    else
        echo "启动 JupyterLab 失败，请查看日志: $LOG_FILE"
        rm "$PID_FILE"
    fi
}

# 停止JupyterLab
stop() {
    if [ ! -f "$PID_FILE" ]; then
        echo "JupyterLab 没有在运行 (未找到PID文件)"
        exit 0
    fi

    PID=$(cat "$PID_FILE")
    echo "正在停止 JupyterLab (PID: $PID)..."
    kill "$PID"
    sleep 2

    if ps -p "$PID" > /dev/null; then
        echo "无法停止进程，尝试强制终止..."
        kill -9 "$PID"
    fi

    rm "$PID_FILE"
    echo "JupyterLab 已停止"
}

# 查看状态
status() {
    if [ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") > /dev/null; then
        echo "JupyterLab 正在运行 (PID: $(cat "$PID_FILE"))"
    else
        echo "JupyterLab 已停止"
    fi
}

# --- 主逻辑 ---
case "$1" in
    start) start ;;
    stop) stop ;;
    status) status ;;
    *) show_usage; exit 1 ;;
esac
