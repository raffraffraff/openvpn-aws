# AWS Client VPN with SAML SSO
If you're an AWS customer, and you use the AWS Client VPN you will run into problems if you're a Linux user. The official client has a number of major issues:
1. It only supports Ubuntu 18.04 or 20.04. No other distributions are supported.
2. It only works on AMD64
3. It's a basty .NET application

I managed to get it repackaged into an RPM (which took half a day to compile some old dependencies) and it worked for a while. Then one day, after upgrading some unrelated system packages, it just ... _broke_. I tried `ldd`/`strace` etc but in the end I had to use snapper to roll back my system to a working state, and I had to leave it in that state in case it broke again!

# Can't you use regular OpenVPN?
No. The AWS Client VPN doesn't work unless you patch OpenVPN. And the SAML SSO solution requires some additional logic on the client-side. Thankfully all of the hard work was done by @samm-git here: https://github.com/samm-git/aws-vpn-client

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
