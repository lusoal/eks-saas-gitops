#!/bin/bash

# Check if the tenant_id and model argument is provided 
if [ -z "$1" ]; then
  echo "Please provide the tenant_id as an argument."
  exit 1
fi

# Assign the tenant_id argument to a variable
tenant_id="$1"
tenant_model="$2"
REPOSITORY_URL="git@github.com:lusoal/eks-saas-gitops.git"

git clone $REPOSITORY_URL
cd eks-saas-gitops
git checkout main

TENANT_TEMPLATE_FILE="TENANT_TEMPLATE.yaml"
TENANT_MANIFEST_FILE="${tenant_id}.yaml"

# Create new manifests for the tenant using TENANT_TEMPLATE_FILE, check if tenant_model is pooled or siloed, and update the manifests accordingly
if [ "$tenant_model" == "pooled" ]; then
    cd gitops/pooled-tenants/production/config/
    ls
    cp $TENANT_TEMPLATE_FILE $TENANT_MANIFEST_FILE && sed -i "s/TENANT_ID/${tenant_id}/g" $TENANT_MANIFEST_FILE
    # append a new line in kustomization.yaml file using $TENANT_MANIFEST_FILE
    sed -i '$a\  - '"$TENANT_MANIFEST_FILE" kustomization.yaml
    cd ../../../../

elif [ "$tenant_model" == "siloed" ]; then
    cd gitops/siloed-tenants/production/
    cp $TENANT_TEMPLATE_FILE $TENANT_MANIFEST_FILE && sed -i "s/TENANT_ID/${tenant_id}/g" $TENANT_MANIFEST_FILE
    sed -i '$a\  - '"$TENANT_MANIFEST_FILE" kustomization.yaml
    cd ../../../
fi

git status
# git add .
# git commit -m "Adding tenant $tenant_id"
# git push origin main
cd .. && rm -rf eks-saas-gitops


