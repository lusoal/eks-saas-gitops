# DEFINE HERE FIRST TIME WHERE TO DEPLOY

terraform {
  backend "s3" {
    bucket = "terraform-state-tenants-saas-278129817" # Replace during install.sh
    key    = "tenants-infra/tenants-infra.json"
    region = "us-west-2" # Replace during install.sh
  }
}

provider "aws" {
  region = "us-west-2"
}