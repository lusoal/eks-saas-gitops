#!/bin/bash

# Apply terarform without flux
cd /home/ec2-user/environment/eks-saas-gitops/terraform/clusters/production

terraform init

terraform apply -var "aws_region=${AWS_REGION}" \
-target=module.vpc \
-target=module.eks \
-target=aws_iam_role.karpenter_node_role \
-target=aws_iam_policy_attachment.container_registry_policy \
-target=aws_iam_policy_attachment.amazon_eks_worker_node_policy \
-target=aws_iam_policy_attachment.amazon_eks_cni_policy \
-target=aws_iam_policy_attachment.amazon_eks_ssm_policy \
-target=aws_iam_instance_profile.karpenter_instance_profile \
-target=module.karpenter_irsa_role \
-target=aws_iam_policy.karpenter-policy \
-target=aws_iam_policy_attachment.karpenter_policy_attach \
-target=module.argo_workflows_eks_role \
-target=random_uuid.uuid \
-target=aws_s3_bucket.argo-artifacts \
-target=module.lb-controller-irsa \
-target=aws_ecr_repository.tenant_helm_chart \
-target=aws_ecr_repository.argoworkflow_container \
-target=aws_ecr_repository.consumer_container \
-target=aws_ecr_repository.producer_container \
-target=module.codecommit-flux \
-target=aws_iam_user.codecommit-user \
-target=aws_iam_user_policy_attachment.codecommit-user-attach \
-target=module.ebs_csi_irsa_role \
-target=aws_s3_bucket.tenant-terraform-state-bucket --auto-approve

# Exporting terraform outputs to bashrc
outputs=("argo_workflows_bucket_name" 
         "argo_workflows_irsa" 
         "aws_codecommit_clone_url_http" 
         "aws_codecommit_clone_url_ssh" 
         "aws_vpc_id" 
         "cluster_endpoint" 
         "cluster_iam_role_name" 
         "cluster_primary_security_group_id" 
         "ecr_argoworkflow_container" 
         "ecr_consumer_container" 
         "ecr_helm_chart_url" 
         "ecr_producer_container" 
         "karpenter_instance_profile" 
         "karpenter_irsa" 
         "lb_controller_irsa"
         "tenant_terraform_state_bucket_name")

for output in "${outputs[@]}"; do
    value=$(terraform output -raw $output)
    echo "export ${output^^}=$value" >> /home/ec2-user/.bashrc
done

source /home/ec2-user/.bashrc

# Configuring Git user for Cloud9
git config --global user.name "Workshop User"
git config --global user.email workshop.user@example.com
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

