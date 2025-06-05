# tiptap_s3_access_iam.tf

# IAM Policy for Tiptap Collab S3 Bucket Access
resource "aws_iam_policy" "tiptap_collab_s3_access" {
  name        = "${var.cluster_name}-TiptapCollabS3AccessPolicy"
  description = "Allows Tiptap Collab pods to access the S3 bucket ${var.tiptap_s3_bucket_name}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket"
        ],
        Resource = ["arn:aws:s3:::${var.tiptap_s3_bucket_name}"]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl" # Often needed if objects need specific ACLs, can be optional
        ],
        Resource = ["arn:aws:s3:::${var.tiptap_s3_bucket_name}/*"] # Access to objects within the bucket
      }
    ]
  })

  tags = var.common_tags
}

# Trust policy for IRSA (IAM Roles for Service Accounts)
data "aws_iam_policy_document" "tiptap_collab_pod_identity_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.eks_oidc_provider_arn]
    }

    # Condition to scope the trust to the specific service account
    condition {
      test     = "StringEquals"
      variable = "${replace(var.eks_oidc_provider_arn, "/^.*oidc-provider\\/(.*)$/", "$1")}:sub"
      values   = ["system:serviceaccount:${var.tiptap_collab_namespace}:${var.tiptap_collab_service_account_name}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.eks_oidc_provider_arn, "/^.*oidc-provider\\/(.*)$/", "$1")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "tiptap_collab_pod_identity_role" {
  name               = "${var.cluster_name}-TiptapCollabPodRole"
  assume_role_policy = data.aws_iam_policy_document.tiptap_collab_pod_identity_assume_role_policy.json
  description        = "IAM role for Tiptap Collab pods (IRSA)"
  tags               = var.common_tags
}

resource "aws_iam_role_policy_attachment" "tiptap_collab_s3_access_attachment" {
  policy_arn = aws_iam_policy.tiptap_collab_s3_access.arn
  role       = aws_iam_role.tiptap_collab_pod_identity_role.name
}

# Output is defined in iam/tiptap-collab/outputs.tf
# output "tiptap_collab_pod_identity_role_arn" {
#   description = "ARN of the IAM role for Tiptap Collab pods (EKS Pod Identity)."
#   value       = aws_iam_role.tiptap_collab_pod_identity_role.arn
# } 