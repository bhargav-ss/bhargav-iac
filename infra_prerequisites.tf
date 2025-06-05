# Consolidated Infrastructure Prerequisites for Digger

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"  # Match your project region
}

data "aws_caller_identity" "current" {}

# dummy change

locals {
  # Standard OIDC provider ARN for GitHub Actions
  github_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
  digger_role_name         = "DiggerGithubActionsRole" # Consistent role name for Digger
  digger_policy_name       = "DiggerExecutionPolicy"
  # IMPORTANT: Replace with your GitHub organization and repository
  github_repository_path   = "bhargav-ss/bhargav-iac"
}

# --- Backend Infrastructure (from backend-setup.tf) ---

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "ss-terraform-state-us-west-2"
  
  tags = {
    Name                = "Terraform State Store"
    TerraformManaged   = "true"
    Purpose            = "Backend for Digger"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "ss-terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name             = "Terraform State Locks"
    TerraformManaged = "true"
    Purpose          = "State locking for Digger"
  }
}

# --- OIDC and IAM Role for Digger (from oidc-digger-setup.tf) ---

# 1. IAM OpenID Connect (OIDC) Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github_actions_oidc_provider" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # Standard thumbprint for GitHub OIDC

  tags = {
    Name      = "GitHubActionsOIDCProvider"
    ManagedBy = "Terraform"
    Purpose   = "Allow GitHub Actions to assume IAM roles"
  }
}

# 2. IAM Policy Document for the Digger Role's Trust Relationship
data "aws_iam_policy_document" "digger_github_actions_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions_oidc_provider.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.github_repository_path}:*",
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# 3. IAM Role for Digger to be assumed by GitHub Actions
resource "aws_iam_role" "digger_github_actions_role" {
  name               = local.digger_role_name
  assume_role_policy = data.aws_iam_policy_document.digger_github_actions_trust_policy.json
  description        = "IAM Role to be assumed by Digger via GitHub Actions for Terraform operations"

  tags = {
    Name      = local.digger_role_name
    ManagedBy = "Terraform"
    Purpose   = "Digger Terraform Orchestration"
  }
}

# 4. IAM Policy for Digger Execution (Broad Permissions - Refine Later)
resource "aws_iam_policy" "digger_execution_policy" {
  name        = local.digger_policy_name
  description = "Broad permissions for Digger. IMPORTANT: Refine these to least privilege."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "*",
        Resource = "*"
      }
    ]
  })

  tags = {
    Name      = local.digger_policy_name
    ManagedBy = "Terraform"
    Purpose   = "Digger Terraform Orchestration"
  }
}

# 5. Attach the Digger Execution Policy to the Digger Role
resource "aws_iam_role_policy_attachment" "digger_role_attaches_execution_policy" {
  role       = aws_iam_role.digger_github_actions_role.name
  policy_arn = aws_iam_policy.digger_execution_policy.arn
}

# --- Outputs ---

# Output the backend configuration
output "backend_config" {
  description = "Configuration details for the S3 backend (bucket, region, DynamoDB table)."
  value = {
    bucket         = aws_s3_bucket.terraform_state.bucket
    region         = aws_s3_bucket.terraform_state.region
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
  }
}

# Output the ARN of the Digger IAM Role
output "digger_github_actions_role_arn" {
  description = "The ARN of the IAM role for Digger GitHub Actions. Use this in GitHub Secrets (AWS_ROLE_ARN)."
  value       = aws_iam_role.digger_github_actions_role.arn
} 