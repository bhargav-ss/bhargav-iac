variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-west-2" # Aligning with Tiptap ECR image region
}

variable "cluster_name" {
  description = "Name for the EKS cluster and prefix for many resources."
  type        = string
  default     = "scispace-infra-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.33"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "172.16.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
  default     = ["172.16.1.0/24", "172.16.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
  default     = ["172.16.101.0/24", "172.16.102.0/24"]
}

# Tiptap Collab Service specific variables
variable "tiptap_collab_image" {
  description = "Docker image for the Tiptap Collab service."
  type        = string
  default     = "249531194221.dkr.ecr.us-west-2.amazonaws.com/bhargav/tiptap:1.0.0"
}

variable "app_services_namespace" {
  description = "Kubernetes namespace for shared application services."
  type        = string
  default     = "app-services"
}

variable "env_name" {
  description = "Environment name (e.g., dev, stage, prod), used for AWS_FOLDER_NAME."
  type        = string
  default     = "prod" # Matching example from values.yaml AWS_FOLDER_NAME
}

variable "tiptap_s3_bucket_name" {
  description = "S3 bucket name for Tiptap (AWS_BUCKET_NAME)."
  type        = string
  default     = "bhargav-tiptap-poc" # From values.yaml
}

variable "tiptap_aws_folder_name" {
  description = "AWS folder name within the S3 bucket."
  type        = string
  default     = "tiptap-prod" # Default from values.yaml, can also be dynamic e.g., "tiptap-${var.env_name}"
}

variable "tiptap_database_url" {
  description = "Database URL for Tiptap (DATABASE_URL)."
  type        = string
  sensitive   = true
  default     = "postgres://scispace_root:5b2uhtv5aK8z@scispace.c0fwkhspicdq.us-west-2.rds.amazonaws.com:5432/tiptap" # From values.yaml
}

variable "tiptap_database_url_direct" {
  description = "Direct Database URL for Tiptap (DATABASE_URL_DIRECT)."
  type        = string
  sensitive   = true
  default     = "postgres://scispace_root:5b2uhtv5aK8z@scispace.c0fwkhspicdq.us-west-2.rds.amazonaws.com:5432/tiptap" # From values.yaml
}

variable "tiptap_port_api" {
  description = "API port for Tiptap (PORT_API)."
  type        = string
  default     = "8081"
}

variable "tiptap_aws_use_s3" {
  description = "Enable S3 usage for Tiptap (AWS_USE_S3)."
  type        = string
  default     = "1"
}

variable "tiptap_aws_force_path_style" {
  description = "Force path style S3 access (AWS_FORCE_PATH_STYLE)."
  type        = string
  default     = "1"
}

variable "tiptap_collab_clustermode" {
  description = "Collaboration cluster mode (COLLAB_CLUSTERMODE)."
  type        = string
  default     = "1"
}

variable "tiptap_redis_url" {
  description = "Redis URL for Tiptap (REDIS_URL)."
  type        = string
  default     = "redis://v4-bhargav-tiptap.y4dwpy.ng.0001.usw2.cache.amazonaws.com"
}

variable "tiptap_license_key" {
  description = "License key for Tiptap (LICENSE_KEY)."
  type        = string
  sensitive   = true
  # Default value should be sourced from a secure location, not hardcoded here for real use.
  # For this exercise, I'm omitting the default from values.yaml to avoid storing it directly.
  # It should be provided during terraform apply or via a tfvars file.
  default = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2Nsb3VkLnRpcHRhcC5kZXYiLCJpYXQiOjE3NDczMzc3MzMuOTgxOTIxLCJhdWQiOiJ4OWxkMGxsayJ9.QwRvQ21KPv8vEpFV991AUbAylVG0VWCY5wGbQOVZnms" # From values.yaml
}

variable "tiptap_jwt_secret" {
  description = "JWT secret for Tiptap (JWT_SECRET)."
  type        = string
  sensitive   = true
  default     = "76365bb4a90259da5be2ccdaf9f5e09b3b8c6b9562ff837f2468424be0565258745fb7b89e4c40df3b423703cda328dbea4364c655e9d4bf3fb9b9f395e060b7a99bfb134aaf6a8bddb5bac5a01691ce370ec5fc26c7170766c55dbb64b558174e02760a36d0a4dee4bd8d1a8a1623f975c1abcbc48f1d0d0f69dd79f8bda8b785292bf40ab62bd34a65ac2348531ed778173804703105157932362bcc11dafd096009fc7eaee79aa7d5bfba3a3c8581709889d3c3b9e6b867d24c2f145700891f75da3bbe2945065d0a676dac1bb77b7b6d6264a6188b8f13fbf88b53a840d66ed20d943d69409fe339b91a03962952a05bac9d4e17124a1fdac9c5867f13a0" # From values.yaml
}

variable "tiptap_api_secret" {
  description = "API secret for Tiptap (API_SECRET)."
  type        = string
  sensitive   = true
  default     = "huhuhaha" # From values.yaml
}

variable "tiptap_collab_replicas" {
  description = "Number of replicas for the Tiptap Collab deployment."
  type        = number
  default     = 1
}

variable "caddy_internal_http_port" {
  description = "Internal HTTP port Caddy will listen on inside its container."
  type        = number
  default     = 8080
}

variable "target_vpc_id" {
  description = "The ID of the target VPC for peering with the RDS VPC."
  type        = string
}

variable "enable_vpc_peering" {
  description = "Set to true to enable VPC peering. Disabled by default."
  type        = bool
  default     = false
} 