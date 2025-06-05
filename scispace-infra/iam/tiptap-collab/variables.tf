# tiptap-terraform/iam/tiptap-collab/variables.tf

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "tiptap_s3_bucket_name" {
  description = "S3 bucket name for Tiptap."
  type        = string
}

variable "common_tags" { # Renamed from local.tags for clarity as a variable
  description = "Common tags to apply to resources."
  type        = map(string)
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider."
  type        = string
}

variable "tiptap_collab_namespace" {
  description = "Kubernetes namespace for Tiptap Collab."
  type        = string
}

variable "tiptap_collab_service_account_name" {
  description = "Name of the Tiptap Collab service account."
  type        = string
} 