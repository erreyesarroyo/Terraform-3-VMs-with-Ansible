
resource "azurerm_resource_group" "rg001" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "vnet001" {
  name                = local.virtual_network.name
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = [local.virtual_network.address_space]

  depends_on = [
    azurerm_resource_group.rg001
  ]
}

resource "azurerm_subnet" "subnetA" {
  name                 = local.subnets[0].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnets[0].address_prefix]

  depends_on = [
    azurerm_virtual_network.vnet001
  ]
}

resource "azurerm_subnet" "subnetB" {
  name                 = local.subnets[1].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnets[1].address_prefix]

  depends_on = [
    azurerm_virtual_network.vnet001
  ]
}

resource "azurerm_network_security_group" "nsg001" {
  name                = "nsg001"
  location            = local.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [
    azurerm_resource_group.rg001
  ]
}

resource "azurerm_subnet_network_security_group_association" "nsglink001" {
  subnet_id                 = azurerm_subnet.subnetA.id
  network_security_group_id = azurerm_network_security_group.nsg001.id
}

resource "azurerm_network_interface" "nic001" {
  count               = 3
  name                = "nic${count.index + 1}"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_subnet.subnetA
  ]
}

resource "azurerm_linux_virtual_machine" "lvm" {
  count               = 3
  name                = count.index == 0 ? "Master" : "lvm00${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg001.name
  location            = azurerm_resource_group.rg001.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic001[count.index].id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/azure_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
