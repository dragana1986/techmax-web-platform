locals {
  environment = "prod"
  name        = "techmax-${local.environment}"
  cidr_block  = "10.30.0.0/16"
}

module "vpc" {
  source     = "git::ssh://git@github.com/dragana1986/platform-terraform-modules.git//vpc?ref=v1.0.0"
  name       = local.name
  cidr_block = local.cidr_block
}
