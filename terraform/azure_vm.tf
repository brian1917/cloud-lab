resource "azurerm_linux_virtual_machine" "linuxVMs" {
  for_each            = local.azure_config.linuxVMs
  name                = each.key
  location            = local.azure_config.location
  resource_group_name = local.azure_config.resourceGroup
  network_interface_ids = [
    azurerm_network_interface.vminterfaces[each.key].id,
  ]

  size           = each.value["size"]
  admin_username = "ubuntu"

  admin_ssh_key {
    username   = "ubuntu"
    public_key = file("${local.aws_config.sshKey}.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  tags = each.value.tags
}

resource "azurerm_windows_virtual_machine" "windowsVM" {
  for_each              = local.azure_config.windowsVMs
  name                  = each.key
  location              = local.azure_config.location
  resource_group_name   = local.azure_config.resourceGroup
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  admin_password        = "P@$$w0rd1234!"
  network_interface_ids = [azurerm_network_interface.vminterfaces[each.key].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}


resource "azurerm_network_interface" "vminterfaces" {
  for_each            = merge(local.azure_config.linuxVMs, local.azure_config.windowsVMs)
  name                = each.key
  location            = local.azure_config.location
  resource_group_name = local.azure_config.resourceGroup

  dynamic "ip_configuration" {
    for_each = { for k, v in merge(local.azure_config.linuxVMs, local.azure_config.windowsVMs) : k => v if v.publicIP && k == each.key }
    content {
      name                          = each.key
      subnet_id                     = azurerm_subnet.subnets["${each.value["vnet"]}.${each.value["subnet"]}"].id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.public_ip[each.key].id
    }
  }

  dynamic "ip_configuration" {
    for_each = { for k, v in merge(local.azure_config.linuxVMs, local.azure_config.windowsVMs) : k => v if v.publicIP == false && k == each.key }
    content {
      name                          = each.key
      subnet_id                     = azurerm_subnet.subnets["${each.value["vnet"]}.${each.value["subnet"]}"].id
      private_ip_address_allocation = "Dynamic"
    }
  }

 // Dummy ip_configuration block to ensure at least one block is present - needed if no Azure VM's are included
    dynamic "ip_configuration" {
    for_each = length(local.azure_config.linuxVMs) + length(local.azure_config.windowsVMs) > 0 ? {} : { "dummy" = {} }
    content {
      name                          = "dummy"
      subnet_id                     = azurerm_subnet.subnets["${each.value["vnet"]}.${each.value["subnet"]}"].id
      private_ip_address_allocation = "Dynamic"
    }
  }
}

# Create a public IP address
resource "azurerm_public_ip" "public_ip" {
  for_each            = { for k, v in merge(local.azure_config.linuxVMs, local.azure_config.windowsVMs) : k => v if v.publicIP }
  name                = each.key
  location            = local.azure_config.location
  resource_group_name = local.azure_config.resourceGroup
  allocation_method   = "Dynamic"
}