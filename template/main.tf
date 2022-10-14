
# *****************************************************************************
#  The XXXXXXXXXXXXXXX Subscription
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
    resource_group_name  = "<Resource Group Name>"            # Example "fgs01rgpcoreinfra"
    storage_account_name = "<Storage Account Name>"           # Example "fgs01strcoreinfra"
    container_name       = "<Storage Account Container Name>" # Example "fgs01cntcoreinfra"
    key                  = "<Terraform State File Name>"      # Example "fgs01_tf_bootstrap.tfstate"
  }
}

#**************************************
# Providers
#**************************************
provider "azurerm" {
  subscription_id = "<Subscription ID>" # Example "c9528965-5080-44c0-8752-e628e7ae25cf"
  features {}
}

provider "azurerm" {
  alias           = "splat"
  subscription_id = "8cfee6bc-4836-490b-a82a-c04504d7703d" # J.R. Simplot Prod
  features {}
}

#**************************************
# Local variables
#**************************************
locals {
  sub_id               = "<Subscription ID>"                                          # Example "c9528965-5080-44c0-8752-e628e7ae25cf"
  sub_name_prefix      = "<Prefix>"                                                   # Example "fgp01, fgn01, fgs01"
  sub_default_loc      = "<Location>"                                                 # Example "westus2"
  sub_vnet_dns_servers = ["10.200.0.132", "10.200.0.133", "10.10.4.10", "10.10.4.11"] # Simplot DNS Servers
  spn_ado              = "<ADO SPN>"                                                  # Example "ADO-SPLAT-Food-Group-Sandbox-01-Service-Connection"
  spn_splat            = "simplot-SPLAT-8cfee6bc-4836-490b-a82a-c04504d7703d"         # J.R. Simplot Prod ADO SPN
  aad_contribute       = "<Subscription AD Contributor Group>"                        # Example "Ent Azure Food Group Production 01 Subscription Contributor"
  aad_read             = "<Subscription AD Read Group>"                               # Example Ent Azure Food Group Production 01 Subscription Read"
  location_westus2     = "westus2"                                                    # West US 2 Region
  location_westus      = "westus"                                                     # West US Region
  sim_law_global       = "Simplot-Global-LAW"                                         # Global Log Analytics Workspace
  enable_locks         = true                                                         # Enable resource locking

  vnets = {
    "${local.sub_name_prefix}net${local.location_westus2}" = {
      vnet_cidr_location                     =  local.location_westus2
      vnet_cidr                              = ["<vNET CIDR>"]          # Example ["192.168.x.x/22"]
      vnet_peering                           = false                    # true to peer, false to not peer
      vnet_watcher                           = "${local.sub_name_prefix}wat${local.location_westus2}"
      peering_prod_vnet_name                 = "ussp1net01westus2"
      peering_prod_resource_group_name       = data.azurerm_virtual_network.net_jr_simplot_prod_westus2.resource_group_name
      peering_prod_virtual_network_name      = data.azurerm_virtual_network.net_jr_simplot_prod_westus2.name
      peering_this_resource_group_name       = data.azurerm_resource_group.rgp_coreinfra.name
      peering_this_remote_virtual_network_id = data.azurerm_virtual_network.net_jr_simplot_prod_westus2.id
      enable_locks                           = true
    }
    "${local.sub_name_prefix}net${local.location_westus}" = {
      vnet_cidr_location                     = local.location_westus
      vnet_cidr                              = ["<vNET CIDR>"]        # Example ["192.168.x.x/22"]
      vnet_peering                           = false                  # true to peer, false to not peer
      vnet_watcher                           = "${local.sub_name_prefix}wat${local.location_westus}"
      peering_prod_vnet_name                 = "ussp1net01coreinfra"
      peering_prod_resource_group_name       = data.azurerm_virtual_network.net_jr_simplot_prod_westus.resource_group_name
      peering_prod_virtual_network_name      = data.azurerm_virtual_network.net_jr_simplot_prod_westus.name
      peering_this_resource_group_name       = data.azurerm_resource_group.rgp_coreinfra.name
      peering_this_remote_virtual_network_id = data.azurerm_virtual_network.net_jr_simplot_prod_westus.id
      enable_locks                           = true
    }
  }

  keyvaults = {
    "${local.sub_name_prefix}keyvault" = {
      kv_location                 = local.location_westus2
      kv_resource_group_name      = azurerm_resource_group.rgp_keyvault.name
      kv_tenant_id                = data.azuread_client_config.simplot.tenant_id
      kv_sku_name                 = "standard"
      kv_purge_protection_enabled = false
      enable_locks                = true
    }
  }

  default_tags = {
    "description"        = "Core Infrastructure Resources",
    "billing_identifier" = "100129",
    "owner"              = "it.cloud.platform.engineering@simplot.com"
  }
}

#**************************************
# Data Lookups
#**************************************
data "azurerm_subscription" "current" {
  subscription_id = local.sub_id
}

# Client Config ---
data "azuread_client_config" "simplot" {}

# Resource Groups ---
data "azurerm_resource_group" "rgp_coreinfra" {
  name = "${local.sub_name_prefix}rgpcoreinfra"
}

data "azurerm_resource_group" "law_coreinfra" {
  provider = azurerm.splat
  name     = "Simplot-Global-LAW"
}

# Storage Accounts ---
data "azurerm_storage_account" "str_coreinfra" {
  name                = "${local.sub_name_prefix}strcoreinfra"
  resource_group_name = "${local.sub_name_prefix}rgpcoreinfra"
}

