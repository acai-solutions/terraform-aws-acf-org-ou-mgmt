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
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_organizations_organization" "org" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  org_id     = data.aws_organizations_organization.org.id
  root_ou_id = data.aws_organizations_organization.org.roots[0].id
  # AWS Organizations is a global service endpoint in the standard partition (us-east-1).
  # In non-standard partitions (e.g. ESC), it lives in the actual deployment region.
  organizations_endpoint_url = "https://organizations.${data.aws_partition.current.dns_suffix == "amazonaws.com" ? "us-east-1" : data.aws_region.current.name}.${data.aws_partition.current.dns_suffix}"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA - OU TREE
# ---------------------------------------------------------------------------------------------------------------------
data "external" "get_ou_tree" {
  program = concat(
    [
      "python3",
      "${path.module}/python/get_ou_tree.py",
      "--expected_org_id",
      local.org_id,
      "--expected_root_ou_id",
      local.root_ou_id,
      "--endpoint-url",
      local.organizations_endpoint_url,
    ],
    var.org_mgmt_reader_role_arn != null && var.org_mgmt_reader_role_arn != "" ? ["--role-arn", var.org_mgmt_reader_role_arn] : []
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS - OU TREE
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Full OU tree: { "/root/": { "ou_id": "r-xxxx", "level": 0 }, "/root/Core/": { "ou_id": "ou-...", "level": 1 }, ... }
  ou_tree = jsondecode(data.external.get_ou_tree.result["result"])

  # Flat map: path -> ou_id (all levels, automatically handles any OU nesting depth)
  ou_paths_to_ou_id = { for path, info in local.ou_tree : path => info.ou_id }

  # Per-level maps for backward compatibility (levels beyond 5 are included in ou_paths_to_ou_id)
  level_0_ous_path  = { for path, info in local.ou_tree : path => info.ou_id if info.level == 0 }
  level_1_ous_paths = { for path, info in local.ou_tree : path => info.ou_id if info.level == 1 }
  level_2_ous_paths = { for path, info in local.ou_tree : path => info.ou_id if info.level == 2 }
  level_3_ous_paths = { for path, info in local.ou_tree : path => info.ou_id if info.level == 3 }
  level_4_ous_paths = { for path, info in local.ou_tree : path => info.ou_id if info.level == 4 }
  level_5_ous_paths = { for path, info in local.ou_tree : path => info.ou_id if info.level == 5 }
}

