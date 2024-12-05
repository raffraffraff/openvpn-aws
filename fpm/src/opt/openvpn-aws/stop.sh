#!/bin/bash
USER_ID=$(id -u $SUDO_USER)
echo "disconnecting" > /var/run/user/$USER_ID/openvpn-aws/status
pkill -F /var/run/user/$USER_ID/openvpn-aws/openvpn.pid
pkill -F /var/run/user/$USER_ID/openvpn-aws/server.pid
