#!/bin/bash

PIDFILE_DIR=/var/run/user/${SUDO_USER}

for i in openvpn server start; do
  pkill -F ${PIDFILE_DIR}/${i}.pid
done
