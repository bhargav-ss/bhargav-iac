# external_dns_iam.tf

locals {
  external_dns_service_account_namespace = "kube-system" # Or your preferred namespace for ExternalDNS
  external_dns_service_account_name      = "external-dns"
}

# IAM Policy for ExternalDNS
resource "aws_iam_policy" "external_dns" {
  name        = "${local.cluster_name}-ExternalDNSManagementPolicy"
  description = "Allows ExternalDNS to manage Route 53 records for the cluster ${local.cluster_name}"

  # Policy document allowing changes to the specific private zone
  # and listing hosted zones to find it.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["route53:ChangeResourceRecordSets"],
        Resource = [aws_route53_zone.private.arn] # Restrict to the bhargav.internal zone
      },
      {
        Effect = "Allow",
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ],
        Resource = ["*"] # Needed to find the zone and check existing records
      }
    ]
  })

  tags = local.tags
}

# IAM Role for ExternalDNS Service Account (IRSA)
data "aws_iam_policy_document" "external_dns_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:${local.external_dns_service_account_namespace}:${local.external_dns_service_account_name}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "${local.cluster_name}-ExternalDNSRole"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role_policy.json
  description        = "IAM role for ExternalDNS service account in cluster ${local.cluster_name}"
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  policy_arn = aws_iam_policy.external_dns.arn
  role       = aws_iam_role.external_dns.name
}

output "external_dns_iam_role_arn" {
  description = "ARN of the IAM role for ExternalDNS."
  value       = aws_iam_role.external_dns.arn
} 