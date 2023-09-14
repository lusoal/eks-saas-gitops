# Apply terarform without flux
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
-target=module.ebs_csi_irsa_role --auto-approve

# Configuring Git user for Cloud9
git config --global user.name "Workshop User"
git config --global user.email workshop.user@example.com
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true