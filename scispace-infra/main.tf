# VPC Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1.0" # Consistent with EKS module v20.x recommendations
  # dummy change 2

  name = "${local.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true # For simplicity in demo, can be false for multi-AZ NATs
  # one_nat_gateway_per_az = false # if single_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1",
    "karpenter.sh/discovery"          = local.cluster_name,             # For Karpenter-based NodePools
    "Name"                            = "${local.cluster_name}-private" # For NodeClass subnetSelector
  }
  private_route_table_tags = {
    "VpcPeeringRouteTarget" = "true"
  }

  tags = merge(local.tags, {
    # Ensure the VPC itself is tagged with its name for the data source lookup
    Name = "${local.cluster_name}-vpc"
  })
}

# IAM Role for Custom NodeClass Nodes (Auto Mode)
resource "aws_iam_role" "custom_automode_node_role" {
  name = "${local.cluster_name}-AutoNodeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "custom_node_AmazonEKSWorkerNodeMinimalPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  role       = aws_iam_role.custom_automode_node_role.name
}

resource "aws_iam_role_policy_attachment" "custom_node_AmazonEC2ContainerRegistryPullOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.custom_automode_node_role.name
}

# This policy is generally needed by VPC CNI, even in AutoMode for some operations.
# While NodePools manage nodes, CNI still runs on them.
resource "aws_iam_role_policy_attachment" "custom_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.custom_automode_node_role.name
}

# EKS Cluster Definition
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.34.0" # Aligning with eks-automode pattern for compatibility

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # IAM Roles: create_iam_role defaults to true, module will create the cluster role.
  # cluster_iam_role_arn is not set.

  # VPC Access Configuration for EKS API Endpoint
  cluster_endpoint_public_access = true # Enable public access, private access remains available within VPC.
  # public_access_cidrs defaults to ["0.0.0.0/0"] when cluster_endpoint_public_access is true.
  # endpoint_private_access defaults to false if not set and public is true.

  # Enable EKS AutoMode with no default node pools
  cluster_compute_config = {
    enabled    = true
    node_pools = [] # Disables built-in nodepools, we will use custom ones
  }

  # Access Entry for the custom automode node role
  access_entries = {
    custom_nodes_access = {
      principal_arn = aws_iam_role.custom_automode_node_role.arn
      type          = "EC2"

      policy_associations = {
        auto_node_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    # Note: terraform_admin_access entry was previously removed by user.
    # enable_cluster_creator_admin_permissions = true will grant admin to creator.
  }

  # enable_security_groups_for_pods was previously removed by user.
  # If re-enabled, add AmazonEKSVPCResourceController to cluster_iam_role_additional_policies

  # cluster_addons block removed as CoreDNS, kube-proxy, and VPC CNI are managed by AWS in EKS Auto Mode.

  enable_cluster_creator_admin_permissions = true # User set this to true
  # manage_aws_auth_configmap was previously removed by user. With access_entries, it's often false.

  tags = local.tags
}

# Security Group for Pods (Tiptap Collab specific)
resource "aws_security_group" "pod_tiptap_collab_sg" {
  name        = "${local.cluster_name}-pod-tiptap-collab-sg"
  description = "Allows specific traffic for Tiptap Collab pods."
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "pod-tiptap-collab-sg" })
}

# VPC Peering
module "vpc_peering" {
  count   = var.enable_vpc_peering ? 1 : 0
  source  = "cloudposse/vpc-peering/aws"
  version = "1.0.1"

  namespace = "scispace"
  stage     = var.env_name
  name      = "peer-to-legacy-rds"

  requestor_vpc_id = module.vpc.vpc_id
  acceptor_vpc_id  = var.target_vpc_id
  requestor_route_table_tags = {
    "VpcPeeringRouteTarget" = "true"
  }
  # NOTE: You still need to define acceptor_route_table_tags for vpc-50f5a335
  # e.g., acceptor_route_table_tags = { "SomeTagKey" = "SomeTagValue" }

  auto_accept = true

  tags = merge(local.tags, {
    Name = "${var.env_name}-to-legacy-vpc-peer"
  })

  depends_on = [module.vpc]
}

# Karpenter NodePools Module
module "karpenter_nodepools" {
  source = "./nodepools" # Path to the nodepools module directory

  cluster_name                   = local.cluster_name
  custom_automode_node_role_name = aws_iam_role.custom_automode_node_role.name
  pod_tiptap_collab_sg_id        = aws_security_group.pod_tiptap_collab_sg.id
  app_services_namespace         = var.app_services_namespace
  env_name                       = var.env_name

  depends_on = [
    module.eks, # Ensure EKS cluster is up
    aws_security_group.pod_tiptap_collab_sg # Ensure the SG is created before module uses its ID/tag
  ]
}
