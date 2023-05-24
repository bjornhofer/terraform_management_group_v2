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

data "azurerm_management_group" "parent_layer0" {
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

resource "azurerm_management_group" "layer1" {
  for_each = local.mgmt_grp_layer1_settings
  display_name = each.value.name
  name = each.value.name
  parent_management_group_id = length(local.layer0_parent) > 0 ? azurerm_management_group.layer0_parent[each.value.parent].id : azurerm_management_group.layer0_no_parent[each.value.parent].id
  depends_on = [ azurerm_management_group.layer0_no_parent, azurerm_management_group.layer0_parent ]
}

resource "azurerm_management_group" "layer2" {
  for_each = local.mgmt_grp_layer2_settings
  display_name = each.value.name
  name = each.value.name
  parent_management_group_id = azurerm_management_group.layer1["${[for layer2parent in local.mgmt_grp_layer2_settings : "${[for layer1parent in local.mgmt_grp_layer1_settings : layer1parent.parent if layer1parent.name == layer2parent.parent][0]}/${layer2parent.parent}" if layer2parent.name == each.value.name][0]}"].id
}

resource "azurerm_management_group" "layer3" {
  for_each = local.mgmt_grp_layer3_settings
  display_name = each.value.name
  name = each.value.name
  parent_management_group_id = azurerm_management_group.layer2["${[for layer3parent in local.mgmt_grp_layer3_settings : "${[for layer2parent in local.mgmt_grp_layer2_settings : "${[for layer1parent in local.mgmt_grp_layer1_settings : layer1parent.parent if layer1parent.name == layer2parent.parent][0]}/${layer2parent.parent}" if layer2parent.name == layer3parent.parent][0]}/${layer3parent.parent}" if layer3parent.name == each.value.name][0]}"].id
  depends_on = [ azurerm_management_group.layer2 ]
}

resource "azurerm_management_group" "layer4" {
  for_each = local.mgmt_grp_layer4_settings
  display_name = each.value.name
  name = each.value.name
  parent_management_group_id = azurerm_management_group.layer3["${[for layer4parent in local.mgmt_grp_layer4_settings : "${[for layer3parent in local.mgmt_grp_layer3_settings : "${[for layer2parent in local.mgmt_grp_layer2_settings : "${[for layer1parent in local.mgmt_grp_layer1_settings : layer1parent.parent if layer1parent.name == layer2parent.parent][0]}/${layer2parent.parent}" if layer2parent.name == layer3parent.parent][0]}/${layer3parent.parent}" if layer3parent.name == layer4parent.parent][0]}/${layer4parent.parent}" if layer4parent.name == each.value.name][0]}"].id
  depends_on = [ azurerm_management_group.layer3 ]
}

resource "azurerm_management_group" "layer5" {
  for_each = local.mgmt_grp_layer5_settings
  display_name = each.value.name
  name = each.value.name
  parent_management_group_id = azurerm_management_group.layer4["${[for layer5parent in local.mgmt_grp_layer5_settings : "${[for layer4parent in local.mgmt_grp_layer4_settings : "${[for layer3parent in local.mgmt_grp_layer3_settings : "${[for layer2parent in local.mgmt_grp_layer2_settings : "${[for layer1parent in local.mgmt_grp_layer1_settings : layer1parent.parent if layer1parent.name == layer2parent.parent][0]}/${layer2parent.parent}" if layer2parent.name == layer3parent.parent][0]}/${layer3parent.parent}" if layer3parent.name == layer4parent.parent][0]}/${layer4parent.parent}" if layer4parent.name == layer5parent.parent][0]}/${layer5parent.parent}" if layer5parent.name == each.value.name][0]}"].id
  depends_on = [ azurerm_management_group.layer4 ]
}
