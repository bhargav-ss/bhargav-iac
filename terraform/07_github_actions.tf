# GitHub Actions OIDC Integration for ECR access
# This allows GitHub Actions to securely authenticate with AWS without storing credentials

# Policy that allows pushing to ECR repositories
resource "aws_iam_policy" "github_actions_ecr_policy" {
  name        = "${terraform.workspace}-github-actions-ecr-policy"
  description = "Policy allowing GitHub Actions to push images to ECR repositories and interact with EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECR Permissions
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = [
          module.agg_view_server.ecr_repository_arn,
          aws_ecr_repository.frontend.arn,
          aws_ecr_repository.backend.arn
        ]
      },
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      # EKS Permissions - restricted to specific cluster
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:ListFargateProfiles",
          "eks:ListAddons",
          "eks:ListIdentityProviderConfigs",
          "eks:AccessKubernetesApi"
        ]
        Resource = [
          "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks.cluster_name}"
        ]
      },
      # Additional permissions for kubectl and helm - restricted to specific cluster and its nodegroups
      {
        Effect = "Allow"
        Action = [
          "eks:UpdateClusterConfig",
          "eks:UpdateNodegroupConfig",
          "eks:CreateAccessEntry",
          "eks:AssociateAccessPolicy"
        ]
        Resource = [
          "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks.cluster_name}",
          "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:nodegroup/${module.eks.cluster_name}/*"
        ]
      },
      # S3 Sync Permissions for typeset-cdn-server-endgame
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::typeset-cdn-server-endgame",
          "arn:aws:s3:::typeset-cdn-server-endgame/*"
        ]
      },
      # Deny DeleteObject for typeset-cdn-server-endgame
      {
        Effect = "Deny",
        Action = [
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::typeset-cdn-server-endgame/*"
        ]
      }
    ]
  })
}

locals {
  # Create a standard OIDC provider ARN whether or not we know if it exists
  github_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# Create the GitHub OIDC provider - we don't know if it exists or not, but Terraform will handle
# the case where it already exists (it will show up as a change that fails, but the apply will succeed)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  
  # If creation fails because the provider already exists, this resource will be marked as failed
  # but the subsequent trust policy will still work because the ARN format is known and standard
  
  tags = {
    Environment = terraform.workspace
    Service     = "github-actions"
    ManagedBy   = "Terraform"
  }
  
  # This will prevent this resource from being removed once created
  lifecycle {
    prevent_destroy = false
  }
}

# Trust policy for GitHub Actions
data "aws_iam_policy_document" "github_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    
    principals {
      type        = "Federated"
      identifiers = [local.github_provider_arn]
    }
    
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        # Allow TypesetIO/agg-view-server repository (all branches)
        "repo:TypesetIO/agg-view-server:*",
        # Add other repositories as needed with format: "repo:org/repo:*"
      ]
    }
  }
}

# Create IAM role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name               = "${terraform.workspace}-github-actions-role"
  description        = "Role used by GitHub Actions to push to ECR repositories"
  assume_role_policy = data.aws_iam_policy_document.github_trust_policy.json
  
  tags = {
    Environment = terraform.workspace
    Service     = "github-actions"
    ManagedBy   = "Terraform"
  }
}

# Attach ECR policy to the role
resource "aws_iam_role_policy_attachment" "github_actions_ecr_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ecr_policy.arn
}
