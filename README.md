# AWS Client VPN with SAML SSO
## What is this?
It's bundle of scripts and a statically-compiled OpenVPN that has a few patches that support AWS Client VPN

## Why does it exist?
If you're an AWS customer, and you use the AWS Client VPN you may run into problems if you're a Linux user:
1. It only supports Ubuntu 18.04 or 20.04. No other distributions are supported.
2. It only works on AMD64

I managed to get the official client repackaged into an RPM. It includes a nasty .NET application that requires old versions of some dependencies, so I had to compile them. While this worked for a while, it broke suddenly after a seemingly unrelated system upgrade. I couldn't resolve the issue after 30 minutes of `ldd`ing and `strace`ing so I rolled back my system and decided to do _this_ instead.

## Can't you use regular OpenVPN?
No, it won't work with AWS Client VPN service unless you patch it, and surround it with some extra logic to handle SAML SSO. Thankfully all of the hard work was done by @samm-git here: https://github.com/samm-git/aws-vpn-client

# Building RPM/DEB packages
The purpose of this project is to make it (relatively) simple to download the source files for OpenVPN and all of its dependencies, compile a static `openvpn` binary, and package it up with some scripts and a desktop shortcut to make it easy to use.

1. Clone this repo
2. Run `./build.sh`

# Installing
Just use `dpkg -i` or `rpm -i`, or you'll probably get warnings about the package being unsigned.

# Status
It works! You'll find a desktop shortcut called "OpenVPN AWS Client" in your desktop menu (or /usr/share/applications). When you launch it, you'll be prompted to choose a VPN configuration file from the existing AWS Client VPN configuration directory (`~/.config/AWSVPNClient/OpenVpnConfigs/`). This isn't ideal but it works as a straight-forward replacement for the official VPN client. Once you select a config, the start.sh script will import it, trigger SSO by opening a browser and directing you to your login portal, and will finally start the connection and leave a notification in the system tray.

# TODO
* Add `/usr/local/bin/awsvpn` and a bash-complete to import, list, start or stop connections
* Replace the file-picker `yad` dialog with a form that runs `awsvpn` commands
* Github Actions to build RPM and DEB packages
