# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh



output "organization_id" {
  value       = data.aws_organizations_organization.organization.id
  description = "The ID of the AWS Organization."
}

output "root_ou_id" {
  value       = tolist(data.aws_organizations_organization.organization.roots)[0].id
  description = "The ID of the root organizational unit."
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ OU-Level Details
# ---------------------------------------------------------------------------------------------------------------------
output "ou_paths_to_ou_id" {
  description = "Map of full OU-Path in the format '/root/a/b/' to OU-ID."
  value = merge(
    {
      "/root/" = local.root_ou_id
    },
    { for path, ou in aws_organizations_organizational_unit.level_1_ous : "${path}/" => ou.id },
    { for path, ou in aws_organizations_organizational_unit.level_2_ous : "${path}/" => ou.id },
    { for path, ou in aws_organizations_organizational_unit.level_3_ous : "${path}/" => ou.id },
    { for path, ou in aws_organizations_organizational_unit.level_4_ous : "${path}/" => ou.id },
    { for path, ou in aws_organizations_organizational_unit.level_5_ous : "${path}/" => ou.id }
  )
}

output "ou_ids_to_ou_path" {
  description = "Map of OU-ID to full OU-Path in the format '/root/a/b/'."
  value = merge(
    {
      (local.root_ou_id) = "/root/"
    },
    { for path, ou in aws_organizations_organizational_unit.level_1_ous : ou.id => "${path}/" },
    { for path, ou in aws_organizations_organizational_unit.level_2_ous : ou.id => "${path}/" },
    { for path, ou in aws_organizations_organizational_unit.level_3_ous : ou.id => "${path}/" },
    { for path, ou in aws_organizations_organizational_unit.level_4_ous : ou.id => "${path}/" },
    { for path, ou in aws_organizations_organizational_unit.level_5_ous : ou.id => "${path}/" }
  )
}

output "organizational_units_paths_ids" {
  description = "Legacy: Map of full OU-Path and OU-ID."
  value = merge(
    {
      "/root" = local.root_ou_id
    },
    { for path, ou in aws_organizations_organizational_unit.level_1_ous : path => ou.id },
    { for path, ou in aws_organizations_organizational_unit.level_2_ous : path => ou.id },
    { for path, ou in aws_organizations_organizational_unit.level_3_ous : path => ou.id },
    { for path, ou in aws_organizations_organizational_unit.level_4_ous : path => ou.id },
    { for path, ou in aws_organizations_organizational_unit.level_5_ous : path => ou.id }
  )
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ OU-Level Details
# ---------------------------------------------------------------------------------------------------------------------
output "level_1_ous_details" {
  description = "Details of Level 1 Organizational Units with OU path as key."
  value = { for path, ou in aws_organizations_organizational_unit.level_1_ous : "${path}/" => {
    id        = ou.id
    name      = ou.name
    path      = "${path}/"
    parent_id = ou.parent_id
    tags      = ou.tags
  } }
}

output "level_2_ous_details" {
  value = { for path, ou in aws_organizations_organizational_unit.level_2_ous : "${path}/" => {
    id        = ou.id
    name      = ou.name
    path      = "${path}/"
    parent_id = ou.parent_id
    tags      = ou.tags
  } }
  description = "Details of Level 2 Organizational Units."
}

output "level_3_ous_details" {
  value = { for path, ou in aws_organizations_organizational_unit.level_3_ous : "${path}/" => {
    id        = ou.id
    name      = ou.name
    path      = "${path}/"
    parent_id = ou.parent_id
    tags      = ou.tags
  } }
  description = "Details of Level 3 Organizational Units."
}

output "level_4_ous_details" {
  value = { for path, ou in aws_organizations_organizational_unit.level_4_ous : "${path}/" => {
    id        = ou.id
    name      = ou.name
    path      = "${path}/"
    parent_id = ou.parent_id
    tags      = ou.tags
  } }
  description = "Details of Level 4 Organizational Units."
}

output "level_5_ous_details" {
  value = { for path, ou in aws_organizations_organizational_unit.level_5_ous : "${path}/" => {
    id        = ou.id
    name      = ou.name
    path      = "${path}/"
    parent_id = ou.parent_id
    tags      = ou.tags
  } }
  description = "Details of Level 5 Organizational Units."
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ OU-SCP Assignments
# ---------------------------------------------------------------------------------------------------------------------
output "ou_scp_assignment" {
  description = "SCP assignments."
  value = [
    local.level_1_ou_scp_attachments,
    local.level_2_ou_scp_attachments,
    local.level_3_ou_scp_attachments,
    local.level_4_ou_scp_attachments,
    local.level_5_ou_scp_attachments,
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ Debugging
# ---------------------------------------------------------------------------------------------------------------------
output "ou_transformed" {
  description = "List of transformed OUs."
  value = [
    [for ou in local.level_1_ou_transformed : merge(ou, { path = "${ou.path}/" })],
    [for ou in local.level_2_ou_transformed : merge(ou, { path = "${ou.path}/" })],
    [for ou in local.level_3_ou_transformed : merge(ou, { path = "${ou.path}/" })],
    [for ou in local.level_4_ou_transformed : merge(ou, { path = "${ou.path}/" })],
    [for ou in local.level_5_ou_transformed : merge(ou, { path = "${ou.path}/" })]
  ]
}

