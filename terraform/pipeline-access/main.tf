data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "plan_role_trust" {
  statement {
    sid     = "AllowGitHubPullRequests"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${var.github_subject_prefix}:pull_request"]
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = "techmax-github-actions-plan"
  description        = "Assumed by GitHub Actions on pull requests to run terraform plan"
  assume_role_policy = data.aws_iam_policy_document.plan_role_trust.json
}


data "aws_caller_identity" "current" {
}

locals {
  state_bucket_arn = "arn:aws:s3:::techmax-terraform-state-${data.aws_caller_identity.current.account_id}"
}

data "aws_iam_policy_document" "plan_permissions" {
  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]
  }

  statement {
    sid       = "ReadDevState"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${local.state_bucket_arn}/dev/terraform.tfstate"]
  }

  statement {
    sid       = "ManageDevStateLock"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["${local.state_bucket_arn}/dev/terraform.tfstate.tflock"]
  }

  statement {
    sid       = "ReadEc2Resources"
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "plan" {
  name   = "techmax-github-actions-plan-permissions"
  role   = aws_iam_role.plan.name
  policy = data.aws_iam_policy_document.plan_permissions.json
}

data "aws_iam_policy_document" "apply_role_trust" {
  statement {
    sid     = "AllowGitHubDevEnvironment"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${var.github_subject_prefix}:environment:dev"]
    }
  }
}

resource "aws_iam_role" "apply" {
  name               = "techmax-github-actions-apply"
  description        = "Assumed by GitHub Actions in the dev environment to run terraform apply"
  assume_role_policy = data.aws_iam_policy_document.apply_role_trust.json
}

data "aws_iam_policy_document" "apply_permissions" {
  statement {
    sid       = "ManageDevState"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${local.state_bucket_arn}/dev/terraform.tfstate"]
  }

  statement {
    sid       = "ManageDevStateLock"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["${local.state_bucket_arn}/dev/terraform.tfstate.tflock"]
  }

  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]
  }

  statement {
    sid       = "ReadEc2Resources"
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }

  statement {
    sid       = "ManageDevVpc"
    effect    = "Allow"
    actions   = ["ec2:ModifyVpcAttribute", "ec2:CreateTags", "ec2:DeleteTags", "ec2:DeleteVpc"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "CreateDevVpc"
    effect    = "Allow"
    actions   = ["ec2:CreateVpc"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "TagDevVpcOnCreate"
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateVpc"]
    }
  }
}

resource "aws_iam_role_policy" "apply" {
  name   = "techmax-github-actions-apply-permissions"
  role   = aws_iam_role.apply.name
  policy = data.aws_iam_policy_document.apply_permissions.json
}
