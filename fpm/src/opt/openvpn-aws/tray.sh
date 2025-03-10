#!/bin/bash
RUN_DIR=/var/run/user/${UID}/openvpn-aws
mkdir -p ${RUN_DIR}

interval() {
  if [ -f "${RUN_DIR}/openvpn.pid" ]; then
    fileage=$(( $( date +%s) - $(stat -c %Y -- "${RUN_DIR}/openvpn.pid") ))
    if [ $(( ${fileage} % 300 )) -gt 295 ]; then
      return 0
    fi
  fi
  return 1
}

running() {
  if [ -f ${RUN_DIR}/openvpn.pid ]; then
    pgrep -F ${RUN_DIR}/openvpn.pid >/dev/null
    return $?
  fi
  return 1
}

watcher() {
  while [ 1 ]; do
    if running; then
      echo "connected" > ${RUN_DIR}/status
      if interval; then
        CURRENT_CONNECTION=$(cat $RUN_DIR/current_connection.txt)
        notify-send --app-name openvpn-aws --expire-time 3000 "openvpn-aws" "REMINDER: You are still connected to ${CURRENT_CONNECTION}!" --transient
      fi
    else
      echo "disconnected" > ${RUN_DIR}/status
    fi
    sleep 5
  done
}

# Exit if an existing tray is running
touch ${RUN_DIR}/tray.pid
pkill --signal 0 -F ${RUN_DIR}/tray.pid
if [ $? -eq 0 ]; then
  echo "AWS ClientVPN Manager is already running. Use tray icon to connect/disconnect or exit"
  exit
else
  echo $$ > ${RUN_DIR}/tray.pid
fi

watcher &
WATCHER_PID=$!
yad --notification \
  --image=network-vpn \
  --title "OpenVPN AWS" \
  --text="AWS VPN" \
  --menu="Connect!/opt/openvpn-aws/start.sh|Disconnect!sudo /opt/openvpn-aws/stop.sh|Status!/opt/openvpn-aws/status.sh|Exit!quit" \
  --command="/opt/openvpn-aws/status.sh" \
  --no-middle
kill $WATCHER_PID
