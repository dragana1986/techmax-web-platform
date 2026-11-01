provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "techmax-web-platform"
      Environment = local.environment
      ManagedBy   = "terraform"
    }
  }
}
