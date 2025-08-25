#!/bin/bash

# 如果设置了SSH_PORT环境变量，则修改sshd_config中的端口
if [ -n "$SSH_PORT" ]; then
  echo "SSH port set to: $SSH_PORT"
  # 正则表达式会匹配 #Port 22 或 Port 22
  sed -i "s/^#?Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
fi

# 以前台守护进程模式启动SSH服务
echo "Starting SSH server..."
/usr/sbin/sshd -D
