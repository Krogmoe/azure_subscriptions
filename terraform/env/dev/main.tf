
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
      create             = true
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
      create                                         = true
      enable_locks                                   = false
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
      create                                         = true
      enable_locks                                   = false
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
    "${local.sub_name_prefix}keyvault1" = {
      kv_location                 = local.sub_default_loc
      kv_resource_group_name      = "${local.sub_name_prefix}rgpkeyvaults"
      kv_tenant_id                = data.azuread_client_config.krogmoe.tenant_id
      kv_sku_name                 = "standard"
      kv_purge_protection_enabled = false
      create                      = true
      enable_locks                = false
    }
    "${local.sub_name_prefix}keyvault2" = {
      kv_location                 = local.sub_default_loc
      kv_resource_group_name      = "${local.sub_name_prefix}rgpkeyvaults"
      kv_tenant_id                = data.azuread_client_config.krogmoe.tenant_id
      kv_sku_name                 = "standard"
      kv_purge_protection_enabled = false
      create                      = true
      enable_locks                = false
    }
  }

  storage_accounts = {
    "${local.sub_name_prefix}straccount1" = {
      resource_group_name               = "${local.sub_name_prefix}rgpstoraccts"
      storage_location                  = local.sub_default_loc
      storage_description               = "Storage Account 1"
      storage_account_tier              = "Standard"
      storage_account_replication       = "LRS"
      storage_account_kind              = "BlobStorage"
      storage_https_only                = true
      storage_hns_enabled               = true
      storage_nfsv3_enabled             = false
      storage_min_tls_version           = "TLS1_2"
      storage_shared_access_key_enabled = true
      storage_allow_public_access       = true
      storage_resource_tags             = local.default_tags
      create                            = true
      enable_locks                      = false
    }
    "${local.sub_name_prefix}straccount2" = {
      resource_group_name               = "${local.sub_name_prefix}rgpstoraccts"
      storage_location                  = local.sub_default_loc
      storage_description               = "Storage Account 2"
      storage_account_tier              = "Standard"
      storage_account_replication       = "LRS"
      storage_account_kind              = "BlobStorage"
      storage_https_only                = true
      storage_hns_enabled               = true
      storage_nfsv3_enabled             = false
      storage_min_tls_version           = "TLS1_2"
      storage_shared_access_key_enabled = true
      storage_allow_public_access       = true
      storage_resource_tags             = local.default_tags
      create                            = true
      enable_locks                      = false
    }
  }

  storage_account_containers = {
    "${local.sub_name_prefix}cntaccount1" = {
      storage_account_name  = "${local.sub_name_prefix}straccount1"
      create = true
    }
    "${local.sub_name_prefix}cntaccount2" = {
      storage_account_name  = "${local.sub_name_prefix}straccount2"
      create = true
    }
  }

  resource_groups = {
    "${local.sub_name_prefix}rgpkeyvaults" = {
      rgp_location = local.sub_default_loc
      create       = true
      enable_locks = false
    }
    "${local.sub_name_prefix}rgpstoraccts" = {
      rgp_location = local.sub_default_loc
      create       = true
      enable_locks = false
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
# Base IAC - Process Starts Here.....
#**************************************
module "base" {
  source = "../../../modules/base"
}
