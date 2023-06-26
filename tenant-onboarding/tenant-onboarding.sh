#!/bin/bash

# This script is used to add a new tenant to the gitops repository, needs to have git permission configured

# Check if the tenant_id and model argument is provided
if [ -z "$1" ]; then
  echo "Please provide the tenant_id as the first argument."
  exit 1
fi

# Assign the tenant_id and tenant_model arguments to variables
tenant_id="$1"
tenant_model="$2"
REPOSITORY_URL="$3"

git clone "$REPOSITORY_URL"
cd eks-saas-gitops
git checkout main

TENANT_TEMPLATE_FILE="TENANT_TEMPLATE.yaml"
TENANT_MANIFEST_FILE="${tenant_id}.yaml"

# Create new manifests for the tenant using TENANT_TEMPLATE_FILE, check if tenant_model is pooled or siloed, and update the manifests accordingly
if [ "$tenant_model" == "pooled" ]; then
    cd gitops/pooled-tenants/production/config/ || exit 1
    ls
    cp "$TENANT_TEMPLATE_FILE" "$TENANT_MANIFEST_FILE" && sed -i '' "s/TENANT_ID/${tenant_id}/g" "$TENANT_MANIFEST_FILE"
    # append a new line in kustomization.yaml file using $TENANT_MANIFEST_FILE
    printf "\n  - ${TENANT_MANIFEST_FILE}\n" >> kustomization.yaml
    cd ../../../../

elif [ "$tenant_model" == "siloed" ]; then
    cd gitops/siloed-tenants/production/ || exit 1
    cp "$TENANT_TEMPLATE_FILE" "$TENANT_MANIFEST_FILE" && sed -i '' "s/TENANT_ID/${tenant_id}/g" "$TENANT_MANIFEST_FILE"
    printf "\n  - ${TENANT_MANIFEST_FILE}\n" >> kustomization.yaml
    cd ../../../
fi

git status
git add .
git commit -m "Adding new tenant $tenant_id in model $tenant_model"
git push origin main
cd .. && rm -rf eks-saas-gitops
