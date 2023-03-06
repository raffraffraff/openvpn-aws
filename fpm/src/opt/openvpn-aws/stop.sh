#!/bin/bash

USER_ID=$(id -u $SUDO_USER)
PIDFILE_DIR=/var/run/user/$USER_ID/openvpn-aws

for proc in openvpn server start notification; do
  pkill -F ${PIDFILE_DIR}/${proc}.pid
done
