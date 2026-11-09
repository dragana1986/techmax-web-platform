data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_caller_identity" "current" {
}

locals {
  state_bucket_arn = "arn:aws:s3:::techmax-terraform-state-${data.aws_caller_identity.current.account_id}"
}


