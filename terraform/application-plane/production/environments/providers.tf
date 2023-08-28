# DEFINE HERE FIRST TIME WHERE TO DEPLOY

terraform {
  backend "s3" {
    bucket = "saasgitops-terraform-b9251378-4038-b8ae-dda7-beb13114b204" # Replace during install.sh
    key    = "tenants-infra/tenants-infra.json"
    region = "us-west-2" # Replace during install.sh
  }
}

provider "aws" {
  region = "us-west-2"
}