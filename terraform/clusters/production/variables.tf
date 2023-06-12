variable "name" {
  default = "eks-saas-gitops"
}

variable "aws_region" {
  default = "us-west-2"
} 

variable "vpc_cidr" {
  default = "10.35.0.0/16"
}

variable "cluster_version" {
  default = "1.24"
}

variable "git_branch" {
  default = "main"
}

# variable "git_password" {}

# variable "git_username" {}

# variable "git_url" {}

var "kustomization_path" {
  default = "gitops/clusters/production"
}