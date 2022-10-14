
# *****************************************************************************
#  The Krogmoe DEV Subscription
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

  backend "azurerm" {
    resource_group_name  = "krogdev01rgpiac"
    storage_account_name = "krogdev01striac"
    container_name       = "krogdev01cntiac"
    key                  = "krogdev01.tfstate"
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

  vnets = {
    "${local.sub_name_prefix}net${local.sub_default_loc}" = {
      vnet_cidr_location                     =  local.sub_default_loc
      vnet_cidr                              = ["192.168.0.0/23"]
      enable_locks                           = false
    }
  }

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

# Resource Groups ---
data "azurerm_resource_group" "rgp_iac" {
  name = "${local.sub_name_prefix}rgpiac"
}

# Storage Accounts ---
data "azurerm_storage_account" "str_coreinfra" {
  name                = "${local.sub_name_prefix}striac"
  resource_group_name = "${local.sub_name_prefix}rgpiac"
}

#**************************************
# vNet
#**************************************
resource "azurerm_virtual_network" "vnets" {
  for_each            = local.vnets
  name                = each.key
  resource_group_name = data.azurerm_resource_group.rgp_iac.name
  location            = each.value.vnet_cidr_location
  address_space       = each.value.vnet_cidr

  tags = local.default_tags
}

resource "azurerm_management_lock" "vnets" {
  for_each = { 
    for k, v in local.vnets : k => v if v.enable_locks
  }
  name       = each.key
  scope      = azurerm_virtual_network.vnets[each.key].id
  lock_level = "CanNotDelete"
  notes      = "Locked to protect against deletion"
}

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
