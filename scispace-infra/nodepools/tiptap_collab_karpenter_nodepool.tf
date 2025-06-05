resource "helm_release" "tiptap_collab_nodepool" {
  name             = "tiptap-collab-nodes" 
  chart            = "${path.module}/helm_chart"
  namespace        = var.app_services_namespace 
  create_namespace = true                        
  version          = "0.1.1"                     # Match the chart version

  values = [
    yamlencode({
      cluster_name = var.cluster_name # Use module variable
      nameSuffix   = "tiptap-custom" # This will be used for NodeGroupType and resource naming part

      nodeClass = {
        role = var.custom_automode_node_role_name # Use module variable
        additionalSecurityGroupSelectorTerms = [
          { id = var.pod_tiptap_collab_sg_id } 
        ]
        tags = { 
          NodeClassGroup = "tiptap-custom-compute"
          Environment    = var.env_name # Use module variable
        }
      }

      nodePool = {
        labels = { 
          intent = "apps"
        }
        taints = [
          {
            key    = "service"
            value  = "tiptap" 
            effect = "NoSchedule"
          }
        ]
      }
    })
  ]

  timeout = 600
} 