#!/bin/bash
RUN_DIR=/var/run/user/${UID}/openvpn-aws

STATUS=$(cat ${RUN_DIR}/status)
CURRENT_CONNECTION=$(cat ${RUN_DIR}/current_connection.txt)

yad --button="${CURRENT_CONNECTION} ${STATUS:-unknown}:0" \
      --mouse \
      --skip-taskbar \
      --undecorated \
      --on-top \
      --timeout 2
