# Output the VPC ID
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

# Output the EKS cluster details
output "eks_cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster API Endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  description = "EKS Cluster ARN"
  value       = module.eks.cluster_arn
}

# Output the AWS Region
output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "backend_ecr_repository_url" {
  description = "URL of the backend ECR repository"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_ecr_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.repository_url
}

output "agg_view_server_ecr_repository_url" {
  description = "URL of the agg-view-server ECR repository"
  value       = module.agg_view_server.ecr_repository_url
}

output "agg_view_server_ecr_repository_arn" {
  description = "ARN of the agg-view-server ECR repository"
  value       = module.agg_view_server.ecr_repository_arn
}

# GitHub Actions OIDC Integration
output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}
