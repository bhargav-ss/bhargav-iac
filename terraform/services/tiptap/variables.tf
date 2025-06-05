variable "prefix_env" {
  description = "The prefix for environment-specific resources (e.g., 'sci-dev')."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where ElastiCache will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the ElastiCache subnet group."
  type        = list(string)
}

variable "eks_node_security_group_id" {
  description = "The ID of the EKS node security group to allow Redis access."
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "k8s_namespace" {
  description = "The Kubernetes namespace where the Tiptap service account and resources reside."
  type        = string
  default     = "default"
}

variable "k8s_service_account_name" {
  description = "The name of the Kubernetes service account for Tiptap."
  type        = string
  default     = "tiptap-collab-server-sa"
}

variable "tiptap_s3_bucket_name" {
  description = "The name of the S3 bucket for Tiptap."
  type        = string
}

variable "env_name" {
  description = "The environment name (e.g., dev, stage, prod)."
  type        = string
}

variable "tiptap_database_url" {
  description = "Database URL for Tiptap (Connection Pooler)"
  type        = string
  sensitive   = true
}

variable "tiptap_database_url_direct" {
  description = "Direct Database URL for Tiptap (for migrations, etc.)"
  type        = string
  sensitive   = true
}

variable "tiptap_collab_pod_sg_id" {
  type        = string
  description = "The ID of the security group to be used by Tiptap Collab pods (created in root module)."
} 