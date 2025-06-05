# Map the GitHub Actions IAM role to a Kubernetes ClusterRole
# This allows GitHub Actions workflows to interact with the Kubernetes API

resource "kubernetes_cluster_role_binding" "github_actions" {
  metadata {
    name = "github-actions-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin" # For simplicity, using cluster-admin; use more restrictive role in production
  }

  subject {
    kind      = "Group"
    name      = "github-actions"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [module.eks]
}

# Grant access to the GitHub Actions role using EKS Access Entries
# This is the modern recommended way to control access to EKS clusters

# Create an EKS access entry for the GitHub Actions role
resource "aws_eks_access_entry" "github_actions" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = aws_iam_role.github_actions.arn
  
  depends_on = [module.eks]
}

# Associate admin policy to the GitHub Actions role
resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.github_actions.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
  
  depends_on = [aws_eks_access_entry.github_actions]
}
