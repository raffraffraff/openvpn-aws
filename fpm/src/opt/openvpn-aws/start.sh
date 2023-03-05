#!/bin/bash

OFFICIAL_CLIENT_CONF_DIR=~/.config/AWSVPNClient/OpenVpnConfigs
PIDFILE_DIR=/var/run/user/${UID}/openvpn-aws
RAND=$(openssl rand -hex 12)

mkdir -p ${PIDFILE_DIR}

# Missing AWS Certificate
export CERT="-----BEGIN CERTIFICATE-----
MIID7zCCAtegAwIBAgIBADANBgkqhkiG9w0BAQsFADCBmDELMAkGA1UEBhMCVVMx
EDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxJTAjBgNVBAoT
HFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4xOzA5BgNVBAMTMlN0YXJmaWVs
ZCBTZXJ2aWNlcyBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAtIEcyMB4XDTA5
MDkwMTAwMDAwMFoXDTM3MTIzMTIzNTk1OVowgZgxCzAJBgNVBAYTAlVTMRAwDgYD
VQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMSUwIwYDVQQKExxTdGFy
ZmllbGQgVGVjaG5vbG9naWVzLCBJbmMuMTswOQYDVQQDEzJTdGFyZmllbGQgU2Vy
dmljZXMgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjCCASIwDQYJKoZI
hvcNAQEBBQADggEPADCCAQoCggEBANUMOsQq+U7i9b4Zl1+OiFOxHz/Lz58gE20p
OsgPfTz3a3Y4Y9k2YKibXlwAgLIvWX/2h/klQ4bnaRtSmpDhcePYLQ1Ob/bISdm2
8xpWriu2dBTrz/sm4xq6HZYuajtYlIlHVv8loJNwU4PahHQUw2eeBGg6345AWh1K
Ts9DkTvnVtYAcMtS7nt9rjrnvDH5RfbCYM8TWQIrgMw0R9+53pBlbQLPLJGmpufe
hRhJfGZOozptqbXuNC66DQO4M99H67FrjSXZm86B0UVGMpZwh94CDklDhbZsc7tk
6mFBrMnUVN+HL8cisibMn1lUaJ/8viovxFUcdUBgF4UCVTmLfwUCAwEAAaNCMEAw
DwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFJxfAN+q
AdcwKziIorhtSpzyEZGDMA0GCSqGSIb3DQEBCwUAA4IBAQBLNqaEd2ndOxmfZyMI
bw5hyf2E3F/YNoHN2BtBLZ9g3ccaaNnRbobhiCPPE95Dz+I0swSdHynVv/heyNXB
ve6SbzJ08pGCL72CQnqtKrcgfU28elUSwhXqvfdqlS5sdJ/PHLTyxQGjhdByPq1z
qwubdQxtRbeOlKyWN7Wg0I8VRw7j6IPdj/3vQQF3zCepYoUz8jcI73HPdwbeyBkd
iEDPfUYd/x7H4c7/I9vG+o1VTqkC50cRRj70/b17KSa7qWFiNyi2LSr2EIZkyXCn
0q23KXB56jzaYyWf/Wi3MOxw+3WKt21gZ7IeyLnp2KhvAotnDU0mV3HaIPzBSlCN
sSi6
-----END CERTIFICATE-----"

# Prompt for an AWS VPN Client configuration
pushd ${OFFICIAL_CLIENT_CONF_DIR}
VPNCONF=$(yad --file)
popd

if [ ! -f "$VPNCONF" ]; then exit; fi

echo "Copying and editing VPN configuration..."
TMPDIR=$(mktemp -d)
cd $TMPDIR
cp $VPNCONF ${TMPDIR}/vpn.conf

sed -i '/^auth-user-pass.*$/d' ${TMPDIR}/vpn.conf
sed -i '/^auth-federate.*$/d' ${TMPDIR}/vpn.conf
sed -i '/^auth-retry.*$/d' ${TMPDIR}/vpn.conf

