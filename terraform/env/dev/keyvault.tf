
#**************************************
# KeyVault
#**************************************
resource "azurerm_key_vault" "key" {
  for_each = {
    for k, v in local.keyvaults : k => v if v.create
  }
  name                     = each.key
  location                 = each.value.kv_location
  resource_group_name      = each.value.kv_resource_group_name
  tenant_id                = each.value.kv_tenant_id
  sku_name                 = each.value.kv_sku_name
  purge_protection_enabled = each.value.kv_purge_protection_enabled

  tags = local.default_tags
}

resource "azurerm_management_lock" "key" {
  for_each = {
    for k, v in local.keyvaults : k => v if v.enable_locks
  }
  name       = each.key
  scope      = azurerm_key_vault.key[each.key].id
  lock_level = "CanNotDelete"
  notes      = "Locked to protect against deletion"
}
