# Staging Environment Configuration
aws_region   = "us-west-2"
cluster_name = "scispace-stage-cluster"
env_name     = "stage"

# Cluster Configuration
cluster_version = "1.33"

# Network Configuration (smaller CIDR for staging)
vpc_cidr               = "172.17.0.0/16"
private_subnet_cidrs   = ["172.17.1.0/24", "172.17.2.0/24"]
public_subnet_cidrs    = ["172.17.101.0/24", "172.17.102.0/24"]

# Application Configuration
app_services_namespace = "app-services"
tiptap_collab_replicas = 1  # Single replica for staging

# Tiptap Configuration
tiptap_collab_image           = "249531194221.dkr.ecr.us-west-2.amazonaws.com/bhargav/tiptap:1.0.0"
tiptap_s3_bucket_name         = "bhargav-tiptap-stage" # Different bucket for staging
tiptap_aws_folder_name        = "tiptap-stage"
tiptap_port_api              = "8081"
tiptap_aws_use_s3            = "1"
tiptap_aws_force_path_style  = "1"
tiptap_collab_clustermode    = "1"

# Infrastructure Configuration
caddy_internal_http_port = 8080

# VPC Peering (can be enabled for staging testing)
enable_vpc_peering = false
# target_vpc_id = "vpc-xxxxxxxxx"  # Uncomment and set if needed

# Redis Configuration (staging instance)
tiptap_redis_url = "redis://v4-bhargav-tiptap-stage.y4dwpy.ng.0001.usw2.cache.amazonaws.com"

# Sensitive variables - these will be provided via environment variables in CI/CD:
# tiptap_database_url        = "<provided via TF_VAR_tiptap_database_url>"
# tiptap_database_url_direct = "<provided via TF_VAR_tiptap_database_url_direct>"
# tiptap_license_key         = "<provided via TF_VAR_tiptap_license_key>"
# tiptap_jwt_secret          = "<provided via TF_VAR_tiptap_jwt_secret>"
# tiptap_api_secret          = "<provided via TF_VAR_tiptap_api_secret>" 