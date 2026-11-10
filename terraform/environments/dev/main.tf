locals {
  environment              = "dev"
  name                     = "techmax-${local.environment}"
  cidr_block               = "10.10.0.0/16"
  availability_zones       = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs      = ["10.10.1.0/24", "10.10.2.0/24"]
  private_app_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]

  nat_gateway_mode = "single"
}


module "vpc" {
  source                   = "git::ssh://git@github.com/dragana1986/platform-terraform-modules.git//vpc?ref=v1.3.2"
  name                     = local.name
  cidr_block               = local.cidr_block
  availability_zones       = local.availability_zones
  public_subnet_cidrs      = local.public_subnet_cidrs
  private_app_subnet_cidrs = local.private_app_subnet_cidrs
  nat_gateway_mode         = local.nat_gateway_mode
}

module "alb" {
  source            = "git::ssh://git@github.com/dragana1986/platform-terraform-modules.git//alb?ref=v1.4.0"
  name              = local.name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  health_check_path = "/"
}

module "auto_scaling_group" {
  source                 = "git::ssh://git@github.com/dragana1986/platform-terraform-modules.git//auto-scaling-group?ref=v1.4.0"
  name                   = local.name
  vpc_id                 = module.vpc.vpc_id
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  alb_security_group_id  = module.alb.security_group_id
  target_group_arn       = module.alb.target_group_arn
  artifact_bucket_arn    = aws_s3_bucket.artifacts.arn

  user_data = templatefile("${path.module}/../../../scripts/deploy.sh", {
    s3_uri   = "s3://${aws_s3_bucket.artifacts.bucket}/releases/techmax-1.0.0.zip"
    app_name = "techmax"
  })

  tags = {
    Environment = local.environment
  }
}
