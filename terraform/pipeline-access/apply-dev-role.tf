data "aws_iam_policy_document" "apply_dev_role_trust" {
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

resource "aws_iam_role" "apply_dev" {
  name               = "techmax-github-actions-apply"
  description        = "Assumed by GitHub Actions in the dev environment to run terraform apply"
  assume_role_policy = data.aws_iam_policy_document.apply_dev_role_trust.json
}

moved {
  from = aws_iam_role_policy.apply
  to   = aws_iam_role_policy.apply_dev
}

moved {
  from = aws_iam_role.apply
  to   = aws_iam_role.apply_dev
}

data "aws_iam_policy_document" "apply_dev_permissions" {
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
    sid       = "ReadBalancingResources"
    effect    = "Allow"
    actions   = ["elasticloadbalancing:Describe*"]
    resources = ["*"]
  }

  statement {
    sid       = "ReadAutoScalingResources"
    effect    = "Allow"
    actions   = ["autoscaling:Describe*"]
    resources = ["*"]
  }

  statement {
    sid    = "ReadRoleResources"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:GetInstanceProfile",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/techmax-*",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/techmax-*"]
  }

  statement {
    sid       = "ReadAmazonLinuxImageParameters"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${var.aws_region}::parameter/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"]
  }

  statement {
    sid    = "ReadArtifactBuckets"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucket*",
      "s3:GetEncryptionConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:GetAccelerateConfiguration",
      "s3:ListTagsForResource",
    ]
    resources = ["arn:aws:s3:::techmax-*-artifacts-*"]
  }
}

