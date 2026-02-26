# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh



output "example_complete" {
  description = "example_complete"
  value       = module.example_complete
}

output "test_success1" {
  description = "Check if specific OU-Path exists."
  value       = module.example_complete.level_3_ous_details["/root/level1_unit1/level1_unit1__level2_unit2/level1_unit1__level2_unit2__level3_unit1/"].name == "level1_unit1__level2_unit2__level3_unit1"
}

output "test_success2" {
  description = "Check if specific OU-Path exists."
  value       = lookup(module.example_complete.organizational_units_paths_ids, "/root/WorkloadAccounts/BusinessUnit_1/Prod/", null) != null
}

output "example_reporting" {
  description = "example_reporting"
  value       = module.example_reporting
}

output "test_success3" {
  description = "Check if specific OU-Path exists."
  value       = contains(keys(module.example_reporting.ous_paths), "/root/WorkloadAccounts/BusinessUnit_1/Prod/")
}