# Cloning code commit repository and copying files to the git repository
cd /home/ec2-user/environment
git clone $AWS_CODECOMMIT_CLONE_URL_HTTP
cp -r /home/ec2-user/environment/eks-saas-gitops/* /home/ec2-user/environment/eks-saas-gitops-aws
cp /home/ec2-user/environment/eks-saas-gitops/.gitignore /home/ec2-user/environment/eks-saas-gitops-aws/.gitignore
rm -rf /home/ec2-user/environment/eks-saas-gitops

# Creating pool-1 application infra
export APPLICATION_PLANE_INFRA_FOLDER="/home/ec2-user/environment/eks-saas-gitops-aws/terraform/application-plane/production/environments"

sed -e "s|{AWS_REGION}|${AWS_REGION}|g" "${APPLICATION_PLANE_INFRA_FOLDER}/providers.tf.template" > ${APPLICATION_PLANE_INFRA_FOLDER}/providers.tf
sed -i "s|{TERRAFORM_STATE_BUCKET}|${TENANT_TERRAFORM_STATE_BUCKET_NAME}|g" "${APPLICATION_PLANE_INFRA_FOLDER}/providers.tf"

cd $APPLICATION_PLANE_INFRA_FOLDER && terraform init && terraform apply -auto-approve

# Changing template files to use the new values
export GITOPS_FOLDER="/home/ec2-user/environment/eks-saas-gitops-aws/gitops"
export ONBOARDING_FOLER="/home/ec2-user/environment/eks-saas-gitops-aws/tenant-onboarding"
export TENANT_CHART_FOLER="/home/ec2-user/environment/eks-saas-gitops-aws/tenant-chart"

sed -e "s|{TENANT_CHART_HELM_REPO}|$(echo ${ECR_HELM_CHART_URL} | sed 's|\(.*\)/.*|\1|')|g" "${GITOPS_FOLDER}/infrastructure/base/sources/tenant-chart-helm.yaml.template" > ${GITOPS_FOLDER}/infrastructure/base/sources/tenant-chart-helm.yaml
sed -e "s|{KARPENTER_CONTROLLER_IRSA}|${KARPENTER_IRSA}|g" "${GITOPS_FOLDER}/infrastructure/production/02-karpenter.yaml.template" > ${GITOPS_FOLDER}/infrastructure/production/02-karpenter.yaml
sed -i "s|{EKS_CLUSTER_ENDPOINT}|${CLUSTER_ENDPOINT}|g" "${GITOPS_FOLDER}/infrastructure/production/02-karpenter.yaml"
sed -i "s|{KARPENTER_INSTANCE_PROFILE}|${KARPENTER_INSTANCE_PROFILE}|g" "${GITOPS_FOLDER}/infrastructure/production/02-karpenter.yaml"
sed -e "s|{ARGO_WORKFLOW_IRSA}|${ARGO_WORKFLOWS_IRSA}|g" "${GITOPS_FOLDER}/infrastructure/production/03-argo-workflows.yaml.template" > "${GITOPS_FOLDER}/infrastructure/production/03-argo-workflows.yaml"
sed -i "s|{ARGO_WORKFLOW_BUCKET}|${ARGO_WORKFLOWS_BUCKET_NAME}|g" "${GITOPS_FOLDER}/infrastructure/production/03-argo-workflows.yaml"
sed -e "s|{LB_CONTROLLER_IRSA}|${LB_CONTROLLER_IRSA}|g" "${GITOPS_FOLDER}/infrastructure/production/04-lb-controller.yaml.template" > ${GITOPS_FOLDER}/infrastructure/production/04-lb-controller.yaml

sed -i "s|{ARGO_WORKFLOW_CONTAINER}|${ECR_ARGOWORKFLOW_CONTAINER}|g" "${ONBOARDING_FOLER}/tenant-onboarding-workflow-template.yaml"

sed -e "s|{CONSUMER_ECR}|${ECR_CONSUMER_CONTAINER}|g" "${TENANT_CHART_FOLER}/values.yaml.template" > ${TENANT_CHART_FOLER}/values.yaml
sed -i "s|{PRODUCER_ECR}|${ECR_PRODUCER_CONTAINER}|g" "${TENANT_CHART_FOLER}/values.yaml"

# Building containers and push to ECR
cd /home/ec2-user/environment/eks-saas-gitops-aws

# Build & Push Tenant Helm Chart
aws ecr get-login-password \
     --region $AWS_REGION | helm registry login \
     --username AWS \
     --password-stdin $ECR_HELM_CHART_URL
helm package tenant-chart
helm push helm-tenant-chart-0.0.1.tgz oci://$(echo $ECR_HELM_CHART_URL | sed 's|\(.*\)/.*|\1|')

aws ecr get-login-password \
     --region $AWS_REGION | docker login \
     --username AWS \
     --password-stdin $ECR_PRODUCER_CONTAINER
docker build -t $ECR_PRODUCER_CONTAINER:0.1 tenants-microsservices/producer
docker push $ECR_PRODUCER_CONTAINER:0.1

aws ecr get-login-password \
     --region $AWS_REGION | docker login \
     --username AWS \
     --password-stdin $ECR_CONSUMER_CONTAINER
docker build -t $ECR_CONSUMER_CONTAINER:0.1 tenants-microsservices/consumer
docker push $ECR_CONSUMER_CONTAINER:0.1

aws ecr get-login-password \
     --region $AWS_REGION | docker login \
     --username AWS \
     --password-stdin $ECR_ARGOWORKFLOW_CONTAINER
docker build -t $ECR_ARGOWORKFLOW_CONTAINER tenant-onboarding
docker push $ECR_ARGOWORKFLOW_CONTAINER

git checkout -b main
git add .
git commit -m 'Initial Setup'
git push origin main

chown -R ec2-user:ec2-user /home/ec2-user/environment/eks-saas-gitops-aws