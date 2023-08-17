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

Change terraform cluster template to use your GitHub fork:

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
```

Update Kubeconfig

```bash
# create kubeconfig file
aws eks update-kubeconfig --region $AWS_REGION --name eks-saas-gitops
```

## Create pool-1 application infrastructure

Change terraform pool-1 infrastructure template to use your GitHub fork:

```bash
export TERRAFORM_STATE_BUCKET=$(terraform output -raw tenant_terraform_state_bucket_name)
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

In this step we will change values needed by our add-ons in order to work with our new EKS cluster.

```bash
cd ../../../clusters/production

# Change Flux HelmRepository to use private chart
sed -e "s|{TENANT_CHART_HELM_REPO}|$(terraform output -raw ecr_helm_chart_url | sed 's|\(.*\)/.*|\1|')|g" "../../../gitops/infrastructure/base/sources/tenant-chart-helm.yaml.template" > ../../../gitops/infrastructure/base/sources/tenant-chart-helm.yaml

# Change Karpenter values.yaml file to cluster specifics
sed -e "s|{KARPENTER_CONTROLLER_IRSA}|$(terraform output -raw karpenter_irsa)|g" "../../../gitops/infrastructure/production/02-karpenter.yaml.template" > ../../../gitops/infrastructure/production/02-karpenter.yaml
sed -i '' -e "s|{EKS_CLUSTER_ENDPOINT}|$(terraform output -raw cluster_endpoint)|g" "../../../gitops/infrastructure/production/02-karpenter.yaml"
sed -i '' -e "s|{KARPENTER_INSTANCE_PROFILE}|$(terraform output -raw karpenter_instance_profile)|g" "../../../gitops/infrastructure/production/02-karpenter.yaml"

# Change argo-workflows values.yaml file to environment specifics (IRSA and S3)
sed -e "s|{ARGO_WORKFLOW_IRSA}|$(terraform output -raw argo_workflows_irsa)|g" "../../../gitops/infrastructure/production/03-argo-workflows.yaml.template" > ../../../gitops/infrastructure/production/03-argo-workflows.yaml
sed -i '' -e "s|{ARGO_WORKFLOW_BUCKET}|$(terraform output -raw argo_workflows_bucket_name)|g" "../../../gitops/infrastructure/production/03-argo-workflows.yaml"

# Change LB controller values.yaml file to use created IRSA
sed -e "s|{LB_CONTROLLER_IRSA}|$(terraform output -raw lb_controller_irsa)|g" "../../../gitops/infrastructure/production/04-lb-controller.yaml.template" > ../../../gitops/infrastructure/production/04-lb-controller.yaml

# Change Argo Workflow CRD to use container in private registry
sed -i '' -e "s|{ARGO_WORKFLOW_CONTAINER}|$(terraform output -raw ecr_argoworkflow_container)|g" "../../../tenant-onboarding/tenant-onboarding-workflow-template.yaml"

# Change microsservices image on tenant-chart default values.yaml
sed -e "s|{CONSUMER_ECR}|$(terraform output -raw ecr_consumer_container)|g" "../../../tenant-chart/values.yaml.template" > ../../../tenant-chart/values.yaml
sed -i '' -e "s|{PRODUCER_ECR}|$(terraform output -raw ecr_producer_container)|g" "../../../tenant-chart/values.yaml"
```

## Build & Push Helm Chart and Containers to ECR
```bash
export HELM_CHART_ECR=$(terraform output -raw ecr_helm_chart_url)
export ARGO_WORKFLOW_ECR=$(terraform output -raw ecr_argoworkflow_container)
export PRODUCER_ECR=$(terraform output -raw ecr_producer_container)
export CONSUMER_ECR=$(terraform output -raw ecr_consumer_container)

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

# Create new Tenant using Argo-Workflows

The first thing we need to do is create a secret to be able to clone and push our GitHub Repository (The public key needs to be already added with the right permissions in your repository).

```bash
kubectl create secret generic github-ssh-key --from-file=ssh-privatekey=PATH_TO_PRIVATE_KEY --from-literal=ssh-privatekey.mode=0600 -nargo-workflows
```

> If you don't know how to generate a private key, you can find it [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

## Creating Workflow Temaplate

In Argo Workflows we can create `Workflows Templates` and reuse it, let's create our workflow template who will be responsible to provision tenants in our environment:

```bash
kubectl apply -f tenant-onboarding/tenant-onboarding-workflow-template.yaml
```

Replacing variables in `workflow-call-workflow-template.yaml`

```bash
export GIT_USER_EMAIL=<your_github_email>

sed -i '' -e "s|{GITHUB_USERNAME}|$GITHUB_USERNAME|g" "tenant-onboarding/workflow-call-workflow-template.yaml"
sed -i '' -e "s|{GIT_USER_EMAIL}|$GIT_USER_EMAIL|g" "tenant-onboarding/workflow-call-workflow-template.yaml"
```

Now that you replace specific variables, let's create the tenant, first you will need to define your `TENANT_ID` and `TENANT MODEL` in `workflow-call-workflow-template.yaml` file:

```yaml
- name: TENANT_ID
  value: "tenant-2" # ID of your tenant, use this patter eg. tenant-xx (tenant-10, tenant-11)
- name: TENANT_MODEL
  value: "siloed" # Valid values are: siloed, pooled, hybrid
```

In the example above we will create a tenant using the `siloed` model, valid values are `siloed`, `hybrid` and `pooled`. Let's apply the manifest.

```bash
kubectl create -f tenant-onboarding/workflow-call-workflow-template.yaml
```

Visualizing in Argo Workflows, let's open Argo Workflows and see our pipeline running:

```bash
ARGO_WORKFLOWS_URL=$(kubectl get svc -nargo-workflows | grep -i elb | awk '{print $4}'):2746
echo ARGO_WORKFLOWS_URL
```