data "aws_iam_policy_document" "apply_dev_network" {

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

  statement {
    sid       = "CreateDevSubnet"
    effect    = "Allow"
    actions   = ["ec2:CreateSubnet"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "CreateDevSubnetInDevVpc"
    effect    = "Allow"
    actions   = ["ec2:CreateSubnet"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "TagDevSubnetOnCreate"
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateSubnet"]
    }
  }

  statement {
    sid       = "ManageDevSubnet"
    effect    = "Allow"
    actions   = ["ec2:ModifySubnetAttribute", "ec2:CreateTags", "ec2:DeleteTags", "ec2:DeleteSubnet"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "CreateDevInternetGateway"
    effect    = "Allow"
    actions   = ["ec2:CreateInternetGateway"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:internet-gateway/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid     = "AttachDevInternetGatewayToVpc"
    effect  = "Allow"
    actions = ["ec2:AttachInternetGateway", "ec2:DetachInternetGateway"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:internet-gateway/*",
    "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "TagDevInternetGatewayOnCreate"
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:internet-gateway/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateInternetGateway"]
    }
  }

  statement {
    sid       = "ManageDevInternetGateway"
    effect    = "Allow"
    actions   = ["ec2:DeleteInternetGateway", "ec2:CreateTags", "ec2:DeleteTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:internet-gateway/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "CreateDevRouteTable"
    effect    = "Allow"
    actions   = ["ec2:CreateRouteTable"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:route-table/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "CreateDevRouteTableInDevVpc"
    effect    = "Allow"
    actions   = ["ec2:CreateRouteTable"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "TagDevRouteTable"
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:route-table/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateRouteTable"]
    }
  }

  statement {
    sid     = "RouteTableAssociationDev"
    effect  = "Allow"
    actions = ["ec2:AssociateRouteTable", "ec2:DisassociateRouteTable"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:route-table/*",
    "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "ManageDevRouteTable"
    effect    = "Allow"
    actions   = ["ec2:CreateRoute", "ec2:DeleteRouteTable", "ec2:DeleteRoute", "ec2:ReplaceRoute", "ec2:CreateTags", "ec2:DeleteTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:route-table/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }
}

data "aws_iam_policy_document" "apply_dev_nat_gateway" {

  statement {
    sid       = "AllocateDevElasticIp"
    effect    = "Allow"
    actions   = ["ec2:AllocateAddress"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:elastic-ip/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "TagDevElasticIpOnCreate"
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:elastic-ip/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["AllocateAddress"]
    }
  }

  statement {
    sid       = "ManageDevElasticIp"
    effect    = "Allow"
    actions   = ["ec2:ReleaseAddress", "ec2:DisassociateAddress", "ec2:CreateTags", "ec2:DeleteTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:elastic-ip/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "DisassociateDevElasticIpFromInterface"
    effect    = "Allow"
    actions   = ["ec2:DisassociateAddress"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*"]
  }

  statement {
    sid       = "CreateDevNatGateway"
    effect    = "Allow"
    actions   = ["ec2:CreateNatGateway"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:natgateway/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid     = "CreateDevNatGatewayInDevNetwork"
    effect  = "Allow"
    actions = ["ec2:CreateNatGateway"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:elastic-ip/*",
    "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "TagDevNatGatewayOnCreate"
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:natgateway/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateNatGateway"]
    }
  }

  statement {
    sid       = "ManageDevNatGateway"
    effect    = "Allow"
    actions   = ["ec2:DeleteNatGateway", "ec2:CreateTags", "ec2:DeleteTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:natgateway/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

}

data "aws_iam_policy_document" "apply_dev_compute" {

  statement {
    sid       = "CreateDevSecurityGroup"
    effect    = "Allow"
    actions   = ["ec2:CreateSecurityGroup"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["dev"]
    }
  }
  statement {
    sid       = "CreateSecurityGroupInDevVpc"
    effect    = "Allow"
    actions   = ["ec2:CreateSecurityGroup"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "TagDevSecurityGroupOnCreate"
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateSecurityGroup"]
    }
  }

  statement {
    sid       = "CreateDevSecurityGroupRule"
    effect    = "Allow"
    actions   = ["ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group-rule/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "AddRuleToDevSecurityGroup"
    effect    = "Allow"
    actions   = ["ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid     = "RemoveDevSecurityGroupRule"
    effect  = "Allow"
    actions = ["ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group-rule/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "TagDevSecurityGroupRuleOnCreate"
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group-rule/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["AuthorizeSecurityGroupIngress", "AuthorizeSecurityGroupEgress"]
    }
  }

  statement {
    sid    = "ManageDevSecurityGroup"
    effect = "Allow"
    actions = [
      "ec2:DeleteSecurityGroup",
      "ec2:ModifySecurityGroupRules",
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]

    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
    "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group-rule/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid    = "CreateDevLaunchTemplate"
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplate",
    ]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:launch-template/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "TagDevLaunchTemplateOnCreate"
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:launch-template/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateLaunchTemplate"]
    }
  }

  statement {
    sid    = "ManageDevLaunchTemplate"
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplateVersion",
      "ec2:DeleteLaunchTemplateVersions",
      "ec2:DeleteLaunchTemplate",
      "ec2:ModifyLaunchTemplate",
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]

    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:launch-template/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

}

data "aws_iam_policy_document" "apply_dev_auto_scaling" {

  statement {
    sid    = "CreateDevAutoScalingGroup"
    effect = "Allow"
    actions = [
      "autoscaling:CreateAutoScalingGroup",
    ]
    resources = ["arn:aws:autoscaling:${var.aws_region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/techmax-dev-*"]
  }

  statement {
    sid       = "LaunchFromAmazonImages"
    effect    = "Allow"
    actions   = ["ec2:RunInstances"]
    resources = ["arn:aws:ec2:${var.aws_region}::image/ami-*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:Owner"
      values   = ["amazon"]
    }
  }

  statement {
    sid     = "LaunchWithDevresources"
    effect  = "Allow"
    actions = ["ec2:RunInstances"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:launch-template/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid     = "LaunchDevInstancesAndVolumes"
    effect  = "Allow"
    actions = ["ec2:RunInstances"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid       = "LaunchWithNewNetworkInterfaces"
    effect    = "Allow"
    actions   = ["ec2:RunInstances"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*"]
  }

  statement {
    sid     = "TagDevInstancesAndVolumesOnLaunch"
    effect  = "Allow"
    actions = ["ec2:CreateTags"]
    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["RunInstances"]
    }
  }

  statement {
    sid       = "PassDevInstanceRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/techmax-dev-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  statement {
    sid    = "ManageDevAutoScalingGroup"
    effect = "Allow"
    actions = [
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:StartInstanceRefresh",
      "autoscaling:CancelInstanceRefresh",
      "autoscaling:PutScalingPolicy",
      "autoscaling:DeletePolicy",
      "autoscaling:DeleteAutoScalingGroup"
    ]
    resources = ["arn:aws:autoscaling:${var.aws_region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/techmax-dev-*"]

  }
}

data "aws_iam_policy_document" "apply_dev_load_balancing" {

  statement {
    sid    = "CreateDevLoadBalancingResources"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
    ]
    resources = ["arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/techmax-dev-*",
    "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:targetgroup/techmax-dev-*"]


    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = ["dev"]
    }
  }

  statement {
    sid     = "TagDevLoadBalancingResourcesOnCreate"
    effect  = "Allow"
    actions = ["elasticloadbalancing:AddTags"]
    resources = [
      "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/techmax-dev-*",
      "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:targetgroup/techmax-dev-*",
      "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:listener/app/techmax-dev-*",
    ]

    condition {
      test     = "StringEquals"
      variable = "elasticloadbalancing:CreateAction"
      values   = ["CreateLoadBalancer", "CreateTargetGroup", "CreateListener"]
    }
  }

  statement {
    sid     = "CreateDevListener"
    effect  = "Allow"
    actions = ["elasticloadbalancing:CreateListener"]
    resources = [
      "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/techmax-dev-*",
      "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:listener/app/techmax-dev-*",
    ]
  }

  statement {
    sid    = "ManageDevLoadBalancingResources"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeleteLoadBalancer",
    ]
    resources = [
      "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/techmax-dev-*",
      "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:targetgroup/techmax-dev-*",
      "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:listener/app/techmax-dev-*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }
}

data "aws_iam_policy_document" "apply_dev_iam_storage" {

  statement {
    sid    = "ManageDevInstanceRole"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateRoleDescription",
      "iam:UpdateAssumeRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:ListInstanceProfilesForRole",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/techmax-dev-*"]
  }

  statement {
    sid    = "AttachSessionManagerPolicyToDevRole"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/techmax-dev-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PolicyARN"
      values   = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
    }
  }

  statement {
    sid    = "ManageDevInstanceProfile"
    effect = "Allow"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/techmax-dev-*"]
  }

  statement {
    sid    = "ManageDevArtifactBucket"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketOwnershipControls",
      "s3:PutBucketTagging",
      "s3:TagResource",
      "s3:UntagResource",
    ]
    resources = ["arn:aws:s3:::techmax-dev-artifacts-*"]
  }
}


resource "aws_iam_role_policy" "apply_dev" {
  name   = "techmax-github-actions-apply-dev-permissions"
  role   = aws_iam_role.apply_dev.name
  policy = data.aws_iam_policy_document.apply_dev_permissions.json
}

resource "aws_iam_policy" "apply_dev_network" {
  name        = "techmax-github-actions-apply-dev-network"
  description = "The permissions that allow the dev pipeline to manage the dev network: the VPC, subnets, internet gateway, and route tables."
  policy      = data.aws_iam_policy_document.apply_dev_network.json
}

resource "aws_iam_role_policy_attachment" "apply_dev_network" {
  role       = aws_iam_role.apply_dev.name
  policy_arn = aws_iam_policy.apply_dev_network.arn
}

resource "aws_iam_policy" "apply_dev_nat_gateway" {
  name        = "techmax-github-actions-apply-dev-nat-gateway"
  description = "The permissions that allow the dev pipeline to manage the dev NAT gateway."
  policy      = data.aws_iam_policy_document.apply_dev_nat_gateway.json
}

resource "aws_iam_role_policy_attachment" "apply_dev_nat_gateway" {
  role       = aws_iam_role.apply_dev.name
  policy_arn = aws_iam_policy.apply_dev_nat_gateway.arn
}

resource "aws_iam_policy" "apply_dev_compute" {
  name        = "techmax-github-actions-apply-dev-compute"
  description = "The permissions that allow the dev pipeline to manage the dev compute resources: EC2 instances, security groups, and key pairs."
  policy      = data.aws_iam_policy_document.apply_dev_compute.json
}

resource "aws_iam_role_policy_attachment" "apply_dev_compute" {
  role       = aws_iam_role.apply_dev.name
  policy_arn = aws_iam_policy.apply_dev_compute.arn
}

resource "aws_iam_policy" "apply_dev_auto_scaling" {
  name        = "techmax-github-actions-apply-dev-auto-scaling"
  description = "The permissions that allow the dev pipeline to manage the dev auto scaling resources."
  policy      = data.aws_iam_policy_document.apply_dev_auto_scaling.json
}

resource "aws_iam_role_policy_attachment" "apply_dev_auto_scaling" {
  role       = aws_iam_role.apply_dev.name
  policy_arn = aws_iam_policy.apply_dev_auto_scaling.arn
}

resource "aws_iam_policy" "apply_dev_load_balancing" {
  name        = "techmax-github-actions-apply-dev-load-balancing"
  description = "The permissions that allow the dev pipeline to manage the dev load balancer resources."
  policy      = data.aws_iam_policy_document.apply_dev_load_balancing.json
}

resource "aws_iam_role_policy_attachment" "apply_dev_load_balancing" {
  role       = aws_iam_role.apply_dev.name
  policy_arn = aws_iam_policy.apply_dev_load_balancing.arn
}

resource "aws_iam_policy" "apply_dev_iam_storage" {
  name        = "techmax-github-actions-apply-dev-iam-storage"
  description = "The permissions that allow the dev pipeline to manage the dev IAM and storage resources."
  policy      = data.aws_iam_policy_document.apply_dev_iam_storage.json
}

resource "aws_iam_role_policy_attachment" "apply_dev_iam_storage" {
  role       = aws_iam_role.apply_dev.name
  policy_arn = aws_iam_policy.apply_dev_iam_storage.arn
}
