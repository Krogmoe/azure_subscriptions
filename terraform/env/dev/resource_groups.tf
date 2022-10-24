
#**************************************
# Resource Group(s)
#**************************************
resource "azurerm_resource_group" "rgp" {
  for_each = {
    for k, v in local.resource_groups : k => v if v.create
  }
  name     = each.key
  location = each.value.rgp_location

  tags = local.default_tags
}

resource "azurerm_management_lock" "rgp" {
  for_each = {
    for k, v in local.resource_groups : k => v if v.enable_locks
  }
  name       = each.key
  scope      = azurerm_resource_group.rgp[each.key].id
  lock_level = "CanNotDelete"
  notes      = "Locked to protect against deletion"
}
