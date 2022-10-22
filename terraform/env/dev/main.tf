
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
  sub_id          = "4dbb38b7-84ce-4b2d-b44f-20e94d38bed9"
  sub_name_prefix = "krogdev01"
  sub_default_loc = "westus2"
  enable_locks    = false

  vnets = {
    "${local.sub_name_prefix}net${local.sub_default_loc}" = {
      vnet_cidr_location = local.sub_default_loc
      vnet_cidr          = ["192.168.0.0/22"]
      enable_locks       = false

    }
  }

  subnets = {
    "${local.sub_name_prefix}sub001" = {
      location                                       = local.sub_default_loc
      resource_group_name                            = data.azurerm_resource_group.rgp_iac.name
      vnet                                           = "${local.sub_name_prefix}net${local.sub_default_loc}"
      subnet                                         = ["192.168.0.0/24"]
      service_endpoints                              = []
      delegations                                    = []
      enforce_private_link_endpoint_network_policies = true
      rules = {
        https_in = {
          name                       = "https_ingress"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_address_prefix      = "0.0.0.0/0"
          source_port_range          = "*"
          destination_address_prefix = "0.0.0.0/0"
          destination_port_range     = "443"
        }
        https_out = {
          name                       = "https_egress"
          priority                   = 100
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_address_prefix      = "0.0.0.0/0"
          source_port_range          = "*"
          destination_address_prefix = "0.0.0.0/0"
          destination_port_range     = "443"
        }
      }
    }
    "${local.sub_name_prefix}sub002" = {
      location                                       = local.sub_default_loc
      resource_group_name                            = data.azurerm_resource_group.rgp_iac.name
      vnet                                           = "${local.sub_name_prefix}net${local.sub_default_loc}"
      subnet                                         = ["192.168.1.0/24"]
      service_endpoints                              = []
      delegations                                    = []
      enforce_private_link_endpoint_network_policies = true
      rules = {
        https_in = {
          name                       = "https_ingress"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_address_prefix      = "0.0.0.0/0"
          source_port_range          = "*"
          destination_address_prefix = "0.0.0.0/0"
          destination_port_range     = "443"
        }
        https_out = {
          name                       = "https_egress"
          priority                   = 100
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_address_prefix      = "0.0.0.0/0"
          source_port_range          = "*"
          destination_address_prefix = "0.0.0.0/0"
          destination_port_range     = "443"
        }
      }
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
# vNet(s)
#**************************************
resource "azurerm_virtual_network" "vnets" {
  for_each            = local.vnets
  name                = each.key
  resource_group_name = data.azurerm_resource_group.rgp_iac.name
  location            = each.value.vnet_cidr_location
  address_space       = each.value.vnet_cidr

  tags = local.default_tags
}

#**************************************
# Subnet(s)
#**************************************
resource "azurerm_subnet" "subnets" {
  for_each                                       = local.subnets
  name                                           = each.key
  resource_group_name                            = each.value.resource_group_name
  virtual_network_name                           = each.value.vnet
  address_prefixes                               = each.value.subnet
  service_endpoints                              = each.value.service_endpoints
  enforce_private_link_endpoint_network_policies = each.value.enforce_private_link_endpoint_network_policies

  dynamic "delegation" {
    for_each = each.value.delegations

    content {
      name = delegation.value.name

      dynamic "service_delegation" {
        for_each = delegation.value.services

        content {
          name    = service_delegation.value.name
          actions = service_delegation.value.actions
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [delegation]
  }

  depends_on = [azurerm_virtual_network.vnets]
}

#**************************************
# KeyVault Resource Group
#**************************************
resource "azurerm_resource_group" "rgp_keyvault" {
  name     = "${local.sub_name_prefix}rgpkeyvaults"
  location = local.sub_default_loc

  tags = local.default_tags
}

# resource "azurerm_management_lock" "rgp_keyvault" {
#   count      = local.enable_locks ? 1 : 0
#   name       = "${local.sub_name_prefix}rgpkeyvaults"
#   scope      = azurerm_resource_group.rgp_keyvault.id
#   lock_level = "CanNotDelete"
#   notes      = "Locked to protect against deletion"
# }

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

# resource "azurerm_management_lock" "key_certs" {
#   for_each = { 
#     for k, v in local.keyvaults : k => v if v.enable_locks
#   }
#   name       = each.key
#   scope      = azurerm_key_vault.key_certs[each.key].id
#   lock_level = "CanNotDelete"
#   notes      = "Locked to protect against deletion"
# }
