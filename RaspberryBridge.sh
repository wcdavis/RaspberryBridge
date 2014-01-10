#!/bin/bash
# Adapted from Breadtk's onion pi setup script: https://github.com/breadtk/onion_pi
# Unfortunately, using Breadtk's script will end up with the user using the Tor network 
# without having to install the Tor Browser, which, as we've discussed, is an ill-conceived
# idea. EPICFAIL, indeed.
# 
# This script will set up the Raspberry Pi to act as a bridge, rather than a Pogoplug-style
# Tor-in-the-middle box. 


if (( $EUID != 0 )); then
  echo "This must be run as root. Type in 'sudo $0' to run it as root."
  exit 1
fi

echo "This script will auto-setup a Tor bridge for you. I suggest you run this on a fresh installation of Raspbian, to eliminate the chance of weird configuration issues."
read -p "Press [Enter] key to begin.."

echo "Updating package index..."
apt-get update -y

echo "Removing the wolfram-engine due to incompatibility with required packages"
apt-get rm wolfram* -y

echo "Updating out-of-date packages..."
apt-get upgrade -y

echo "Downloading and installing various packages..."
apt-get install -y tor chkrootkit unattended-upgrades ntp shred monit

echo "Configuring Tor..."
cat /dev/null > /etc/tor/torrc
/etc/tor/torrc <<'onion_pi_configuration'

SocksPort 0
ORPort 443
BridgeRelay 1
Exitpolicy reject *:*

onion_pi_configuration

echo "Fixing firewall configuration.."
iptables -F
iptables -t nat -F
iptables -t nat -A PREROUTING -i wlan0 -p udp --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A PREROUTING -i wlan0 -p tcp --syn -j REDIRECT --to-ports 9040
sh -c "iptables-save > /etc/iptables.ipv4.nat"

echo "Setting up logging in /var/log/tor/notices.log.."
touch /var/log/tor/notices.log
chown debian-tor /var/log/tor/notices.log
chmod 644 /var/log/tor/notices.log

echo "Setting tor to start at boot.."
update-rc.d tor enable

echo "Starting tor.."
service tor start

echo "Setup complete!
To connect to your own node set your web browser to connect to:
  Proxy type: SOCKSv5
  IP: $(hostname -i | awk '{print $1}')
  Port: 9050

Verify your installation by visiting: https://check.torproject.org/
"

exit
