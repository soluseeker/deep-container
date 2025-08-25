#!/bin/bash

# 如果设置了SSH_PORT环境变量，则修改sshd_config中的端口
if [ -n "$SSH_PORT" ]; then
  echo "SSH port set to: $SSH_PORT"
  sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
fi

echo 'for item in $(cat /proc/1/environ | tr "\0" "\n"); do export $item; done' >> /etc/profile

/usr/sbin/sshd -D
