# Define the kubernetes-sigs/external-dns Helm chart installation
# Documentation: https://github.com/kubernetes-sigs/external-dns

# Create IAM policy for external-dns to modify Route53 records
resource "aws_iam_policy" "external_dns" {
  name        = "${local.cluster_name}-external-dns"
  description = "IAM Policy for external-dns to modify Route53 records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/${aws_route53_zone.internal_zone.id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = ["*"]
      }
    ]
  })

  tags = {
    Environment = local.prefix_env
    Terraform   = "true"
    Project     = "external-dns"
  }
}

# Create IAM Role for ServiceAccount (IRSA)
module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30.0"

  role_name                  = "${local.cluster_name}-external-dns"
  attach_external_dns_policy = false

  role_policy_arns = {
    policy = aws_iam_policy.external_dns.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

  tags = {
    Environment = local.prefix_env
    Terraform   = "true"
    Project     = "external-dns"
  }
}

# Deploy external-dns using the official kubernetes-sigs Helm chart
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.14.0" # Update to the latest version as needed
  namespace  = "kube-system"

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_dns_irsa.iam_role_arn
  }

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  # Using CNAME for ALB is recommended, as ALB IPs can change
  set {
    name  = "aws.preferCNAME"
    value = "true"
  }

  set {
    name  = "policy"
    value = "sync" # Options: sync, upsert-only, create-only
  }

  set {
    name  = "domainFilters[0]"
    value = "scispace.internal"
  }

  set {
    name  = "txtOwnerId"
    value = "scispace-internal-dns"
  }

  set {
    name  = "logLevel"
    value = "debug" # Set to debug for troubleshooting, can change to info later
  }

  # These control which Kubernetes resources external-dns should monitor
  set {
    name  = "sources[0]"
    value = "service"
  }

  set {
    name  = "sources[1]"
    value = "ingress"
  }

  # Depends on EKS and the private hosted zone
  depends_on = [
    module.eks,
    aws_route53_zone.internal_zone
  ]
}

# Output the IAM role ARN for reference
output "external_dns_role_arn" {
  description = "The ARN of the IAM role used by external-dns"
  value       = module.external_dns_irsa.iam_role_arn
}
