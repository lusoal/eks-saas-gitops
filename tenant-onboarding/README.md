# TODO List

- Create secret to be able to clone and push to the GitHub Repository

```bash
kubectl create secret generic github-ssh-key --from-file=ssh-privatekey=/Users/lucasdu/.ssh/id_rsa_git --from-literal=ssh-privatekey.mode=0600 -nargo-workflows
```