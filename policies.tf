locals {
  // Management Group Settings
  mgmt_grp_layer0_policies          = { for folder in [for layers in local.folders_policies : layers if length(split("/", layers)) == 1] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_policy_file_name}")), {}) }
  mgmt_grp_layer1_policies          = { for folder in [for layers in local.folders_policies : layers if length(split("/", layers)) == 2] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_policy_file_name}")), {}) }
  mgmt_grp_layer2_policies          = { for folder in [for layers in local.folders_policies : layers if length(split("/", layers)) == 3] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_policy_file_name}")), {}) }
  mgmt_grp_layer3_policies          = { for folder in [for layers in local.folders_policies : layers if length(split("/", layers)) == 4] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_policy_file_name}")), {}) }
  mgmt_grp_layer4_policies          = { for folder in [for layers in local.folders_policies : layers if length(split("/", layers)) == 5] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_policy_file_name}")), {}) }
  mgmt_grp_layer5_policies          = { for folder in [for layers in local.folders_policies : layers if length(split("/", layers)) == 6] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_policy_file_name}")), {}) }
  
  // Test to iterate only over the first two layers
  unfiltered_mgmt_grp_policies = merge(local.mgmt_grp_layer0_policies, local.mgmt_grp_layer1_policies, local.mgmt_grp_layer2_policies, local.mgmt_grp_layer3_policies, local.mgmt_grp_layer4_policies, local.mgmt_grp_layer5_policies)
  // Filter the policies (remove empty entries in map)
  mgmt_grp_policies_temp = {
    for mgmt_grp, policydata in local.unfiltered_mgmt_grp_policies : mgmt_grp => {
      for policy_name, policy_information in policydata :
      policy_name => policy_information
    if try(policy_information.project_name, false) != false }
  if length(policydata) > 0 }

  existing_mgmt_grp_policies_temp = {
    for mgmt_grp, policydata in local.unfiltered_mgmt_grp_policies : mgmt_grp => {
      for policy_name, policy_information in policydata :
      policy_name => policy_information
      if try(policy_information.project_name, false) == false &&
    try(policy_information.policy_definition_id, false) == false }
  if length(policydata) > 0 }

  mgmt_grp_policies_builtIn_temp = {
    for mgmt_grp, policydata in local.unfiltered_mgmt_grp_policies : mgmt_grp => {
      for policy_name, policy_information in policydata :
      policy_name => policy_information
      if try(policy_information.project_name, false) == false &&
    try(policy_information.policy_definition_id, false) != false }
  if length(policydata) > 0 }

  // Flatten the map to better work with data
  mgmt_grp_policies = merge([
    for mgmt_grp, policydata in local.mgmt_grp_policies_temp :
    { for policy_information in policydata :
      "${mgmt_grp}/${policy_information.policy_name}" => policy_information
    } if length(policydata) > 0
  ]...)
  existing_mgmt_grp_policies = merge([
    for mgmt_grp, policydata in local.existing_mgmt_grp_policies_temp :
    { for policy_information in policydata :
      "${mgmt_grp}/${policy_information.policy_name}" => policy_information
    } if length(policydata) > 0
  ]...)
  mgmt_grp_policies_builtIn = merge([
    for mgmt_grp, policydata in local.mgmt_grp_policies_builtIn_temp :
    { for policy_information in policydata :
      "${mgmt_grp}/${policy_information.policy_name}" => policy_information
    } if length(policydata) > 0
  ]...)

}

output "mgmt_grp_policies" {
  value = local.verbose ? local.mgmt_grp_policies : null
}

output "existing_mgmt_group_policies" {
  value = local.verbose ? local.existing_mgmt_grp_policies : null
}
output "mgmt_grp_policies_builtIn" {
  value = local.verbose ? local.mgmt_grp_policies_builtIn : null
}

// Gather project data from Azure DevOps
data "azuredevops_project" "project" {
  for_each = local.mgmt_grp_policies
  name     = each.value.project_name
}

output "project" {
  value = local.verbose ? data.azuredevops_project.project : null
}

// Gather repository data from Azure DevOps
data "azuredevops_git_repository" "repo" {
  for_each   = local.mgmt_grp_policies
  project_id = data.azuredevops_project.project[each.key].id
  name       = each.value.repo_name
}

output "repo" {
  value = local.verbose ? data.azuredevops_git_repository.repo : null
}

// Triggers below commands all the time (Due to missing feature of Azure DevOps data provider, to detect changed size of repos)
resource "random_string" "trigger" {
  keepers = {
    timestamp = timestamp()
  }
  length  = 5
  special = false
}

// Detect the operating system
locals {
  is_linux = length(regexall("/home/", lower(abspath(path.root)))) > 0
}

output "is_linux" {
  value = local.is_linux
}

