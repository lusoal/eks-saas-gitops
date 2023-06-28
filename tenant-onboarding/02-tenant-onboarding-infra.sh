#!/bin/bash

# Set the desired values for AWS_REGION and TENANT_ID
AWS_REGION="$1"
TENANT_ID="$2"

# Define the filename of the Terraform script
TERRAFORM_SCRIPT="saas-gitops-eks/terraform/tenant-infra/production/main.tf"

# Perform sed replacements
sed -i '' "s/AWS_REGION/$AWS_REGION/g" $TERRAFORM_SCRIPT
sed -i '' "s/TENANT_ID/$TENANT_ID/g" $TERRAFORM_SCRIPT

echo "Replacements completed successfully."
