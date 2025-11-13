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
