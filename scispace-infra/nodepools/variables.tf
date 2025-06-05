variable "cluster_name" {
  description = "The EKS cluster name."
  type        = string
}

variable "custom_automode_node_role_name" {
  description = "The name of the IAM role for EKS Auto Mode nodes."
  type        = string
}

variable "pod_tiptap_collab_sg_id" {
  description = "The ID of the Tiptap Collab specific security group."
  type        = string
}

variable "app_services_namespace" {
  description = "The Kubernetes namespace for shared application services."
  type        = string
}

variable "env_name" {
  description = "The environment name (e.g., dev, stage, prod)."
  type        = string
} 