data "aws_iam_policy_document" "tiptap_s3_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.tiptap_s3_bucket_name}",
      "arn:aws:s3:::${var.tiptap_s3_bucket_name}/tiptap-${var.env_name}/*"
    ]
  }
}

resource "aws_iam_policy" "tiptap_s3_access" {
  name        = "${var.prefix_env}-tiptap-s3-access"
  description = "Allows Tiptap service to access its S3 bucket and folder."
  policy      = data.aws_iam_policy_document.tiptap_s3_access.json
}

# IAM Role for Tiptap Service Account using EKS Pod Identity
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "tiptap_server_pod_identity" {
  name = "${var.prefix_env}-tiptap-server-pod-identity"

  # Trust policy for EKS Pod Identity
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowEksAuthToAssumeRoleForPodIdentity",
        Effect    = "Allow",
        Principal = {
          Service = "pods.eks.amazonaws.com"
        },
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ],
        # Optional: Condition to scope to your specific EKS cluster OIDC provider if needed,
        # though for pods.eks.amazonaws.com service principal, the association itself provides the scoping.
        # Condition = {
        #   StringEquals = {
        #     "pods.eks.amazonaws.com:aud" = "sts.amazonaws.com"
        #   },
        #   StringLike = {
        #     # This condition might need adjustment based on exact EKS Pod Identity requirements
        #     # if you want to further restrict which cluster's pods.eks.amazonaws.com can use this.
        #     # For now, the EKS Pod Identity Association will provide the primary link.
        #     "pods.eks.amazonaws.com:sub" = "system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account_name}"
        #   }
        # }
      }
    ]
  })

  tags = {
    Name        = "${var.prefix_env}-tiptap-server-pod-identity-role"
    Environment = var.prefix_env
    Terraform   = "true"
    Service     = "tiptap"
  }
}

resource "aws_iam_role_policy_attachment" "tiptap_s3_access_attach" {
  role       = aws_iam_role.tiptap_server_pod_identity.name
  policy_arn = aws_iam_policy.tiptap_s3_access.arn
}

# Variable blocks for k8s_namespace and k8s_service_account_name removed from here,
# as they are now proper module inputs defined in variables.tf 