terraform {
  backend "s3" {
    bucket = "__BUCKET_NAME__" # Replace
    key    = "tenants-infra/__TENANT_ID__"
    region = "__AWS_REGION__"
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_pet" "bucket_name" {
  length = 2
  separator = "-"
}

resource "aws_s3_bucket" "example_bucket" {
  bucket = "${var.tenant_id}-${random_pet.bucket_name.id}"  # Update with your desired bucket name
  acl    = "private"

  tags = {
    Name        = "${var.tenant_id}-${random_pet.bucket_name.id}"
    Environment = "Production"
  }
}