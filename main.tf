locals {
    folderstructure = [ for folder in fileset(path.module, "**") : folder 
    if (length(regexall("(\\.json)", folder)) > 0)]

    folders = distinct(flatten([for folder in local.folderstructure : join("/", slice(split("/", folder), 0, length(split("/", folder))-1))]))
}

locals {
    // Management Group Settings
    management_group_config_file_name = "management_group.json"
    mgmt_grp_layer0_settings = {for folder in [for layers in local.folders : layers  if length(split("/", layers)) == 1] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_config_file_name}")), {})}
    mgmt_grp_layer1_settings = {for folder in [for layers in local.folders : layers  if length(split("/", layers)) == 2] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_config_file_name}")), {})}
    mgmt_grp_layer2_settings = {for folder in [for layers in local.folders : layers  if length(split("/", layers)) == 3] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_config_file_name}")), {})}
    mgmt_grp_layer3_settings = {for folder in [for layers in local.folders : layers  if length(split("/", layers)) == 4] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_config_file_name}")), {})}
    mgmt_grp_layer4_settings = {for folder in [for layers in local.folders : layers  if length(split("/", layers)) == 5] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_config_file_name}")), {})}
    mgmt_grp_layer5_settings = {for folder in [for layers in local.folders : layers  if length(split("/", layers)) == 6] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_config_file_name}")), {})}
}

locals {
  layer0_parent = distinct([for parents in local.mgmt_grp_layer0_settings : parents.parent if contains(keys(parents), "parent")])
  mgmt_layer0_parent_config = {for settings in local.mgmt_grp_layer0_settings : settings.name => settings.parent if contains(keys(settings), "parent")}
}

output "test" {
  value = local.layer0_parent
}


data "azurerm_management_group" "parent_layer0" {
  //for_each = {for parents in distinct([for parents in local.mgmt_grp_layer0_settings : parents.parent if contains(keys(parents), "parent")]) : parents => parents}
  for_each = local.mgmt_layer0_parent_config
  name = each.value
}


resource "azurerm_management_group" "layer0_parent" {
  for_each = local.mgmt_layer0_parent_config
  name     = each.key
  display_name = each.key
  parent_management_group_id = data.azurerm_management_group.parent_layer0[each.value].id
}

resource "azurerm_management_group" "layer0_no_parent" {
  for_each = local.mgmt_grp_layer0_settings
  display_name = each.value.name
  name = each.value.name
}

data "azurerm_management_group" "layer1" {
  for_each = local.mgmt_grp_layer1_settings
  name = each.value.parent
}

resource "azurerm_management_group" "layer1" {
  for_each = local.mgmt_grp_layer1_settings
  display_name = each.value.name
  name = each.value.name
  parent_management_group_id = data.azurerm_management_group.layer1[each.value.parent].id
  depends_on = [ azurerm_management_group.layer0_no_parent, azurerm_management_group.layer0_parent ]
}
