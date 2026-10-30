terraform {
  backend "s3" {
    bucket       = "techmax-terraform-state-222634382766"
    key          = "pipeline-access/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
