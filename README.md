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

## Deploy EKS cluster and add-ons

Change terraform template to use your GitHub fork:

```bash
export GITHUB_USERNAME=<your-github-username>
export GITHUB_PASSWORD=<your-github-token>
export AWS_REGION=us-west-2

export TF_PATH_CLUSTER=terraform/clusters/production

sed -e "s|{GITHUB_USERNAME}|$GITHUB_USERNAME|g" "${TF_PATH_CLUSTER}/values.yaml.template" > $TF_PATH_CLUSTER/values.yaml
sed -i '' -e "s|{GITHUB_PASSWORD}|$GITHUB_PASSWORD|g" "${TF_PATH_CLUSTER}/values.yaml"
sed -e "s|{GITHUB_USERNAME}|$GITHUB_USERNAME|g" "${TF_PATH_CLUSTER}/variables.tf.template" > $TF_PATH_CLUSTER/variables.tf
sed -i '' -e "s|{AWS_REGION}|$AWS_REGION|g" "${TF_PATH_CLUSTER}/variables.tf"
```

Apply terraform script:

```bash
cd $TF_PATH_CLUSTER
terraform init
terraform apply --auto-approve

# create kubeconfig file
aws eks update-kubeconfig --region $AWS_REGION --name eks-saas-gitops
```

## Create pool-1 application infrastructure

This infrastructure is needed to support the applications

```bash
export TERRAFORM_STATE_BUCKET=$(terraform output -raw argo_workflows_bucket_name)
echo $TERRAFORM_STATE_BUCKET

cd ../../application-plane/production/environments

sed -e "s|{AWS_REGION}|$AWS_REGION|g" "./providers.tf.template" > providers.tf
sed -i '' -e "s|{TERRAFORM_STATE_BUCKET}|$TERRAFORM_STATE_BUCKET|g" "./providers.tf"
```

Apply terraform script:

```bash
terraform init
terraform apply --auto-approve
```

## Change Templates using Terraform output

```bash
cd ../../../clusters/production

sed -e "s|{TENANT_CHART_HELM_REPO}|$(terraform output -raw ecr_helm_chart_url | sed 's|\(.*\)/.*|\1|')|g" "../../../gitops/infrastructure/base/sources/tenant-chart-helm.yaml.template" > ../../../gitops/infrastructure/base/sources/tenant-chart-helm.yaml

sed -e "s|{KARPENTER_CONTROLLER_IRSA}|$(terraform output -raw karpenter_irsa)|g" "../../../gitops/infrastructure/production/02-karpenter.yaml.template" > ../../../gitops/infrastructure/production/02-karpenter.yaml
sed -i '' -e "s|{EKS_CLUSTER_ENDPOINT}|$(terraform output -raw cluster_endpoint)|g" "../../../gitops/infrastructure/production/02-karpenter.yaml"
sed -i '' -e "s|{KARPENTER_INSTANCE_PROFILE}|$(terraform output -raw karpenter_instance_profile)|g" "../../../gitops/infrastructure/production/02-karpenter.yaml"

sed -e "s|{ARGO_WORKFLOW_IRSA}|$(terraform output -raw argo_workflows_irsa)|g" "../../../gitops/infrastructure/production/03-argo-workflows.yaml.template" > ../../../gitops/infrastructure/production/03-argo-workflows.yaml
sed -i '' -e "s|{ARGO_WORKFLOW_BUCKET}|$(terraform output -raw argo_workflows_bucket_name)|g" "../../../gitops/infrastructure/production/03-argo-workflows.yaml"

sed -e "s|{LB_CONTROLLER_IRSA}|$(terraform output -raw lb_controller_irsa)|g" "../../../gitops/infrastructure/production/04-lb-controller.yaml.template" > ../../../gitops/infrastructure/production/04-lb-controller.yaml

sed -i '' -e "s|{ARGO_WORKFLOW_CONTAINER}|$(terraform output -raw ecr_argoworkflow_container)|g" "../../../tenant-onboarding/tenant-onboarding-workflow-template.yaml"

sed -e "s|{CONSUMER_ECR}|$(terraform output -raw ecr_consumer_container)|g" "../../../tenant-chart/values.yaml.template" > ../../../tenant-chart/values.yaml
sed -i '' -e "s|{PRODUCER_ECR}|$(terraform output -raw ecr_producer_container)|g" "../../../tenant-chart/values.yaml"

```

## Build & Push Helm Chart and Containers to ECR
```bash
HELM_CHART_ECR=$(terraform output -raw ecr_helm_chart_url)
ARGO_WORKFLOW_ECR=$(terraform output -raw ecr_argoworkflow_container)
PRODUCER_ECR=$(terraform output -raw ecr_producer_container)
CONSUMER_ECR=$(terraform output -raw ecr_consumer_container)

cd ../../../

# Build & Push Tenant Helm Chart
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $HELM_CHART_ECR     
helm package tenant-chart
helm push helm-tenant-chart-0.0.1.tgz oci://$(echo $HELM_CHART_ECR | sed 's|\(.*\)/.*|\1|')

# Build & Push Producer Container
aws ecr get-login-password \
     --region $AWS_REGION | finch login \
     --username AWS \
     --password-stdin $PRODUCER_ECR    
finch build --platform linux/amd64 -t $PRODUCER_ECR:0.1 tenants-microsservices/producer
finch push $PRODUCER_ECR:0.1

# Build & Push Consumer Container
aws ecr get-login-password \
     --region $AWS_REGION | finch login \
     --username AWS \
     --password-stdin $CONSUMER_ECR    
finch build --platform linux/amd64 -t $CONSUMER_ECR:0.1 tenants-microsservices/consumer
finch push $CONSUMER_ECR:0.1

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
git add .
git commit -m 'Initial Setup'
git push origin main
```
