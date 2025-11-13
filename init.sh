#!/bin/sh

kubeadm init --control-plane-endpoint "$1":"$2" --upload-certs | tee kubeadm_init.log
