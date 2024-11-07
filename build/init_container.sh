#!/bin/bash

if [ -n "$SSH_PORT" ]; then
  sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
fi
# TODO: move it to Dockerfile
echo 'for item in $(cat /proc/1/environ | tr "\0" "\n"); do export $item; done' >> /etc/profile

/usr/sbin/sshd -D
