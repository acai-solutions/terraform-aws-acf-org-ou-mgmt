# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh



output "root_ou" {
  value = local.level_0_ous_path
}

output "level_1_ous_paths" {
  value = local.level_1_ous_paths
}

output "level_2_ous_paths" {
  value = local.level_2_ous_paths
}

output "level_3_ous_paths" {
  value = local.level_3_ous_paths
}

output "level_4_ous_paths" {
  value = local.level_4_ous_paths
}

output "level_5_ous_paths" {
  value = local.level_5_ous_paths
}


output "ou_paths_to_ou_id" {
  value = merge(
    local.level_0_ous_path,
    local.level_1_ous_paths,
    local.level_2_ous_paths,
    local.level_3_ous_paths,
    local.level_4_ous_paths,
    local.level_5_ous_paths
  )
}