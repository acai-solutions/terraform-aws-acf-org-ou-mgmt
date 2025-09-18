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
# ¦ OU-Names are case-sensitive!!!
# ---------------------------------------------------------------------------------------------------------------------
variable "organizational_units" {
  description = "The organization with the tree of organizational units and their tags. OU-Names are case-sensitive!!!"
  type = object({
    level1_units = optional(list(object({
      name    = string,
      scp_ids = optional(list(string), [])
      tags    = optional(map(string), {}),
      level2_units = optional(list(object({
        name    = string,
        scp_ids = optional(list(string), [])
        tags    = optional(map(string), {}),
        level3_units = optional(list(object({
          name    = string,
          scp_ids = optional(list(string), [])
          tags    = optional(map(string), {}),
          level4_units = optional(list(object({
            name    = string,
            scp_ids = optional(list(string), [])
            tags    = optional(map(string), {}),
            level5_units = optional(list(object({
              name    = string,
              scp_ids = optional(list(string), [])
              tags    = optional(map(string), {}),
            })), [])
          })), [])
        })), [])
      })), [])
    })), [])
  })
  default = null
}