// Delete the file in case the it exists (to force refreshs)
resource "null_resource" "remove_cloned_directory" {
  for_each = local.mgmt_grp_policies

  triggers = {
    string = random_string.trigger.result
  }

  provisioner "local-exec" {
    command = (
      fileexists("${path.module}/policies/${each.key}/${each.value.policy_filename}") ?
      local.is_linux ?
      "rm -rf ${each.value.policy_filename}" :
      "rmdir /s /q ${each.value.policy_filename}":
      local.is_linux ? 
      "echo 'Nothing to remove: ${each.value.policy_filename}'" : 
      "echo Nothing to remove: ${each.value.policy_filename}"
      

    )
  }
  depends_on = [random_string.trigger]
}


// Clone the repo
resource "null_resource" "git_clone" {
  for_each = local.mgmt_grp_policies

  triggers = {
    string = random_string.trigger.result
  }

  provisioner "local-exec" {
    command = (
      "git clone ${replace(data.azuredevops_git_repository.repo[each.key].web_url, "https://", "https://${local.git_pat}@")} ${path.module}/policies/${each.key}"
    )
  }

  depends_on = [
    data.azuredevops_git_repository.repo,
    random_string.trigger,
    null_resource.remove_cloned_directory
  ]
}

//merge the mgmt_grp_policies and existing_mgmt_grp_policies to one map
locals {
  all_mgmt_grp_policies = merge(local.mgmt_grp_policies, local.existing_mgmt_grp_policies)
}

output "all_mgmt_grp_policies" {
  value = local.verbose ? local.all_mgmt_grp_policies : null
}

//Deploy custom policy defintions
// only if variable deploy_custom_policies is set to true
resource "azurerm_policy_definition" "existing_defintions" {
  for_each            = var.deploy_policies ? local.existing_mgmt_grp_policies : {}
  name                = jsondecode(file("${path.module}/policies/${each.key}.json"))["name"]
  display_name        = jsondecode(file("${path.module}/policies/${each.key}.json"))["properties"]["displayName"]
  description         = jsondecode(file("${path.module}/policies/${each.key}.json"))["properties"]["description"]
  policy_type         = jsondecode(file("${path.module}/policies/${each.key}.json"))["properties"]["policyType"]
  mode                = jsondecode(file("${path.module}/policies/${each.key}.json"))["properties"]["mode"]
  policy_rule         = jsonencode(jsondecode(file("${path.module}/policies/${each.key}.json"))["properties"]["policyRule"])
  management_group_id = "/providers/Microsoft.Management/managementGroups/${split("/", each.key)[length(split("/", each.key)) - 2]}"
}

resource "azurerm_policy_definition" "git_defintions" {
  for_each            = var.deploy_policies ? local.mgmt_grp_policies : {}
  name                = jsondecode(file("${path.module}/policies/${each.key}/${each.value.policy_filename}"))["name"]
  display_name        = jsondecode(file("${path.module}/policies/${each.key}/{each.value.policy_filename}"))["properties"]["displayName"]
  description         = jsondecode(file("${path.module}/policies/${each.key}/{each.value.policy_filename}"))["properties"]["description"]
  policy_type         = jsondecode(file("${path.module}/policies/${each.key}/{each.value.policy_filename}"))["properties"]["policyType"]
  mode                = jsondecode(file("${path.module}/policies/${each.key}/${each.value.policy_filename}"))["properties"]["mode"]
  policy_rule         = jsonencode(jsondecode(file("${path.module}/policies/${each.key}/${each.value.policy_filename}"))["properties"]["policyRule"])
  management_group_id = "/providers/Microsoft.Management/managementGroups/${split("/", each.key)[length(split("/", each.key)) - 2]}"
  depends_on          = [null_resource.remove_cloned_directory, null_resource.git_clone]
}

resource "azurerm_management_group_policy_assignment" "assigments_custom_existing" {
  for_each             = var.deploy_policies ? local.existing_mgmt_grp_policies : {}
  name                 = each.value.assignment_name
  policy_definition_id = azurerm_policy_definition.existing_defintions[each.key].id
  management_group_id  = "/providers/Microsoft.Management/managementGroups/${split("/", each.key)[length(split("/", each.key)) - 2]}"
  depends_on           = [azurerm_policy_definition.existing_defintions]
}

resource "azurerm_management_group_policy_assignment" "assigments_custom_git" {
  for_each             = var.deploy_policies ? local.mgmt_grp_policies : {}
  name                 = each.value.assignment_name
  policy_definition_id = azurerm_policy_definition.git_defintions[each.key].id
  management_group_id  = "/providers/Microsoft.Management/managementGroups/${split("/", each.key)[length(split("/", each.key)) - 2]}"
  depends_on           = [azurerm_policy_definition.git_defintions]
}

resource "azurerm_management_group_policy_assignment" "assigment_built_in" {
  for_each             = var.deploy_policies ? local.mgmt_grp_policies_builtIn : {}
  name                 = each.value.assignment_name
  policy_definition_id = each.value.policy_definition_id
  management_group_id  = "/providers/Microsoft.Management/managementGroups/${split("/", each.key)[length(split("/", each.key)) - 2]}"
}
