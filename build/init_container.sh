#!/bin/bash

if [ -n "$SSH_PORT" ]; then
  sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
  echo "SSH Port is be setted $SSH_PORT"
  echo "export SSH_PORT=$SSH_PORT" >> /etc/profile
  JUPYTER_PORT=$((8000 + SSH_PORT))
  nohup jupyter lab --allow-root --no-browser --port=$JUPYTER_PORT --ip=0.0.0.0 --IdentityProvider.token='' --ServerApp.password='' --notebook-dir='/root' > /dev/null 2>&1 &
fi

/usr/sbin/sshd -D
