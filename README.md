# GitOps SaaS

Sample pattern using GitOps with Flux to manage multiple tenants in a single cluster.

## Pre reqs
- terraform
- kubectl
- Helm
- GitHub token
- Fork this repository

## Install

Change variables in `terraform/clusters/production/values.yaml`:

```yaml
secret:
  data:
    username: "YOUR_USERNAME"
    password: "YOUR_GITHUB_TOKEN"
```

Change the `git_url` in `terraform/clusters/production/variables.tf`

```json
variable "git_url" {
  default = "https://github.com/YOUR_USER/eks-saas-gitops"
}
```

Apply terraform script:

```bash
cd terraform/clusters/production/
terraform init
terraform apply --auto-approve
```

## Change Flux yaml files using Terraform output


## Push Helm Chart to ECR created registry

Login into ECR registry

```bash
aws ecr get-login-password \
     --region YOUR_AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin YOUR_REPO_URL
```

Package helm chart

```bash
```
