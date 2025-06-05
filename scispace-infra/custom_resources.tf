locals {
  enable_custom_resources            = true // Set to true to enable these resources
  tiptap_collab_service_account_name = "tiptap-collab-sa" # Define SA name as a local

  # Define lists of YAML files to apply, similar to the pattern
  storageclass_yamls = [
    "ebs-storageclass.yaml"
  ]

  # Original lists for existing NodePools/NodeClasses
  custom_nodeclass_yamls = [
    # "nodeclass-tiptap-custom.yaml", // Removed as Tiptap Collab NodeClass is now managed by Helm
    "kube-services-nodeclass.yaml"
  ]
  custom_nodepool_yamls = [
    # "nodepool-tiptap-custom.yaml",  // Removed as Tiptap Collab NodePool is now managed by Helm
    "kube-services-nodepool.yaml"
  ]
}

module "tiptap_collab_iam" {
  source = "./iam/tiptap-collab"

  cluster_name                       = local.cluster_name                       # from root module's locals
  tiptap_s3_bucket_name              = var.tiptap_s3_bucket_name                # from root module's variables
  common_tags                        = local.tags                               # from root module's locals
  eks_oidc_provider_arn              = module.eks.oidc_provider_arn             # from the EKS module output
  tiptap_collab_namespace            = var.app_services_namespace
  tiptap_collab_service_account_name = local.tiptap_collab_service_account_name # from root module's locals (defined for the SA)
}

# Apply default storage class for EKS AutoMode
resource "kubectl_manifest" "storageclass" {
  for_each   = local.enable_custom_resources ? toset(local.storageclass_yamls) : []
  yaml_body  = file("${path.module}/eks_config/${each.value}")
  depends_on = [module.eks] # Ensure EKS cluster and OIDC provider are ready
}

# Apply ALB IngressClass for EKS Auto Mode
resource "kubectl_manifest" "alb_ingress_class" {
  count = local.enable_custom_resources ? 1 : 0
  yaml_body = file("${path.module}/eks_config/alb-ingress-class.yaml")
  depends_on = [module.eks] # Ensure EKS cluster is ready
}

# Original NodeClass resources using for_each over YAML list (existing)
resource "kubectl_manifest" "custom_nodeclass" {
  for_each = local.enable_custom_resources ? toset(local.custom_nodeclass_yamls) : []
  yaml_body = templatefile("${path.module}/eks_config/${each.value}", {
    node_iam_role_name = aws_iam_role.custom_automode_node_role.name
    cluster_name       = module.eks.cluster_name
  })
  depends_on = [module.eks, aws_iam_role.custom_automode_node_role]
}

# Original NodePool resources using for_each over YAML list (existing)
resource "kubectl_manifest" "custom_nodepool" {
  for_each   = local.enable_custom_resources ? toset(local.custom_nodepool_yamls) : []
  yaml_body  = file("${path.module}/eks_config/${each.value}") # Assumes these are not templated or get vars differently
  depends_on = [kubectl_manifest.custom_nodeclass]
}

# Nginx Dummy Deployment for testing the new node pool
resource "kubectl_manifest" "nginx_dummy_deployment" {
  count     = local.enable_custom_resources ? 1 : 0
  yaml_body = file("${path.module}/eks_config/nginx-deployment.yaml")
  depends_on = [
    module.karpenter_nodepools
  ]
}

# Apply the Tiptap Collab Namespace
resource "kubectl_manifest" "tiptap_collab_namespace" {
  count = local.enable_custom_resources ? 1 : 0
  yaml_body = templatefile("${path.module}/eks_config/tiptap-collab-namespace.yaml", {
    tiptap_collab_namespace = var.app_services_namespace
  })
  depends_on = [
    module.eks # Ensure cluster is ready for any k8s resources
  ]
}

# Apply the Tiptap Collab Service Account
resource "kubectl_manifest" "tiptap_collab_service_account" {
  count = local.enable_custom_resources ? 1 : 0
  yaml_body = templatefile("${path.module}/eks_config/tiptap-collab-sa.yaml", {
    tiptap_collab_namespace             = var.app_services_namespace,
    tiptap_collab_service_account_name  = local.tiptap_collab_service_account_name,
    tiptap_collab_pod_identity_role_arn = module.tiptap_collab_iam.tiptap_collab_pod_identity_role_arn
  })
  depends_on = [
    kubectl_manifest.tiptap_collab_namespace,
    module.tiptap_collab_iam
  ]
}

