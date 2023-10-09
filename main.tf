// Main Settings
locals {
  management_group_config_file_name = "management_group.json"
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
  // Management Group Settings
  mgmt_grp_layer0_settings          = { for folder in [for layers in local.folders : layers if length(split("/", layers)) == 1] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_config_file_name}")), {}) }
  mgmt_grp_layer1_settings          = { for folder in [for layers in local.folders : layers if length(split("/", layers)) == 2] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_config_file_name}")), {}) }
  mgmt_grp_layer2_settings          = { for folder in [for layers in local.folders : layers if length(split("/", layers)) == 3] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_config_file_name}")), {}) }
  mgmt_grp_layer3_settings          = { for folder in [for layers in local.folders : layers if length(split("/", layers)) == 4] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_config_file_name}")), {}) }
  mgmt_grp_layer4_settings          = { for folder in [for layers in local.folders : layers if length(split("/", layers)) == 5] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_config_file_name}")), {}) }
  mgmt_grp_layer5_settings          = { for folder in [for layers in local.folders : layers if length(split("/", layers)) == 6] : folder => try(jsondecode(file("${path.module}/${folder}/${local.management_group_config_file_name}")), {}) }
}

locals {
  layer0_existing      = [for management_group in local.mgmt_grp_layer0_settings : management_group.name if contains(keys(management_group), "existing") && management_group.existing == true]
  layer0_create_parent = { for management_group in local.mgmt_grp_layer0_settings : management_group.name => management_group.parent if contains(keys(management_group), "parent") && !contains(local.layer0_existing, management_group.name) }
  layer0_create        = [for management_group in local.mgmt_grp_layer0_settings : management_group.name if !contains(keys(management_group), "parent") && !contains(local.layer0_existing, management_group.name)]
}

// Lookup existing management groups
data "azurerm_management_group" "layer0_existing" {
  for_each = { for management_group in local.layer0_existing : management_group => management_group }
  name     = each.key
}

// Create new management groups
resource "azurerm_management_group" "layer0_create_parent" {
  for_each                   = local.layer0_create_parent
  name                       = each.key
  display_name               = each.key
  parent_management_group_id = data.azurerm_management_group.layer0_existing[each.value].id
}

resource "azurerm_management_group" "layer0_create" {
  for_each     = { for management_group in local.layer0_create : management_group => management_group }
  name         = each.key
  display_name = each.key
}

// Merge management group information
locals {
  layer0 = merge(data.azurerm_management_group.layer0_existing, azurerm_management_group.layer0_create_parent, azurerm_management_group.layer0_create)
}


output "layer1_settings" {
  value = local.mgmt_grp_layer1_settings
}

resource "azurerm_management_group" "layer1" {
  for_each                   = local.mgmt_grp_layer1_settings
  display_name               = each.value.name
  name                       = each.value.name
  parent_management_group_id = local.layer0[each.value.parent].id
  depends_on                 = [azurerm_management_group.layer0_create_parent, azurerm_management_group.layer0_create]
}

resource "azurerm_management_group" "layer2" {
  for_each                   = local.mgmt_grp_layer2_settings
  display_name               = each.value.name
  name                       = each.value.name
  parent_management_group_id = azurerm_management_group.layer1["${[for layer2parent in local.mgmt_grp_layer2_settings : "${[for layer1parent in local.mgmt_grp_layer1_settings : layer1parent.parent if layer1parent.name == layer2parent.parent][0]}/${layer2parent.parent}" if layer2parent.name == each.value.name][0]}"].id
  depends_on                 = [azurerm_management_group.layer1]
}

resource "azurerm_management_group" "layer3" {
  for_each                   = local.mgmt_grp_layer3_settings
  display_name               = each.value.name
  name                       = each.value.name
  parent_management_group_id = azurerm_management_group.layer2["${[for layer3parent in local.mgmt_grp_layer3_settings : "${[for layer2parent in local.mgmt_grp_layer2_settings : "${[for layer1parent in local.mgmt_grp_layer1_settings : layer1parent.parent if layer1parent.name == layer2parent.parent][0]}/${layer2parent.parent}" if layer2parent.name == layer3parent.parent][0]}/${layer3parent.parent}" if layer3parent.name == each.value.name][0]}"].id
  depends_on                 = [azurerm_management_group.layer2]
}

//Uncomment if a layer 4 management group is added to the file structure
/*
  resource "azurerm_management_group" "layer4" {
  for_each = local.mgmt_grp_layer4_settings
  display_name = each.value.name
  name = each.value.name
  parent_management_group_id = azurerm_management_group.layer3["${[for layer4parent in local.mgmt_grp_layer4_settings : "${[for layer3parent in local.mgmt_grp_layer3_settings : "${[for layer2parent in local.mgmt_grp_layer2_settings : "${[for layer1parent in local.mgmt_grp_layer1_settings : layer1parent.parent if layer1parent.name == layer2parent.parent][0]}/${layer2parent.parent}" if layer2parent.name == layer3parent.parent][0]}/${layer3parent.parent}" if layer3parent.name == layer4parent.parent][0]}/${layer4parent.parent}" if layer4parent.name == each.value.name][0]}"].id
  depends_on = [ azurerm_management_group.layer3 ]
}
*/

//Uncomment if a layer 5 management group is added to the file structure
/*
resource "azurerm_management_group" "layer5" {
  for_each = local.mgmt_grp_layer5_settings
  display_name = each.value.name
  name = each.value.name
  parent_management_group_id = azurerm_management_group.layer4["${[for layer5parent in local.mgmt_grp_layer5_settings : "${[for layer4parent in local.mgmt_grp_layer4_settings : "${[for layer3parent in local.mgmt_grp_layer3_settings : "${[for layer2parent in local.mgmt_grp_layer2_settings : "${[for layer1parent in local.mgmt_grp_layer1_settings : layer1parent.parent if layer1parent.name == layer2parent.parent][0]}/${layer2parent.parent}" if layer2parent.name == layer3parent.parent][0]}/${layer3parent.parent}" if layer3parent.name == layer4parent.parent][0]}/${layer4parent.parent}" if layer4parent.name == layer5parent.parent][0]}/${layer5parent.parent}" if layer5parent.name == each.value.name][0]}"].id
  depends_on = [ azurerm_management_group.layer4 ]
} */