echo "" >> ${TMPDIR}/vpn.conf
echo "script-security 2" >> ${TMPDIR}/vpn.conf
echo "up /opt/openvpn-aws/update-resolv-conf" >> ${TMPDIR}/vpn.conf
echo "down /opt/openvpn-aws/update-resolv-conf" >> ${TMPDIR}/vpn.conf

perl -i -0pe '$count = 0; s/-----BEGIN.*?-----END CERTIFICATE-----/(++$count == 3)?"$ENV{'CERT'}":$&/gesm;' ${TMPDIR}/vpn.conf

echo "Parsing VPN endpoint and picking a single IP address to connect to"
VPN_HOST=$(cat ${TMPDIR}/vpn.conf | grep 'remote ' | cut -d ' ' -f2)
PORT=$(cat ${TMPDIR}/vpn.conf | grep 'remote ' | cut -d ' ' -f3)
PROTO=$(cat ${TMPDIR}/vpn.conf | grep "proto " | cut -d " " -f2)
SRV=$(dig a +short "${RAND}.${VPN_HOST}"|head -n1)

# Stripping remote DNS records from conf
sed -i '/^remote .*$/d' ${TMPDIR}/vpn.conf
sed -i '/^remote-random-hostname.*$/d' ${TMPDIR}/vpn.conf

# Starting SAML listener
echo "Starting SAML listener an connecting to $VPN_HOST:$PORT over $PROTO"
/opt/openvpn-aws/server &
echo $! > ${PIDFILE_DIR}/server.pid

# Hit VPN endpoint grab VPN_SID and SAML auth URL
OVPN_OUT=$(/opt/openvpn-aws/openvpn --config ${TMPDIR}/vpn.conf --verb 3 \
     --proto "$PROTO" --remote "${SRV}" "${PORT}" \
     --auth-user-pass <( printf "%s\n%s\n" "N/A" "ACS::35001" ) \
    2>&1 | grep AUTH_FAILED,CRV1)

VPN_SID=$(echo "$OVPN_OUT" | awk -F : '{print $7}')
URL=$(echo "$OVPN_OUT" | grep -Eo 'https://.+')
xdg-open $URL

# Wait for the SAML response, and write out the auth-user-pass
echo "Waiting for SAML Authentication response"
while [ 1 ]; do
  if [ -f "${TMPDIR}/saml-response.txt" ]; then
    echo "success"
    pkill -F ${PIDFILE_DIR}/server.pid
    printf "%s\n%s\n" "N/A" "CRV1::${VPN_SID}::$(cat saml-response.txt)" > ${TMPDIR}/auth-user-pass
    rm ${TMPDIR}/saml-response.txt
    break
  else
    TIMER=$((TIMER+1))
  fi
  if [ $TIMER -eq 60 ]; then
    echo "SAML Authentication timed out"
    pkill -F ${PIDFILE_DIR}/server.pid
    exit 1
  else
    echo -n "."
    sleep 1
  fi
done

# Start OpenVPN
echo "Running OpenVPN."
sudo /opt/openvpn-aws/openvpn --config ${TMPDIR}/vpn.conf \
  --verb 3 --auth-nocache --inactive 3600 \
  --proto $PROTO --remote $SRV $PORT \
  --script-security 2 \
  --keepalive 10 60 \
  --auth-user-pass ${TMPDIR}/auth-user-pass &
echo $! > ${PIDFILE_DIR}/openvpn.pid

# Start tray notification
disconnect() {
  yad --button=Disconnect:0 \
      --mouse \
      --undecorated \
      --timeout 3 && sudo /opt/openvpn-aws/stop.sh
}

export -f disconnect

yad --notification \
    --image=network-vpn \
    --title "OpenVPN AWS" \
    --text="AWS VPN" \
    --menu='Disconnect!quit' \
    --command="bash -c disconnect" \
    --no-middle

