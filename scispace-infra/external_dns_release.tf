# external_dns_release.tf

resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = local.external_dns_service_account_namespace      # Defined in external_dns_iam.tf (e.g., kube-system)
  chart      = "external-dns"                                    # Chart name from kubernetes-sigs
  repository = "https://kubernetes-sigs.github.io/external-dns/" # Official repository
  version    = "1.14.0"                                          # Version from your reference configuration

  # Ensure OIDC provider and IAM role are created before Helm release attempts to use them
  depends_on = [
    module.eks.oidc_provider,
    aws_iam_role.external_dns
  ]

  set {
    name  = "provider"
    value = "aws"
  }
  set {
    name  = "aws.region"
    value = var.aws_region # Using the region variable
  }
  set {
    name  = "aws.zoneType"
    value = "private" # We are using a private zone
  }
  set {
    name  = "aws.preferCNAME"
    value = "true" # As per your reference
  }
  set {
    name  = "domainFilters[0]"
    value = aws_route53_zone.private.name # Filter to only manage our bhargav.internal zone
  }
  set {
    name  = "txtOwnerId"
    value = aws_route53_zone.private.zone_id # Helps ExternalDNS identify records it owns
  }
  set {
    name  = "policy"
    value = "sync"
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = local.external_dns_service_account_name # Defined in external_dns_iam.tf
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" # Correctly escaped for Terraform HCL
    value = aws_iam_role.external_dns.arn
  }
  set {
    name  = "logLevel"
    value = "info" # Can be "debug" for troubleshooting
  }
  set {
    name  = "sources[0]"
    value = "service" # Explicitly setting service source
  }
  # Optional: If you have many services and only want to target specific ones for DNS
  # set {
  #   name  = "sources[0]"
  #   value = "service" # Only consider services
  # }
  # set {
  #   name = "serviceMonitor.enabled" # If you use Prometheus Operator
  #   value = "true"
  # }
} 