resource "aws_security_group_rule" "allow_eks_pods_to_rds" {
  count = var.enable_vpc_peering ? 1 : 0

  type                     = "ingress"
  security_group_id        = "sg-068770844a9bd4c58"
  protocol                 = "tcp"
  from_port                = 5432
  to_port                  = 5432
  source_security_group_id = aws_security_group.pod_tiptap_collab_sg.id
  description              = "Allow Tiptap Collab pods from EKS VPC to Legacy RDS"

  depends_on = [module.vpc_peering]
}