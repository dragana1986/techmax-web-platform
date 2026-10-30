provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "techmax-web-platform"
      ManagedBy = "terraform"
      Component = "pipeline-access"
    }
  }

}
