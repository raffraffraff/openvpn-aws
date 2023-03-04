# Draft! Not 100% working yet
This project is based on existing work by @samm-git here: https://github.com/samm-git/aws-vpn-client

## Changes:
* Using latest stable versions of openvpn, openssl, lz4
* Build a static binary (in a Docker container)
* Output a simple FPM packager container with the static binaries

## Motivation
1. The official AWS VPN Client is clunky (uses .NET, and intermittently breaks on OpenSUSE Tumbleweed)
2. The existing aws-vpn-client project is out of date and leaves extra work for the user

## Usage
Run `./build.sh`
