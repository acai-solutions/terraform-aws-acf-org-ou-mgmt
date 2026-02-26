# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh



# ---------------------------------------------------------------------------------------------------------------------
# ¦ VERSIONS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.10"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.0"
      configuration_aliases = []
    }
  }
}


resource "aws_iam_role" "cicd_principal" {
  name                 = var.iam_role_settings.name
  path                 = var.iam_role_settings.path
  permissions_boundary = var.iam_role_settings.permissions_boundary_arn
  description          = "IAM Role used to provision the OrganizationStructure"
  assume_role_policy   = data.aws_iam_policy_document.assume_role_policy.json
  tags                 = var.resource_tags
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.iam_role_settings.aws_trustee_arns
    }
  }
}

resource "aws_iam_role_policy" "OrganizationStructure" {
  name   = "OrganizationStructure"
  role   = aws_iam_role.cicd_principal.id
  policy = data.aws_iam_policy_document.org_structure_policy.json
}

#tfsec:ignore:AVD-AWS-0057
data "aws_iam_policy_document" "org_structure_policy" {
  #checkov:skip=CKV_AWS_111 
  #checkov:skip=CKV_AWS_356 
  statement {
    effect = "Allow"
    actions = [
      "organizations:DescribeOrganization",
      "organizations:ListRoots",
      "organizations:ListParents",
      "organizations:ListOrganizationalUnitsForParent",
      "organizations:ListAccounts",
      "organizations:ListAccountsForParent",
      "organizations:ListAWSServiceAccessForOrganization",
      "organizations:DescribeOrganizationalUnit",
      "organizations:CreateOrganizationalUnit",
      "organizations:UpdateOrganizationalUnit",
      "organizations:DeleteOrganizationalUnit",
      "organizations:AttachPolicy",
      "organizations:DetachPolicy",
      "organizations:DescribePolicy",
      "organizations:ListTargetsForPolicy",
      "organizations:ListTagsForResource",
      "organizations:TagResource",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "MaintainModuleVersionSSMParameter"
    effect = "Allow"
    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:AddTagsToResource",
      "ssm:ListTagsForResource",
      "ssm:RemoveTagsFromResource",
      "ssm:DeleteParameter",
    ]
    resources = ["arn:aws:ssm:*:*:parameter/acai/acf-org-ou-mgmt/moduleversion"]
  }

  statement {
    sid    = "SSMDescribeParameters"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
    ]
    resources = ["*"]
  }
}
