#!/bin/sh

export KUBERNETES_VERSION=v1.33
export CRIO_VERSION=v1.34

tar czvf /root/keyrings_backups_$(date +%Y%m%d%H%M%S).tar.gz /etc/apt/keyrings/
rm -f /etc/apt/keyrings/kuberentes-apt-keyring.gpg 2>/dev/null
rm -f /etc/apt/keyrings/cri-o-apt-keyring.gpg 2>/dev/null

curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |
    timeout 5 gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
    timeout 5 gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

apt update -y 2>/dev/null
