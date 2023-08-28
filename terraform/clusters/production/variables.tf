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
  default = "demo-branch"
}

variable "git_url" {
  default = "https://github.com/lusoal/eks-saas-gitops"
}

variable "kustomization_path" {
  default = "gitops/clusters/production"
}

variable "values_path" {
  default = "./values.yaml"
}

variable "tenant_helm_chart_repo" {
  default = "gitops-saas/helm-tenant-chart"
}

variable "argoworkflow_container_repo" {
  default = "argoworkflow-container"
}

variable "producer_container_repo" {
  default = "producer-container"
}

variable "consumer_container_repo" {
  default = "consumer-container"
}
