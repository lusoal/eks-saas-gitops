# DEFINE HERE FIRST TIME WHERE TO DEPLOY

terraform {
  backend "s3" {
    bucket = "saasgitops-terraform-6e79ba11-535f-3117-4561-b396b9a0632f" # Replace during install.sh
    key    = "tenants-infra/tenants-infra.json"
    region = "us-west-2" # Replace during install.sh
  }
}

provider "aws" {
  region = "us-west-2"
}