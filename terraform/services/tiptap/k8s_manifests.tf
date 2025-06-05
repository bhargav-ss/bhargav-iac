locals {
  # tiptap_k8s_manifest_files       = fileset("${path.module}/kubernetes/", "*.yaml") # No longer needed
  tiptap_k8s_namespace            = var.k8s_namespace
  tiptap_k8s_service_account_name = var.k8s_service_account_name // This is the name Helm chart will create/use
}

resource "helm_release" "tiptap_collab_server" {
  name       = "tiptap-collab-server"
  chart      = "${path.module}/chart"
  namespace  = local.tiptap_k8s_namespace
  version    = "0.1.0" # Assuming Chart.yaml appVersion or version

  values = [
    yamlencode({
      replicaCount = 1,
      serviceAccount = {
        # name: local.tiptap_k8s_service_account_name # Already set in values.yaml by default
        # create: true # Already set in values.yaml by default
        annotations = {
        }
      },
      config = {
        AWS_BUCKET_NAME     = var.tiptap_s3_bucket_name
        AWS_FOLDER_NAME     = "tiptap-${var.env_name}"
        DATABASE_URL        = var.tiptap_database_url
        DATABASE_URL_DIRECT = var.tiptap_database_url_direct
        REDIS_URL           = format("redis://%s:%s", aws_elasticache_replication_group.tiptap_redis.primary_endpoint_address, aws_elasticache_replication_group.tiptap_redis.port)
      }
    })
  ]

  depends_on = [
    aws_eks_pod_identity_association.tiptap_collab_server
  ]
}

# EKS Pod Identity Association remains managed by Terraform
resource "aws_eks_pod_identity_association" "tiptap_collab_server" {
  cluster_name    = var.cluster_name
  namespace       = local.tiptap_k8s_namespace
  service_account = local.tiptap_k8s_service_account_name // This should be the SA name Helm will use/create
  role_arn        = aws_iam_role.tiptap_server_pod_identity.arn

  tags = {
    Name        = "${var.prefix_env}-tiptap-pod-identity-assoc"
    Environment = var.prefix_env
    Terraform   = "true"
    Service     = "tiptap"
  }
}