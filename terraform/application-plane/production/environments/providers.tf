# DEFINE HERE FIRST TIME WHERE TO DEPLOY

terraform {
  backend "s3" {
    bucket = "saasgitops-argo-07f9fc95-266f-e925-5949-b6039f32a2ca" # Replace during install.sh
    key    = "tenants-infra/tenants-infra.json"
    region = "us-west-2" # Replace during install.sh
  }
}

provider "aws" {
  region = "us-west-2"
}