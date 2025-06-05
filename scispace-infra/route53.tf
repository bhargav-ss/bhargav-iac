resource "aws_route53_zone" "private" {
  name = "bhargav.internal"

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  tags = merge(local.tags, {
    Name = "bhargav-internal-private-zone"
  })
}

output "route53_private_zone_id" {
  description = "The ID of the private Route 53 zone."
  value       = aws_route53_zone.private.zone_id
}

output "route53_private_zone_name" {
  description = "The name of the private Route 53 zone."
  value       = aws_route53_zone.private.name
} 