# Apply the Tiptap Collab Deployment
resource "kubectl_manifest" "tiptap_collab_deployment" {
  count     = local.enable_custom_resources ? 1 : 0
  yaml_body = templatefile("${path.module}/eks_config/tiptap-collab-deployment-only.yaml", {
    tiptap_collab_namespace           = var.app_services_namespace,
    tiptap_collab_service_account_name = local.tiptap_collab_service_account_name,
    tiptap_collab_image               = var.tiptap_collab_image,
    tiptap_collab_replicas            = var.tiptap_collab_replicas,
    aws_region                        = var.aws_region,
    tiptap_port_api                     = var.tiptap_port_api,
    tiptap_aws_use_s3                   = var.tiptap_aws_use_s3,
    tiptap_s3_bucket_name               = var.tiptap_s3_bucket_name,
    tiptap_aws_folder_name              = var.tiptap_aws_folder_name,
    tiptap_aws_force_path_style         = var.tiptap_aws_force_path_style,
    tiptap_database_url                 = var.tiptap_database_url,
    tiptap_database_url_direct          = var.tiptap_database_url_direct,
    tiptap_collab_clustermode           = var.tiptap_collab_clustermode,
    tiptap_redis_url                    = var.tiptap_redis_url,
    tiptap_license_key                  = var.tiptap_license_key,
    tiptap_jwt_secret                   = var.tiptap_jwt_secret,
    tiptap_api_secret                   = var.tiptap_api_secret,
    env_name                            = var.env_name
  })
  depends_on = [
    kubectl_manifest.tiptap_collab_service_account,
    aws_security_group.pod_tiptap_collab_sg,
    module.karpenter_nodepools
  ]
}

# Apply the Tiptap Collab Service
resource "kubectl_manifest" "tiptap_collab_service" {
  count = local.enable_custom_resources ? 1 : 0
  yaml_body = templatefile("${path.module}/eks_config/tiptap-collab-service.yaml", {
    tiptap_collab_namespace = var.app_services_namespace
  })
  depends_on = [
    kubectl_manifest.tiptap_collab_deployment
  ]
}

# Apply the Tiptap Collab Headless Service for internal discovery
resource "kubectl_manifest" "tiptap_collab_headless_service" {
  count = local.enable_custom_resources ? 1 : 0
  yaml_body = templatefile("${path.module}/eks_config/tiptap-collab-headless-service.yaml", {
    tiptap_collab_namespace = var.app_services_namespace
  })
  depends_on = [
    kubectl_manifest.tiptap_collab_namespace
  ]
}

# Caddy Proxy Resources
# ConfigMap for Caddyfile
resource "kubectl_manifest" "caddy_configmap" {
  count = local.enable_custom_resources ? 1 : 0
  yaml_body = templatefile("${path.module}/eks_config/caddy/caddy-configmap.yaml", {
    tiptap_collab_namespace  = var.app_services_namespace,
    caddy_internal_http_port = var.caddy_internal_http_port
  })
  depends_on = [
    kubectl_manifest.tiptap_collab_namespace
  ]
}

# Deployment for Caddy
resource "kubectl_manifest" "caddy_deployment" {
  count = local.enable_custom_resources ? 1 : 0
  yaml_body = templatefile("${path.module}/eks_config/caddy/caddy-deployment.yaml", {
    tiptap_collab_namespace  = var.app_services_namespace,
    caddy_internal_http_port = var.caddy_internal_http_port
  })
  depends_on = [
    kubectl_manifest.caddy_configmap,
    kubectl_manifest.custom_nodepool["nodepool-tiptap-custom.yaml"] # Corrected dependency
  ]
}

# Service for Caddy
resource "kubectl_manifest" "caddy_service" {
  count = local.enable_custom_resources ? 1 : 0
  yaml_body = templatefile("${path.module}/eks_config/caddy/caddy-service.yaml", {
    tiptap_collab_namespace  = var.app_services_namespace,
    caddy_internal_http_port = var.caddy_internal_http_port
  })
  depends_on = [
    kubectl_manifest.caddy_deployment
  ]
}
