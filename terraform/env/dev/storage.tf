
#**************************************
# Storage Account(s)
#**************************************
resource "azurerm_storage_account" "str" {
  for_each = {
    for k, v in local.storage_accounts : k => v if v.create
  }
  name                          = each.key
  resource_group_name           = each.value.resource_group_name
  location                      = each.value.storage_location
  account_tier                  = each.value.storage_account_tier
  account_replication_type      = each.value.storage_account_replication
  account_kind                  = each.value.storage_account_kind
  enable_https_traffic_only     = each.value.storage_https_only
  is_hns_enabled                = each.value.storage_hns_enabled
  nfsv3_enabled                 = each.value.storage_nfsv3_enabled
  min_tls_version               = each.value.storage_min_tls_version
  shared_access_key_enabled     = each.value.storage_shared_access_key_enabled
  # public_network_access_enabled = each.value.storage_allow_public_access

  tags = each.value.storage_resource_tags

  network_rules {
    default_action = "Allow" # <-- Setting this to "Deny" turns OFF Allow "All Networks"
    bypass         = ["Logging", "Metrics", "AzureServices"]
  }

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  depends_on = [azurerm_resource_group.rgp]
}

resource "azurerm_management_lock" "str" {
  for_each = { 
    for k, v in local.storage_accounts : k => v if v.enable_locks
  }
  name        = each.key
  scope       = azurerm_storage_account.str[each.key].id
  lock_level  = "CanNotDelete"
  notes       = "Locked to protect against deletion"

  depends_on = [azurerm_storage_account.str] # <--Try without this to see if "scope" provides the depend.
}

#**************************************
# Storage Account Container(s)
#**************************************
resource "azurerm_storage_container" "cnt" {
  for_each = {
    for k, v in local.storage_account_containers : k => v if v.create
  }
  name                  = each.key
  storage_account_name  = each.value.storage_account_name
  container_access_type = "private"

  depends_on = [azurerm_storage_account.str]
}
