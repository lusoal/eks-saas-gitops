# DEFINE HERE FIRST TIME WHERE TO DEPLOY

terraform {
  backend "s3" {
    bucket = "terraform-state-tenants-saas-278129817" # Replace
    key    = "tenants-infra/tenants-infra.json"
    region = "us-west-2"
  }
}

provider "aws" {
  region = "us-west-2"
}