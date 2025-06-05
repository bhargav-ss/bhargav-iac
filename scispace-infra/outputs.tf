output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_provider_arn" {
  description = "EKS Cluster OIDC Provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "configure_kubectl" {
  description = "Command to configure kubectl for this EKS cluster."
  value       = "aws eks --region ${local.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "custom_automode_node_role_arn" {
  description = "ARN of the IAM role for custom AutoMode nodes."
  value       = aws_iam_role.custom_automode_node_role.arn
}

output "pod_tiptap_collab_sg_id" {
  description = "ID of the Security Group created for the Tiptap Collab pods."
  value       = aws_security_group.pod_tiptap_collab_sg.id
} 