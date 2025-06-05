module "ecr" {
  source = "../../modules/ecr"

  name                 = "services-agg-view-server"
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  enable_lifecycle_policy = true
  max_image_count      = 5
  
  tags = {
    Service     = "agg-view-server"
    Environment = terraform.workspace
  }
}
