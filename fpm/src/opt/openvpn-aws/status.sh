#!/bin/bash
RUN_DIR=/var/run/user/${UID}/openvpn-aws

if [ -f "${RUN_DIR}/status" ]; then
  STATUS=$(cat ${RUN_DIR}/status)
else
  STATUS="unknown status"
fi
if [ -f "${RUN_DIR}/current_connection.txt" ]; then
  CURRENT_CONNECTION=$(cat ${RUN_DIR}/current_connection.txt)
else
  CURRENT_CONNECTION="Unknown connection"
fi

notify-send --app-name openvpn-aws --expire-time 3000 "${CURRENT_CONNECTION}" "Status: ${STATUS}"
