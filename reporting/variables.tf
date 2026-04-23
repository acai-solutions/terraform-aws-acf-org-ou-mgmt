# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


variable "org_mgmt_reader_role_arn" {
  description = "ARN to be assumed by the Python, to read the OU structure. Only required, if the provisioning pipeline is not in the context of the Org-Mgmt account."
  type        = string
  default     = ""
}
