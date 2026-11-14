variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-north-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "journal-capstone"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}