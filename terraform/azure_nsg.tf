
# Not updating NSG rules so we don't override other rules.
resource "azurerm_network_security_group" "nsg" {
  for_each            = local.azure_config.networkSecurityGroups
  name                = each.key
  location            = local.azure_config.location
  resource_group_name = local.azure_config.resourceGroup

  dynamic "security_rule" {
    for_each = each.value.rules
    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destinationPortRange
      source_address_prefixes    = concat(security_rule.value.sourceAddressPrefixes, local.aws_config.admin_cidr_list)
      destination_address_prefix = "*"
    }
  }

  lifecycle {
    ignore_changes = [ security_rule ]
  }
}

resource "azurerm_network_interface_security_group_association" "baseline" {
  for_each                  = { for k, v in merge(local.azure_config.linuxVMs, local.azure_config.windowsVMs) : k => v if v.nsg != "" }
  network_interface_id      = azurerm_network_interface.vminterfaces[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value["nsg"]].id
}

resource "azurerm_subnet_network_security_group_association" "baseline_subnet" {
  for_each = {
    for subnet in local.vnet_subnets : "${subnet.vnet_name}.${subnet.subnet_key}" => subnet if subnet.nsg != ""
  }
  subnet_id = azurerm_subnet.db_subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value["nsg"]].id
}


resource "azurerm_storage_account" "storage" {
  for_each            = { for k, v in local.azure_config.networkSecurityGroups : k => v if v.logFlows }
  name                = replace(replace("${local.azure_config.resourceGroup}-${each.key}", "-", ""), "_", "")
  resource_group_name = local.azure_config.resourceGroup
  location            = local.azure_config.location

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
}

resource "azurerm_network_watcher_flow_log" "nw_flog" {
  for_each             = { for k, v in local.azure_config.networkSecurityGroups : k => v if v.logFlows }
  network_watcher_name = "NetworkWatcher_eastus" # make this dynamic
  resource_group_name  = "NetworkWatcherRG"
  name                 = each.key

  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
  storage_account_id        = azurerm_storage_account.storage[each.key].id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = 7
  }
}
