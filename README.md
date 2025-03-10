# AWS Client VPN with SAML SSO
## What is this?
This project contains scripts and Dockerfile that can statically compile OpenVPN with a patch to support AWS Client VPN SSO, and output packages in RPM and DEB format.

## Why does it exist?
The native AWS Client VPN is sub-par in general, but it's worse for Linux users because:
1. It only supports Ubuntu 18.04 or 20.04
2. It only works on AMD64

I managed to get the official AWS Client VPN client to work on OpenSUSE Tumbleweed, but it was brittle. It bundled a .NET application that required old versions of some dependencies that I had to compile. While this worked for a few months, it broke unexpectedly after a seemingly unrelated system upgrade. I couldn't resolve the issue after 30 minutes of `ldd`, `strace` etc and had to do a system rollback. Nasty! Since I have to use the AWS Client VPN for work, this meant that I couldn't upgrade my system until I found an alternative.

## Why can't you use regular OpenVPN?
OpenVPN doesn't support AWS Client VPN with SSO authentication unless you patch it and provide some additional automation to launch a browser, grab a token etc. Thankfully the hard work was done by @samm-git here: https://github.com/samm-git/aws-vpn-client. I'm just making the whole thing easier (for me!) by wrapping it in a Dockerfile and spitting out RPM / DEB packages.

## Compiling
This project downloads the source files for OpenVPN, patches them and builds a static `openvpn` binary. This means it should work on most Linux systems. 

## Packaging
I used FPM to build two packages, an `.rpm` and a `.deb`, since they are suppored by a large number of Linux distrubtions.

# Do it!
1. Clone this repo
2. Run `./build.sh`
3. Install the package (`dpkg -i` or `rpm -i`, and ignore warnings about it being an unsigned package)

# Status
You should find a desktop shortcut called "OpenVPN AWS Client" in your desktop menu (or /usr/share/applications). When you launch it, you'll be prompted to choose a VPN configuration file from the existing AWS Client VPN configuration directory (`~/.config/AWSVPNClient/OpenVpnConfigs/`). This isn't ideal but it works as a straight-forward replacement for the official VPN client. Once you select a configuration, the `start.sh` script will import it, trigger SSO by opening a browser and directing you to your login portal, and will finally start the connection and leave a notification in the system tray.

# TODO (or maybe not)
* Replace everything with a single go binary with shell auto-complete
* Replace the file-picker `yad` dialog with a form that runs `awsvpn` commands
* Github Actions to build RPM and DEB packages
