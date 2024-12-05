#!/bin/bash
AWSVPNCLIENT_CONF_DIR=~/.config/AWSVPNClient/OpenVpnConfigs
RUN_DIR=/var/run/user/${UID}/openvpn-aws

# FUNCTIONS
get_conf() {
  CURRENT_CONNECTION=$(cat ${RUN_DIR}/current_connection.txt)
  
  VPNCONF=$(find ${AWSVPNCLIENT_CONF_DIR} -type f -name "*.ovpn" -exec basename {} \; | sort | yad --separator='' --mouse --width=330 --height=250 --skip-taskbar --image=network-vpn --title "AWS Client VPN" --text "Choose a connection" --list --on-top --undecorated --mouse --list --column "select" --no-headers)

  [[ ! -f "${AWSVPNCLIENT_CONF_DIR}/$VPNCONF" ]] && return 1

  # Copy and edit VPN configuration file
  cp ${AWSVPNCLIENT_CONF_DIR}/$VPNCONF ${RUN_DIR}/vpn.conf
  sed -i '/^auth-user-pass.*$/d' ${RUN_DIR}/vpn.conf
  sed -i '/^auth-federate.*$/d' ${RUN_DIR}/vpn.conf
  sed -i '/^auth-retry.*$/d' ${RUN_DIR}/vpn.conf
  echo "" >> ${RUN_DIR}/vpn.conf
  echo "script-security 2" >> ${RUN_DIR}/vpn.conf
  echo "up /opt/openvpn-aws/update-resolv-conf" >> ${RUN_DIR}/vpn.conf
  echo "down /opt/openvpn-aws/update-resolv-conf" >> ${RUN_DIR}/vpn.conf

  # Parsing VPN endpoint and picking a single IP address to connect to
  VPN_NAME=${VPNCONF%%.*}
  VPN_HOST=$(awk '/^remote / {print $2}' ${RUN_DIR}/vpn.conf)
  VPN_PORT=$(awk '/^remote / {print $3}' ${RUN_DIR}/vpn.conf)
  VPN_PROTO=$(awk '/^proto / {print $2}' ${RUN_DIR}/vpn.conf)
  VPN_SRV=$(dig a +short "${RANDOM}.${VPN_HOST}"|head -n1)
  
  # Stripping remote DNS records from conf
  sed -i '/^remote .*$/d' ${RUN_DIR}/vpn.conf
  sed -i '/^remote-random-hostname.*$/d' ${RUN_DIR}/vpn.conf
}

update_current_connection() {
  echo ${VPNCONF%%.ovpn} > ${RUN_DIR}/current_connection.txt
}

connect() {
  OVPN_OUT=$(/opt/openvpn-aws/openvpn --config ${RUN_DIR}/vpn.conf --verb 3 \
     --proto "$VPN_PROTO" --remote "${VPN_SRV}" "${VPN_PORT}" \
     --auth-user-pass <( printf "%s\n%s\n" "N/A" "ACS::35001" ) \
    2>&1 | grep AUTH_FAILED,CRV1)

  VPN_SID=$(echo "$OVPN_OUT" | awk -F : '{print $7}')
  SSO_URL=$(echo "$OVPN_OUT" | grep -Eo 'https://.+')

  # Start localhost server to capture SAML response and open SSO url
  [[ -f ${RUN_DIR}/server.pid ]] && pkill -F ${RUN_DIR}/server.pid
  cd ${RUN_DIR}
  /opt/openvpn-aws/server &
  echo $! > ${RUN_DIR}/server.pid
  xdg-open $SSO_URL

  # Allow 60s to authenticate
  while [ 1 ]; do
    if [ -f "${RUN_DIR}/saml-response.txt" ]; then
      pkill -F ${RUN_DIR}/server.pid
      break
    else
      TIMER=$((TIMER+1))
    fi
    if [ $TIMER -eq 60 ]; then
      echo "SAML Authentication timed out after 20 seconds"
      return 1
    else
      sleep 1
    fi
  done

  # Convert saml-response.txt to auth-user-pass
  printf "%s\n%s\n" "N/A" "CRV1::${VPN_SID}::$(cat ${RUN_DIR}/saml-response.txt)" > ${RUN_DIR}/auth-user-pass

  # Start the VPN
  sudo /opt/openvpn-aws/openvpn --config ${RUN_DIR}/vpn.conf \
  --verb 3 --auth-nocache --inactive 3600 \
  --proto "$VPN_PROTO" --remote "$VPN_SRV" "$VPN_PORT" \
  --script-security 2 \
  --keepalive 10 60 \
  --auth-user-pass ${RUN_DIR}/auth-user-pass \
  --writepid ${RUN_DIR}/openvpn.pid \
  --daemon openvpn
}

cleanup() {
  for file in saml-response.txt auth-user-pass; do
    if [ -f ${RUN_DIR}/$file ]; then
      rm -f ${RUN_DIR}/$file
    fi
  done
}

check() {
  while [ 1 ]; do
    grep -q "^connected" ${RUN_DIR}/status && break
    SLEEP=$((SLEEP + 1))
    sleep 1
    if [ $SLEEP -gt 30 ]; then
      echo "failed" > ${RUN_DIR}/status
      return 1
    fi
  done
  return 0
}

#MAIN
if [ -f ${RUN_DIR}/openvpn.pid ]; then
  OPENVPN_PID=$(cat ${RUN_DIR}/openvpn.pid)
  ps h -p $OPENVPN_PID -o comm | grep -q openvpn
  if [ $? -eq 0 ]; then
    ls /sys/class/net | grep -q tun
    if [ $? -eq 1 ]; then
      yad --error \
        --title "Notice" \
        --text "OpenVPN is running, but the connection may have terminated. Killing OpenVPN..." \
        --window-icon=yast-security \
        --skip-taskbar --button "Continue:0"
      sudo /opt/openvpn-aws/stop.sh
    else
      yad --error \
        --title "Oops!" \
        --text "A VPN connection is already established" \
        --window-icon=yast-security \
        --skip-taskbar --button "Exit:0"
      exit
    fi
  fi
fi

echo "connecting" > ${RUN_DIR}/status
cleanup
get_conf || exit
update_current_connection
while [ 1 ]; do
  TRIES=$((TRIES + 1))
  connect
  check && break
  if [ $TRIES -gt 3 ]; then break; fi
  pkill -F ${RUN_DIR}/server.pid
done
cleanup