# SPN's ---
data "azuread_service_principal" "spn_splat" {
  display_name = local.spn_splat
}

data "azuread_service_principal" "spn_ado" {
  display_name = local.spn_ado
}

# AD Groups ---
data "azuread_group" "aad_contribute" {
  display_name     = local.aad_contribute
  security_enabled = true
}

data "azuread_group" "aad_read" {
  display_name     = local.aad_read
  security_enabled = true
}

# Remote Virtual Network ---
data "azurerm_virtual_network" "net_jr_simplot_prod_westus2" {
  provider            = azurerm.splat
  name                = "ussp1net01westus2"
  resource_group_name = "ussp1rgp01coreinfra"
}

data "azurerm_virtual_network" "net_jr_simplot_prod_westus" {
  provider            = azurerm.splat
  name                = "ussp1net01coreinfra"
  resource_group_name = "ussp1rgp01coreinfra"
}

# DNS Zones ---
data "azurerm_private_dns_zone" "privatelink-datafactory" {
  provider            = azurerm.splat
  name                = "privatelink.datafactory.azure.net"
  resource_group_name = "ussp1rgp01coreinfra"
}

data "azurerm_private_dns_zone" "privatelink-blob" {
  provider            = azurerm.splat
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "ussp1rgp01coreinfra"
}

data "azurerm_private_dns_zone" "privatelink-database" {
  provider            = azurerm.splat
  name                = "privatelink.database.windows.net"
  resource_group_name = "ussp1rgp01coreinfra"
}

data "azurerm_private_dns_zone" "privatelink-filecore" {
  provider            = azurerm.splat
  name                = "privatelink.file.core.windows.net"
  resource_group_name = "ussp1rgp01coreinfra"
}

# Log Analytics Workspace
data "azurerm_log_analytics_workspace" "global_law" {
  provider            = azurerm.splat
  name                = local.sim_law_global
  resource_group_name = data.azurerm_resource_group.law_coreinfra.name
}

#**************************************
# Core Infra Resource Group
#**************************************
resource "azurerm_management_lock" "rgp_coreinfra" {
  count      = local.enable_locks ? 1 : 0
  name       = "${local.sub_name_prefix}rgpcoreinfra"
  scope      = data.azurerm_resource_group.rgp_coreinfra.id
  lock_level = "CanNotDelete"
  notes      = "Locked to protect against deletion"
}

#**************************************
# Core Infra Storage Account
#**************************************
resource "azurerm_management_lock" "str_coreinfra" {
  count      = local.enable_locks ? 1 : 0
  name       = "${local.sub_name_prefix}strcoreinfra"
  scope      = data.azurerm_storage_account.str_coreinfra.id
  lock_level = "CanNotDelete"
  notes      = "Locked to protect against deletion"
}

#**************************************
# vNet
#**************************************
resource "azurerm_virtual_network" "vnets" {
  for_each            = local.vnets
  name                = each.key
  resource_group_name = data.azurerm_resource_group.rgp_coreinfra.name
  location            = each.value.vnet_cidr_location
  address_space       = each.value.vnet_cidr
  dns_servers         = each.value.vnet_peering == true ? local.sub_vnet_dns_servers : []

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
# vNet Peering
#**************************************
resource "azurerm_virtual_network_peering" "peering_prod_vnet" {
  for_each = {
    for k in keys(local.vnets) : k => local.vnets[k] if lookup(local.vnets[k], "vnet_peering", true)
  }

  provider                  = azurerm.splat
  name                      = "${each.value.peering_prod_vnet_name}_${azurerm_virtual_network.vnets[each.key].name}"
  resource_group_name       = each.value.peering_prod_resource_group_name
  virtual_network_name      = each.value.peering_prod_virtual_network_name
  remote_virtual_network_id = azurerm_virtual_network.vnets[each.key].id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "peering_this_vnet" {
  for_each = {
    for k in keys(local.vnets) : k => local.vnets[k] if lookup(local.vnets[k], "vnet_peering", true)
  }

  name                      = "${azurerm_virtual_network.vnets[each.key].name}_${each.value.peering_prod_vnet_name}"
  resource_group_name       = each.value.peering_this_resource_group_name
  virtual_network_name      = azurerm_virtual_network.vnets[each.key].name
  remote_virtual_network_id = each.value.peering_this_remote_virtual_network_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = true

  depends_on = [azurerm_virtual_network_peering.peering_prod_vnet]
}

#**************************************
# Netwatcher
#**************************************
resource "azurerm_network_watcher" "net_netwatcher" {
  for_each            = local.vnets
  name                = each.value.vnet_watcher
  location            = each.value.vnet_cidr_location
  resource_group_name = data.azurerm_resource_group.rgp_coreinfra.name

  tags = local.default_tags

  depends_on = [azurerm_virtual_network.vnets]
}

resource "azurerm_management_lock" "net_netwatcher" {
  for_each = { 
    for k, v in local.vnets : k => v if v.enable_locks
  }
  name       = each.key
  scope      = azurerm_network_watcher.net_netwatcher[each.key].id
  lock_level = "CanNotDelete"
  notes      = "Locked to protect against deletion"
}

#**************************************
# KeyVault Resource Group
#**************************************
resource "azurerm_resource_group" "rgp_keyvault" {
  name     = "${local.sub_name_prefix}rgpcerts"
  location = local.sub_default_loc

  tags = local.default_tags
}

resource "azurerm_management_lock" "rgp_keyvault" {
  count      = local.enable_locks ? 1 : 0
  name       = "${local.sub_name_prefix}rgpcerts"
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
  infrastructure_encryption_enabled = true

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
