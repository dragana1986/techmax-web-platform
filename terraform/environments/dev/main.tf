locals {
  environment              = "dev"
  name                     = "techmax-${local.environment}"
  cidr_block               = "10.10.0.0/16"
  availability_zones       = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs      = ["10.10.1.0/24", "10.10.2.0/24"]
  private_app_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]

  nat_gateway_mode = "none"
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
