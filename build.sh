#!/bin/bash
docker build -t openvpn-aws-packager .
docker run --rm --name tmp-builder -v $(pwd)/packages:/build/packages openvpn-aws-packager
