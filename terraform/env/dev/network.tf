
#**************************************
# vNet(s)
#**************************************
resource "azurerm_virtual_network" "net" {
  for_each = {
    for k, v in local.vnets : k => v if v.create
  }
  name                = each.key
  resource_group_name = data.azurerm_resource_group.rgp_iac.name
  location            = each.value.vnet_cidr_location
  address_space       = each.value.vnet_cidr

  tags = local.default_tags
}

resource "azurerm_management_lock" "net" {
  for_each = {
    for k, v in local.vnets : k => v if v.enable_locks
  }
  name       = each.key
  scope      = azurerm_virtual_network.net[each.key].id
  lock_level = "CanNotDelete"
  notes      = "Locked to protect against deletion"
}

#**************************************
# Subnet(s)
#**************************************
resource "azurerm_subnet" "sub" {
  for_each = {
    for k, v in local.subnets : k => v if v.create
  }
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

  depends_on = [azurerm_virtual_network.net]
}

resource "azurerm_management_lock" "sub" {
  for_each = {
    for k, v in local.subnets : k => v if v.enable_locks
  }
  name       = each.key
  scope      = azurerm_subnet.sub[each.key].id
  lock_level = "CanNotDelete"
  notes      = "Locked to protect against deletion"
}
