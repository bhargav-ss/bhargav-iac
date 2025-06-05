###############
#
# AWS Infrastructure including the EKS Cluster
#
# Logical order: 01 
##### "Logical order" refers to the order a human would think of these executions
##### (although Terraform will determine actual order executed)
#
###############

#
# VPC and Subnets
data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  az_count = length(data.aws_availability_zones.available.names)
  max_azs  = min(local.az_count, 3) # Use up to 3 AZs, but only if available (looking at you, us-west-1 👀)
}

data "aws_vpc" "target_vpc_for_peering" {
  id = var.target_vpc_id
}

module "vpc" {

  source  = "terraform-aws-modules/vpc/aws"
  version = ">=5.17.0"

  name            = "${local.prefix_env}-vpc"
  cidr            = "172.16.0.0/16"
  azs             = slice(data.aws_availability_zones.available.names, 0, local.max_azs)
  private_subnets = slice(["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"], 0, local.max_azs)
  public_subnets  = slice(["172.16.101.0/24", "172.16.102.0/24", "172.16.103.0/24"], 0, local.max_azs)

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Tag subnets for use by **Auto Mode** Load Balancer controller
  # https://docs.aws.amazon.com/eks/latest/userguide/tag-subnets-auto.html
  public_subnet_tags = {
    "Name"                   = "${local.prefix_env}-public-subnet"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "Name"                            = "${local.prefix_env}-private-subnet"
    "kubernetes.io/role/internal-elb" = "1"
  }

  # Tags for private route tables to target them for peering routes
  private_route_table_tags = {
    "Name"                     = "${local.prefix_env}-private-rtb"
    "VpcPeeringRouteTarget"    = "true"
  }

  tags = {
    Terraform   = "true"
    Environment = local.prefix_env

    # Ensure workspace check logic runs before resources created
    always_zero = length(null_resource.check_workspace)
  }
}

#
# EKS Cluster using Auto Mode
module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # *** AWS EKS Auto Mode is enabled here ***
  # Auto compute, storage, and load balancing are enabled here
  # This replaces the more complex eks_managed_node_groups block
  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  # Cluster access entry
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    "eks-pod-identity-agent" = {
      # Using default version, you can specify addon_version if needed.
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  tags = {
    Environment = local.prefix_env
    Terraform   = "true"

    # Ensure workspace check logic runs before resources created
    always_zero = length(null_resource.check_workspace)
  }

  # Transient failures in creating StorageClass, PersistentVolumeClaim, 
  # ServiceAccount, Deployment, were observed due to RBAC propagation not 
  # completed. Therefore raising this from its default 30s 
  dataplane_wait_duration = "60s"

}

locals {
  node_security_group_id = module.eks.node_security_group_id
}

# Create VPC endpoints (Private Links) for SSM Session Manager access to nodes
resource "aws_security_group" "vpc_endpoint_sg" {
  name   = "vpc-endpoint-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    description     = "Allow EKS Nodes to access VPC Endpoints"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [local.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = local.prefix_env
    Terraform   = "true"
  }
}

resource "aws_security_group" "tiptap_collab_pod" {
  name        = "${local.prefix_env}-tiptap-collab-pod-sg"
  description = "Security group for Tiptap Collab pods, managed in root module"
  vpc_id      = module.vpc.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "private_link_ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Environment = local.prefix_env
    Terraform   = "true"
  }
}

resource "aws_vpc_endpoint" "private_link_ssmmessages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Environment = local.prefix_env
    Terraform   = "true"
  }
}

resource "aws_vpc_endpoint" "private_link_ec2messages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Environment = local.prefix_env
    Terraform   = "true"
  }
}

# DynamoDb table
resource "aws_vpc_endpoint" "private_link_dynamodb" {

  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = {
    Environment = local.prefix_env
    Terraform   = "true"
  }
}

resource "aws_dynamodb_table" "guestbook" {

  name             = "${local.prefix_env}-guestbook"
  billing_mode     = "PROVISIONED"
  read_capacity    = 2
  write_capacity   = 2
  hash_key         = "GuestID"
  range_key        = "Name"
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  attribute {
    name = "GuestID"
    type = "S"
  }

  attribute {
    name = "Name"
    type = "S"
  }

  tags = {
    Environment = local.prefix_env
    Terraform   = "true"
  }

  # Ensure workspace check logic runs before resources created
  depends_on = [null_resource.check_workspace]

}

#
# VPC Peering using cloudposse/vpc-peering/aws module
# 
# Why use this peering connection?
# 
# - To allow agg-view-server from the EKS cluster to access other resources
#   in the target VPC like ALB, RDS, etc.
#
module "vpc_peering" {
  source  = "cloudposse/vpc-peering/aws"
  # Pin to a specific version. Check Terraform Registry for cloudposse/vpc-peering/aws.
  version = "1.0.0" # Example version from user-provided docs

  # Naming and context for CloudPosse modules
  namespace = "eks"
  stage     = local.prefix_env 
  name      = "peer-to-target"

  # VPC IDs for peering
  requestor_vpc_id = module.vpc.vpc_id
  acceptor_vpc_id  = var.target_vpc_id # var.target_vpc_id is defined in variables.tf

  # Auto-accept should be false for manual acceptance in the target account/VPC
  auto_accept = true

  # Use tags to identify which route tables in our VPC get routes to the peer
  requestor_route_table_tags = {
    "VpcPeeringRouteTarget" = "true"
  }

  # DNS resolution options
  requestor_allow_remote_vpc_dns_resolution = true
  acceptor_allow_remote_vpc_dns_resolution  = true
  
  tags = {
    Name        = "${local.prefix_env}-to-target-vpc-peer"
    Environment = local.prefix_env
    Terraform   = "true"
  }
}

#
# Private Hosted Zone for EKS Internal DNS (scispace.internal)
#
resource "aws_route53_zone" "internal_zone" {
  name = "scispace.internal"

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  comment = "Private hosted zone for EKS cluster internal DNS (scispace.internal)"

  tags = {
    Terraform   = "true"
    Environment = local.prefix_env
    Name        = "scispace.internal-private-zone"
  }
}
