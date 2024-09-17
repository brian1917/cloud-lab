
resource "azurerm_local_network_gateway" "lng-aws-azure" {
  for_each            = local.azure_config.vpnConnections
  name                = each.key
  resource_group_name = local.azure_config.resourceGroup
  location            = local.azure_config.location
  gateway_address     = aws_vpn_connection.azurevpn[each.key].tunnel1_address
  address_space       = [aws_vpc.vpcs[each.value["awsVPC"]].cidr_block]
}

resource "azurerm_public_ip" "vgw_pip" {
  for_each            = local.azure_config.vpnConnections
  name                = "vgw_pip"
  location            = local.azure_config.location
  resource_group_name = local.azure_config.resourceGroup
  allocation_method   = "Static"
}


resource "azurerm_virtual_network_gateway" "vng-aws-azure" {
  for_each            = local.azure_config.vpnConnections
  name                = each.key
  location            = local.azure_config.location
  resource_group_name = local.azure_config.resourceGroup

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "${each.key}-ip-config"
    public_ip_address_id          = azurerm_public_ip.vgw_pip[each.key].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnets[each.value["subnet"]].id
  }
}

resource "azurerm_virtual_network_gateway_connection" "onpremise" {
  for_each            = local.azure_config.vpnConnections
  name                = "${each.key}-vpn-connection"
  location            = local.azure_config.location
  resource_group_name = local.azure_config.resourceGroup

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng-aws-azure[each.key].id
  local_network_gateway_id   = azurerm_local_network_gateway.lng-aws-azure[each.key].id
  shared_key                 = aws_vpn_connection.azurevpn[each.key].tunnel1_preshared_key
}
