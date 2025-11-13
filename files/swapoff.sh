#!/bin/sh

cat <<EOF |  tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF |  tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl -p
sysctl -f /etc/sysctl.d/k8s.conf
swapoff -a

checked="$(crontab -l | grep -o swapoff)"

if [ "$checked != "swapoff" ]; then
  (crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab -
fi
