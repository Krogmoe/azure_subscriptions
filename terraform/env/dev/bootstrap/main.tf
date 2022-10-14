
# *****************************************************************************
#  The Krogmoe DEV Subscription - Boot Strap
# *****************************************************************************

terraform {
  required_version = "1.3.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.15.1"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.26.1"
    }
  }
}

#**************************************
# Providers
#**************************************
provider "azurerm" {
  subscription_id = "4dbb38b7-84ce-4b2d-b44f-20e94d38bed9"
  features {}
}

#**************************************
# Local variables
#**************************************
locals {
  sub_id               = "4dbb38b7-84ce-4b2d-b44f-20e94d38bed9"
  sub_name_prefix      = "krogdev01"
  sub_default_loc      = "westus2"
  enable_locks         = false

  keyvaults = {
    "${local.sub_name_prefix}keyvault" = {
      kv_location                 = local.sub_default_loc
      kv_resource_group_name      = azurerm_resource_group.rgp_keyvault.name
      kv_tenant_id                = data.azuread_client_config.krogmoe.tenant_id
      kv_sku_name                 = "standard"
      kv_purge_protection_enabled = false
      enable_locks                = false
    }
  }

  default_tags = {
    "description"        = "Core Infrastructure Resources",
    "billing_identifier" = "123456",
    "owner"              = "krogmoe@gmail.com"
  }
}

#**************************************
# Data Lookups
#**************************************
data "azurerm_subscription" "current" {
  subscription_id = local.sub_id
}

# Client Config ---
data "azuread_client_config" "krogmoe" {}

#**************************************
# KeyVault Resource Group
#**************************************
resource "azurerm_resource_group" "rgp_keyvault" {
  name     = "${local.sub_name_prefix}rgpkeyvaults"
  location = local.sub_default_loc

  tags = local.default_tags
}

resource "azurerm_management_lock" "rgp_keyvault" {
  count      = local.enable_locks ? 1 : 0
  name       = "${local.sub_name_prefix}rgpkeyvaults"
  scope      = azurerm_resource_group.rgp_keyvault.id
  lock_level = "CanNotDelete"
  notes      = "Locked to protect against deletion"
}

#**************************************
# KeyVault
#**************************************
resource "azurerm_key_vault" "key_certs" {
  for_each                 = local.keyvaults
  name                     = each.key
  location                 = each.value.kv_location
  resource_group_name      = each.value.kv_resource_group_name
  tenant_id                = each.value.kv_tenant_id
  sku_name                 = each.value.kv_sku_name
  purge_protection_enabled = each.value.kv_purge_protection_enabled

  tags = local.default_tags
}

resource "azurerm_management_lock" "key_certs" {
  for_each = { 
    for k, v in local.keyvaults : k => v if v.enable_locks
  }
  name       = each.key
  scope      = azurerm_key_vault.key_certs[each.key].id
  lock_level = "CanNotDelete"
  notes      = "Locked to protect against deletion"
}

#**************************************
# IAC Resource Group
#**************************************
resource "azurerm_resource_group" "rgp_iac" {
  name     = "${local.sub_name_prefix}rgpiac"
  location = local.sub_default_loc

  tags = local.default_tags
}

resource "azurerm_management_lock" "rgp_iac" {
  count      = local.enable_locks ? 1 : 0
  name       = "${local.sub_name_prefix}rgpiac"
  scope      = azurerm_resource_group.rgp_iac.id
  lock_level = "CanNotDelete"
  notes      = "Locked to protect against deletion"
}

#**************************************
# IAC Storage Account
#**************************************
resource "azurerm_storage_account" "str_iac" {
  name                              = "${local.sub_name_prefix}striac"
  resource_group_name               = azurerm_resource_group.rgp_iac.name
  location                          = azurerm_resource_group.rgp_iac.location
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  account_kind                      = "BlobStorage"
  min_tls_version                   = "TLS1_2"
  enable_https_traffic_only         = true
  shared_access_key_enabled         = true
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = false

  network_rules {
    default_action = "Allow" # "Deny" <-- This turns OFF Allow "All Networks"
    bypass         = ["Logging", "Metrics", "AzureServices"]
  }

  tags = local.default_tags
}

resource "azurerm_management_lock" "str_iac" {
  count      = local.enable_locks ? 1 : 0
  name       = "${local.sub_name_prefix}striac"
  scope      = azurerm_storage_account.str_iac.id
  lock_level = "CanNotDelete"
  notes      = "Locked to protect against deletion"
}

#**************************************
# IAC Storage Container
#**************************************
resource "azurerm_storage_container" "str_iac_cnt" {
  name                  = "${local.sub_name_prefix}cntiac"
  storage_account_name  = azurerm_storage_account.str_iac.name
  container_access_type = "private"

  # Not Taggable
  # Not Lockable
}
