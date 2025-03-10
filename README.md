# AWS Client VPN with SAML SSO
## What & why
This project contains scripts and Dockerfile that download, patch and compile with AWS SSO support, and produce Linux packages in RPM and DEB format.

The native AWS Client VPN for Linux only supports _some_ Ubuntu LTS versions on AMD64. You can try to hack around this, but I found it to be brittle. It appears to be a .NET application that required old versions of some dependencies that I had to compile, but it broke unexpectedly after a seemingly unrelated system upgrade. After failing to identify the problem I ended up rolling back my whole system. Nasty.

## Why patch OpenVPN?
OpenVPN doesn't natively support AWS Client VPN with AWS SSO authentication.

## Build & install
1. Run `./build.sh`
2. Install the package (`dpkg -i` or `rpm -i`, and ignore warnings about it being an unsigned package)

## Usage
After installation you'll find an application shortcut called "OpenVPN AWS Client" in your menu. When you launch it, it just creates an item in the system tray. Use right-click to bring up a menu.  Choose a VPN configuration file from the existing AWS Client VPN configuration directory (`~/.config/AWSVPNClient/OpenVpnConfigs/`). This isn't ideal but it works as a straight-forward replacement for the official VPN client. Once you select a configuration, the `start.sh` script will import it, trigger SSO by opening a browser and directing you to your login portal, and will finally start the connection and leave a notification in the system tray. You'll get frequent notifications to remind you that you're connected (since AWS charges you per minute!).

## Current status of the project
Not actively maintained, but it's working for me and a few others who have used it. 
