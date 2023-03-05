#!/bin/bash
PKGNAME=openvpn-aws

tar czf /build/packages/${PKGNAME}.tgz --overwrite -C /build/fpm/src opt usr

for PKGFORMAT in deb rpm; do
  fpm --force \
    --name ${PKGNAME} \
    --description "AWS-compatible OpenVPN client with SAML support" \
    --depends yad \
    --input-type tar \
    --output-type ${PKGFORMAT} \
    --after-install fpm/scripts/post-install.sh \
    --before-remove fpm/scripts/pre-uninstall.sh \
    --after-remove fpm/scripts/post-uninstall.sh \
    -a all \
    -p /build/packages/${PKGNAME}.${PKGFORMAT} \
    /build/packages/${PKGNAME}.tgz
done
