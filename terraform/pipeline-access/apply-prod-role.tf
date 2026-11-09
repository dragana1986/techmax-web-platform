data "aws_iam_policy_document" "apply_prod_role_trust" {
  statement {
    sid     = "AllowGitHubProdEnvironment"
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
      values   = ["${var.github_subject_prefix}:environment:prod"]
    }
  }
}
resource "aws_iam_role" "apply_prod" {
  name               = "techmax-github-actions-apply-prod"
  description        = "Assumed by GitHub Actions in the prod environment to run terraform apply"
  assume_role_policy = data.aws_iam_policy_document.apply_prod_role_trust.json
}

data "aws_iam_policy_document" "apply_prod_permissions" {
  statement {
    sid       = "ManageProdState"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${local.state_bucket_arn}/prod/terraform.tfstate"]
  }

  statement {
    sid       = "ManageProdStateLock"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["${local.state_bucket_arn}/prod/terraform.tfstate.tflock"]
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
    sid       = "ManageProdVpc"
    effect    = "Allow"
    actions   = ["ec2:ModifyVpcAttribute", "ec2:CreateTags", "ec2:DeleteTags", "ec2:DeleteVpc"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["prod"]
    }
  }

  statement {
    sid       = "CreateProdVpc"
    effect    = "Allow"
    actions   = ["ec2:CreateVpc"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["prod"]
    }
  }

  statement {
    sid       = "TagProdVpcOnCreate"
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

resource "aws_iam_role_policy" "apply_prod" {
  name   = "techmax-github-actions-apply-prod-permissions"
  role   = aws_iam_role.apply_prod.name
  policy = data.aws_iam_policy_document.apply_prod_permissions.json
}
