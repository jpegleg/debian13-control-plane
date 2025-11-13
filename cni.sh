#!/bin/sh
# install Calico CNI plugin CRDs, cli tool, and apply network global settings - adjust versions as needed

hascrd=$(ls operator-crds.yaml)

if [ "$hascal" != "perator-crds.yaml" ]; then
  curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.31.0/manifests/operator-crds.yaml
fi

kubectl apply -f operator-crds.yaml | tee operator_crds.log

hasbpf=$(ls custom-resources-bpfyaml)

if [ "$hasbpf" != "custom-resources-bpf.yaml" ]; then
  curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.31.0/manifests/custom-resources-bpf.yaml
fi

kubectl apply -f custom-resources-bpf.yaml | tee bpf_crds.log

hascal=$(ls calicoctl 2>/dev/null)

if [ "$hascal" != "calicoctl" ]; then
  curl -L https://github.com/projectcalico/calico/releases/download/v3.31.0/calicoctl-linux-amd64 -o calicoctl
  chmod +x ./calicoctl
fi

./calicoctl apply -f files/global_network_config.yml | tee global_network.log

cat << EOF | ./calicoctl apply -f -
---
apiVersion: projectcalico.org/v3
kind: FelixConfiguration
metadata:
  name: default
spec:
  bpfEnabled: true
  bpfDisableUnprivileged: true
  bpfKubeProxyIptablesCleanupEnabled: true
  wireguardEnabled: true
  bpfExternalServiceMode: DSR
...
EOF
