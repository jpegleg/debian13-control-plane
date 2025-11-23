# debian13-control-plane

The file `pre_init.yml` is a playbook to run before using kubeadm to get the packages installed.

The file `post.yml` is a playbook to run after the cluster is formed to further configure it.

The file `reset.yml` is a playbook to run to reset the cluster (destroy the cluster).

Create an EncryptionConfiguration manifest named `files/encryption_config.yml`. 

An example is to generate a key with `head -c 32 /dev/urandom | base64` and have a simple AES encryption config like this, replacing PUTYOURENCODEDKEYHERE with the generated key:

```
---
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
    - secrets
    - configmaps
  providers:
    - aescbc:
        keys:
          - name: key1
            secret: PUTYOURENCODEDKEYHERE
    - identity: {}

```
The encryption config can be upgraded to whatever, the `encryption.pl` script applies the change carefully and creates a backup.
The script can be deployed along with any updates to the security configuration can be sent with the `post.yml` playbook.

An example inventory:

```
[control]
10.0.2.11
10.0.2.13
10.0.2.14
```

This project is just focused on a (3 or 5) node control plane, but can be used with a single node control plane, too. Worker configurations are not included, but joining them is as usual.

Check to make sure the encryption is working with etcdctl.

```
kubectl create secret generic secrettest -n default --from-literal=mykey=testing

ETCDCTL_API=3 etcdctl \
   --cacert=/etc/kubernetes/pki/etcd/ca.crt   \
   --cert=/etc/kubernetes/pki/etcd/server.crt \
   --key=/etc/kubernetes/pki/etcd/server.key  \
   get /registry/secrets/default/secrettest | hexdump -C

```

If the data is still readable, then validate the configurations and then the last two tasks in `post.yml` can be rerun to restart the apiserver and replace the secrets again.

```
ansible-playbook -u root -i hosts.ini post.yml -t apiserver,replace
```

If we the apiserver is refusing to pick up the encryption config, it may be because kubelet isn't configured to use the standard manifest path. 

Debugging with `crictl` might help.

```
crictl ps
crictl logs $CONTAINERID
```

Note that kubelet reads all files in /etc/kubernetes/manifests regardless of the extension, so extra files can cause issues. Some clusters or configurations will have other needs not accounted for with the technique used here, which can cause services to fail. 

If you need to recover from the apiserver crashing, use kubeadm to reconstrct the apiserver config and restart it:

```
kubeadm init phase control-plane apiserver
```

Applying the change early in the life of the cluster, such as before any worker nodes are joined, is safer than applying the change in a busy cluster with many components already using the apiserver.Update README.md
