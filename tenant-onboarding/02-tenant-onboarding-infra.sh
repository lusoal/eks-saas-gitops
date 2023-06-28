# Set the desired values for AWS_REGION and TENANT_ID
AWS_REGION="$1"
TENANT_ID="$2"
BUCKET_NAME="$3"

# Define the filename of the Terraform script
TENANT_TF_PATH="/mnt/vol/eks-saas-gitops/terraform/tenant-infra/production"

TERRAFORM_SCRIPT_TEMPLATE="${TENANT_TF_PATH}/main.tpl"
TERRAFORM_SCRIPT="${TENANT_TF_PATH}/tenant-infra-main.tf"

cp "$TERRAFORM_SCRIPT_TEMPLATE" "$TERRAFORM_SCRIPT"

echo "$TERRAFORM_SCRIPT"

# Perform sed replacements
sed -i "s/__AWS_REGION__/$AWS_REGION/g" "$TERRAFORM_SCRIPT"
sed -i "s/__TENANT_ID__/$TENANT_ID/g" "$TERRAFORM_SCRIPT"
sed -i "s/__BUCKET_NAME__/$BUCKET_NAME/g" "$TERRAFORM_SCRIPT"

echo "Replacements completed successfully."
echo "Running Terraform..."

cd "$TENANT_TF_PATH"

terraform init
terraform plan -var="aws_region=${AWS_REGION}" -var="tenant_id=${TENANT_ID}"
terraform apply -var="aws_region=${AWS_REGION}" -var="tenant_id=${TENANT_ID}" -auto-approve
