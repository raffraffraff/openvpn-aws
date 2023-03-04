#!/bin/ash
tar czf awsvpnclient.tgz -C /fpm/src opt etc usr

for output_type in deb rpm; do
  fpm --name awsvpnclient \
    --version ${OPENVPN_VERSION} \
    --description "AWS VPN Client based on statically compiled openvpn" \
    --depends yad \
    --input-type tar \
    --output-type ${output_type} \
    --after-install scripts/post-install.sh \
    --before-remove scripts/pre-uninstall.sh \
    --after-remove scripts/post-uninstall.sh \
    -a all \
    awsvpnclient.tgz
done

cp awsvpnclient* /output
