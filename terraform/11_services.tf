module "tiptap_service" {
  source = "./services/tiptap"

  prefix_env                 = local.prefix_env
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnets
  eks_node_security_group_id = module.eks.cluster_security_group_id
  cluster_name               = module.eks.cluster_name
  k8s_namespace              = "default" # Or a specific namespace for Tiptap
  k8s_service_account_name   = "tiptap-collab-server-sa"
  tiptap_s3_bucket_name      = "bhargav-tiptap-poc" # Replace with your actual bucket name or use a variable
  env_name                   = var.env_name # e.g., "stage", "prod"
  tiptap_database_url        = "postgres://scispace_root:5b2uhtv5aK8z@scispace.c0fwkhspicdq.us-west-2.rds.amazonaws.com:5432/tiptap" # FIXME: UPDATE THIS
  tiptap_database_url_direct = "postgres://scispace_root:5b2uhtv5aK8z@scispace.c0fwkhspicdq.us-west-2.rds.amazonaws.com:5432/tiptap"
  tiptap_collab_pod_sg_id    = aws_security_group.tiptap_collab_pod.id # Passed from root module

  depends_on = [
    module.eks # Ensure EKS cluster is up, providing the security group ID
  ]
}

output "tiptap_redis_endpoint" {
  description = "The primary endpoint for the Tiptap Redis cluster."
  value       = module.tiptap_service.endpoint
}

output "tiptap_redis_port" {
  description = "The port for the Tiptap Redis cluster."
  value       = module.tiptap_service.port
}
