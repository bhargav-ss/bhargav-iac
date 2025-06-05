resource "aws_elasticache_subnet_group" "tiptap_redis" {
  name       = "${var.prefix_env}-tiptap-redis"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.prefix_env}-tiptap-redis-subnet-group"
    Environment = var.prefix_env
    Terraform   = "true"
  }
}

resource "aws_security_group" "tiptap_redis" {
  name        = "${var.prefix_env}-tiptap-redis-sg"
  description = "Allow Redis traffic from EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from Tiptap Collab pods"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.tiptap_collab_pod_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.prefix_env}-tiptap-redis-sg"
    Environment = var.prefix_env
    Terraform   = "true"
  }
}

resource "aws_elasticache_replication_group" "tiptap_redis" {
  replication_group_id          = "${var.prefix_env}-tiptap-redis"
  description                   = "ElastiCache Redis for Tiptap service (no replicas)"
  node_type                     = "cache.t3.micro"
  port                          = 6379
  automatic_failover_enabled    = false
  num_node_groups               = 1
  replicas_per_node_group       = 0
  subnet_group_name             = aws_elasticache_subnet_group.tiptap_redis.name
  security_group_ids            = [aws_security_group.tiptap_redis.id]
  engine                        = "redis"
  engine_version                = "7.0"
  parameter_group_name          = "default.redis7"
  apply_immediately             = true

  tags = {
    Name        = "${var.prefix_env}-tiptap-redis"
    Environment = var.prefix_env
    Terraform   = "true"
    Service     = "tiptap"
  }
} 