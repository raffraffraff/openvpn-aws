#!/bin/bash
RUN_DIR=/var/run/user/${UID}/openvpn-aws

fileage() {
  echo $(( $( date +%s) - $(stat -c %Y -- "${RUN_DIR}/openvpn.pid") ))
}

watcher() {
  while [ 1 ]; do
    if [ -f ${RUN_DIR}/openvpn.pid ]; then
      pgrep -F ${RUN_DIR}/openvpn.pid
      echo "OpenVPN pid file found, running status $RUNNING"
      if [ $(( $(fileage) % 300 )) -gt 295 ]; then
        CURRENT_CONNECTION=$(cat $RUN_DIR/current_connection.txt)
	notify-send --app-name openvpn-aws --expire-time 3000 "openvpn-aws" "REMINDER: You are still connected to ${CURRENT_CONNECTION}!" --transient
      fi
    else
      echo "No OpenVPN pid found"
    fi
    sleep 5
  done
} 

mkdir -p ${RUN_DIR}
touch ${RUN_DIR}/tray.pid
pkill --signal 0 -F ${RUN_DIR}/tray.pid
if [ $? -eq 0 ]; then
  echo "AWS ClientVPN running. Use tray icon to connect/disconnect or exit"
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
