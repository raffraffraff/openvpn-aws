#!/bin/ash
tar czf openvpn-aws.tgz -C /build/fpm/src opt etc usr

for output_type in deb rpm; do
  fpm --name openvpn-aws \
    --description "AWS VPN Client based on statically compiled openvpn" \
    --depends yad \
    --input-type tar \
    --output-type ${output_type} \
    --after-install fpm/scripts/post-install.sh \
    --before-remove fpm/scripts/pre-uninstall.sh \
    --after-remove fpm/scripts/post-uninstall.sh \
    -a all \
    openvpn-aws.tgz
done

cp openvpn-aws* /build/packages
