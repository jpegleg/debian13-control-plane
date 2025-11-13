# debian13-control-plane

The file `pre_init.yml` is a playbook to run before using kubeadm to get the packages installed.

The file `post.yml` is a playbook to run after the cluster is formed to further configure it.

The file `reset.yml` is a playbook to run to reset the cluster (destroy the cluster).

Create an EncryptionConfiguration manifest named `files/encryption_config.yml`, example:

```
--
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

This project is just focused on a (3 or 5) node control plane. Worker configurations are not included, but joining them is as usual.
