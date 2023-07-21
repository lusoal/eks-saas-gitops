# GitOps SaaS

Sample pattern using GitOps with Flux to manage multiple tenants in a single cluster.

## Pre reqs
- terraform
- kubectl
- Flux CLI
- AWS CLI
- Helm
- GitHub token
- Fork this repository
- finch

## Install

Change terraform template to use your GitHub fork:

```bash
GITHUB_USERNAME=<your-github-username>
GITHUB_PASSWORD=<your-github-token>
AWS_REGION=us-west-2

cd terraform/clusters/production/

sed -e "s|{GITHUB_USERNAME}|$GITHUB_USERNAME|g" "./values.yaml.template" > values.yaml
sed -i '' -e "s|{GITHUB_PASSWORD}|$GITHUB_PASSWORD|g" "./values.yaml"
sed -e "s|{GITHUB_USERNAME}|$GITHUB_USERNAME|g" "./variables.tf.template" > variables.tf
sed -i '' -e "s|{AWS_REGION}|$AWS_REGION|g" "./variables.tf"
```

Apply terraform script:

```bash

terraform init
terraform apply --auto-approve

# create kubeconfig file
aws eks update-kubeconfig --region $AWS_REGION --name eks-saas-gitops
```

## Change Templates using Terraform output
```bash
sed -e "s|{TENANT_CHART_HELM_REPO}|$(terraform output -raw ecr_helm_chart_url | sed 's|\(.*\)/.*|\1|')|g" "../../../gitops/infrastructure/base/sources/tenant-chart-helm.yaml.template" > ../../../gitops/infrastructure/base/sources/tenant-chart-helm.yaml

sed -e "s|{KARPENTER_CONTROLLER_IRSA}|$(terraform output -raw karpenter_irsa)|g" "../../../gitops/infrastructure/production/02-karpenter.yaml.template" > ../../../gitops/infrastructure/production/02-karpenter.yaml
sed -i '' -e "s|{EKS_CLUSTER_ENDPOINT}|$(terraform output -raw cluster_endpoint)|g" "../../../gitops/infrastructure/production/02-karpenter.yaml"
sed -i '' -e "s|{KARPENTER_INSTANCE_PROFILE}|$(terraform output -raw karpenter_instance_profile)|g" "../../../gitops/infrastructure/production/02-karpenter.yaml"

sed -e "s|{ARGO_WORKFLOW_IRSA}|$(terraform output -raw argo_workflows_irsa)|g" "../../../gitops/infrastructure/production/03-argo-workflows.yaml.template" > ../../../gitops/infrastructure/production/03-argo-workflows.yaml
sed -i '' -e "s|{ARGO_WORKFLOW_BUCKET}|$(terraform output -raw argo_workflows_bucket_name)|g" "../../../gitops/infrastructure/production/03-argo-workflows.yaml"

sed -e "s|{LB_CONTROLLER_IRSA}|$(terraform output -raw lb_controller_irsa)|g" "../../../gitops/infrastructure/production/04-lb-controller.yaml.template" > ../../../gitops/infrastructure/production/04-lb-controller.yaml

sed -i '' -e "s|{ARGO_WORKFLOW_CONTAINER}|$(terraform output -raw ecr_argoworkflow_container)|g" "../../../tenant-onboarding/tenant-onboarding-workflow-template.yaml"
```

## Build & Push Helm Chart and Containers to ECR
```bash
HELM_CHART_ECR=$(terraform output -raw ecr_helm_chart_url)
ARGO_WORKFLOW_ECR=$(terraform output -raw ecr_argoworkflow_container)
MICROSERVICE_1_ECR=$(terraform output -raw ecr_microservice_1_container)
MICROSERVICE_2_ECR=$(terraform output -raw ecr_microservice_2_container)

cd ../../../

# Build & Push Tenant Helm Chart
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $HELM_CHART_ECR     
helm package tenant-chart
helm push helm-tenant-chart-0.1.0.tgz oci://$(echo $HELM_CHART_ECR | sed 's|\(.*\)/.*|\1|')

# Build & Push Microservice 1 Container
aws ecr get-login-password \
     --region $AWS_REGION | finch login \
     --username AWS \
     --password-stdin $MICROSERVICE_1_ECR    
finch build --platform linux/amd64 -t $MICROSERVICE_1_ECR tenants-microsservices/microsservice-1
finch push $MICROSERVICE_1_ECR

# Build & Push Microservice 2 Container
aws ecr get-login-password \
     --region $AWS_REGION | finch login \
     --username AWS \
     --password-stdin $MICROSERVICE_2_ECR    
finch build --platform linux/amd64 -t $MICROSERVICE_2_ECR tenants-microsservices/microsservice-2
finch push $MICROSERVICE_2_ECR

# Build & Push ArgoWorkflow Container
aws ecr get-login-password \
     --region $AWS_REGION | finch login \
     --username AWS \
     --password-stdin $ARGO_WORKFLOW_ECR    
finch build --platform linux/amd64 -t $ARGO_WORKFLOW_ECR tenant-onboarding
finch push $ARGO_WORKFLOW_ECR

```

## Add new files to Git and Push
```bash
git add terraform/clusters/production/values.yaml
git add terraform/clusters/production/variables.tf
git add gitops/infrastructure/base/sources/tenant-chart-helm.yaml
git add gitops/infrastructure/production/02-karpenter.yaml
git add gitops/infrastructure/production/03-argo-workflows.yaml
git add gitops/infrastructure/production/04-lb-controller.yaml
git add tenant-onboarding/tenant-onboarding-workflow-template.yaml
git commit -m 'Initial Setup'
git push
```
