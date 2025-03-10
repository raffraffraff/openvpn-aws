#!/bin/bash
RUN_DIR=/var/run/user/${UID}/openvpn-aws

STATUS=$(cat ${RUN_DIR}/status)
CURRENT_CONNECTION=$(cat ${RUN_DIR}/current_connection.txt)

notify-send --app-name openvpn-aws --expire-time 3000 "marina-internal-euw3" "Status: connected"
