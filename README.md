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

```hcl
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

- Change ECR Repo based on your account in `/gitops/infrastructure/base/sources/tenant-chart-helm.yaml`
- Change IAM configs in `/gitops/infrastructure/production/02-karpenter.yaml`
- Change IAM configs in `/gitops/infrastructure/production/03-argo-workflows.yaml`
- Change IAM configs in `/gitops/infrastructure/production/04-lb-controller.yaml`


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
helm package tenant-chart
```

Push to ECR

```
helm push helm-tenant-chart-0.1.0.tgz oci://YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/gitops-saas
```