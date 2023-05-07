# AWS Client VPN with SAML SSO
## What is this?
It's bundle of scripts and a Dockerfile that statically compiles OpenVPN with a patch to support AWS Client VPN SSO and produces packages in RPM and DEB format.

## Why does it exist?
The native AWS Client VPN is sub-par in general, but it's worse for Linux users because:
1. It only supports Ubuntu 18.04 or 20.04
2. It only works on AMD64

While I eventually got the official client to work on OpenSUSE Tumbleweed, it was brittle. It bundles a .NET application that required old versions of some dependencies that I had to compile. While this worked for a few months, it broke unexpectedly after a seemingly unrelated system upgrade. I couldn't resolve the issue after 30 minutes of `ldd`ing and `strace`ing I had to roll back my system. Since I have to use the AWS Client VPN for work, this meant that I couldn't upgrade my system until I found an alternative.

## Why can't you use regular OpenVPN?
OpenVPN doesn't support AWS Client VPN SSO without a patch it and extra scripting to launch a broser and grab a token. Thankfully all of the hard work was done by @samm-git here: https://github.com/samm-git/aws-vpn-client. I'm just making the whole thing easier by wrapping it in a Dockerfile and providing some extra automation. 

## Compiling
This project downloads the source files for OpenVPN, patches them and builds a static `openvpn` binary. This means it should work on most Linux systems. 

## Packaging
I used FPM to build two packages, an `.rpm` and a `.deb`, since they are suppored by a huge number of Linux distrubtions.

# Do it!
1. Clone this repo
2. Run `./build.sh`
3. Install the package (`dpkg -i` or `rpm -i`, and ignore warnings about it being an unsigned package)

# Status
It works! You'll find a desktop shortcut called "OpenVPN AWS Client" in your desktop menu (or /usr/share/applications). When you launch it, you'll be prompted to choose a VPN configuration file from the existing AWS Client VPN configuration directory (`~/.config/AWSVPNClient/OpenVpnConfigs/`). This isn't ideal but it works as a straight-forward replacement for the official VPN client. Once you select a config, the start.sh script will import it, trigger SSO by opening a browser and directing you to your login portal, and will finally start the connection and leave a notification in the system tray.

# TODO (or to never do, since it works)
* Add `/usr/local/bin/awsvpn` and a bash-complete to import, list, start or stop connections
* Replace the file-picker `yad` dialog with a form that runs `awsvpn` commands
* Github Actions to build RPM and DEB packages
