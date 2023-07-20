// Management Group Settings
variable "deploy_policies" {
  type        = bool
  default     = false
  description = "set to true, this will deploy policies - set to false, it will only download the policies (default: false)"
}

// Main Settings
locals {
  management_group_config_file_name = "management_group.json"
  management_group_policy_file_name = "policies.json"
}

locals {
  folderstructure = [for folder in fileset(path.module, "**") : folder
  if(length(regexall("(\\.json)", folder)) > 0) && !startswith(folder, "policies/")]
  folders = distinct(flatten([for folder in local.folderstructure : join("/", slice(split("/", folder), 0, length(split("/", folder)) - 1))]))
}

// Policy Settings
locals {
  verbose = false
}

locals {
  folderstructure_policies = [for folder in fileset(path.module, "**") : folder
  if(length(regexall("(\\.json)", folder)) > 0)]
  folders_policies = distinct(flatten([for folder in local.folderstructure_policies : join("/", slice(split("/", folder), 0, length(split("/", folder)) - 1))]))
}