resource "helm_release" "karpenter_custom_nodepools" {
  name             = "custom-nodepools"              # Revert to original name
  chart            = "${path.module}/helm_chart" # Path to your local Helm chart directory
  namespace        = "nginx"                         # Changed namespace to nginx
  create_namespace = true
  version          = "0.1.1" # Explicitly set chart version, aligns with Chart.yaml

  values = [
    yamlencode({
      cluster_name = var.cluster_name # Use module variable
      nodeClass = {
        role = var.custom_automode_node_role_name # Use module variable
        additionalSecurityGroupSelectorTerms = []
      }
      nameSuffix = "general-purpose" # This was in the .tpl file, kept here for consistency
      nodePool = {
      }
    })
  ]

  # Timeout for Helm operations
  timeout = 600
}
