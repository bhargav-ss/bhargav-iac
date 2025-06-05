output "tiptap_collab_pod_identity_role_arn" {
  description = "ARN of the IAM role for Tiptap Collab pods (EKS Pod Identity)."
  value       = aws_iam_role.tiptap_collab_pod_identity_role.arn
} 