#!/bin/bash

USER_ID=$(id -u $SUDO_USER)
PIDFILE_DIR=/var/run/user/$USER_ID

for i in openvpn server start; do
  pkill -F ${PIDFILE_DIR}/${i}.pid
done
