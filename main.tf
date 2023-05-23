locals {
    folderstructure = [ for folder in fileset(path.module, "**") : folder 
    if (length(regexall("(\\.json)", folder)) > 0)]

    folders = distinct(flatten([for folder in local.folderstructure : join("/", slice(split("/", folder), 0, length(split("/", folder))-1))]))
}

locals {
    layer0 = distinct(flatten([for layer1 in local.folders : try(split("/", layer1)[0], [])]))
    layer1 = distinct(flatten([for layer1 in local.folders : try(split("/", layer1)[1], [])]))
    layer2 = distinct(flatten([for layer1 in local.folders : try(split("/", layer1)[2], [])]))
    layer3 = distinct(flatten([for layer1 in local.folders : try(split("/", layer1)[3], [])]))
    layer4 = distinct(flatten([for layer1 in local.folders : try(split("/", layer1)[4], [])]))
    layer5 = distinct(flatten([for layer1 in local.folders : try(split("/", layer1)[5], [])]))
}
/*
output "folderstructure" {
  value = local.folderstructure
}

output "folders" {
  value = local.folders
} 

output "layer0" {
  value = local.layer0
}


output "layer1" {
  value = local.layer1
}

output "layer2" {
  value = local.layer2
}

output "layer3" {
  value = local.layer3
}
output "layer4" {
  value = local.layer4
}

output "layer5" {
  value = local.layer5
}
*/

// Management Group
/*
resource "azurerm_management_group" "management_group" {
  for_each = { for layer0 in local.layer0 : layer0 => layer0 }
  name     = each.value
  display_name = each.value
  parent_management_group_id = var.parent_management_group_id
}
*/

//for_each = { for layer0 in local.layer0 : layer0 => layer0 }
locals {
  layer0_setting = jsondecode(file("${each.value}management_group.json"))
}

resource "azurerm_management_group" "management_group" {
  for_each = local.layer0_setting
  name = each.name
}