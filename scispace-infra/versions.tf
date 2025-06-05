terraform {
  required_version = ">= 1.0"

  # S3 Backend Configuration for Digger
  # Note: Variables cannot be used in backend config
  # Configure via terraform init with -backend-config or create per-environment configs
  backend "s3" {
    bucket         = "ss-terraform-state-us-west-2"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "ss-terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0" # Align with modern EKS module requirements
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
} 