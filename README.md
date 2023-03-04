# Draft! Not 100% working yet
This project is based on existing work by @samm-git here: https://github.com/samm-git/aws-vpn-client

## Changes:
* Using current latest versions of OpenVPN, OpenSSL.
* Build static `openvpn` and `server` binaries in an Ubuntu docker container
* Create a simple FPM packager container that can produce RPM or DEB files

## Motivation
1. AWS VPN Client is nasty (uses .NET, and intermittently breaks on OpenSUSE Tumbleweed)
2. The existing aws-vpn-client project is out of date and leaves extra work for the user

## Usage
1. Build the awsvpnclient-packager image: `docker build -t awsvpnclient-packager .`
2. Create a package for your Linux distribution: `docker run -v $(pwd):/output awsvpnclient-packager rpm`
