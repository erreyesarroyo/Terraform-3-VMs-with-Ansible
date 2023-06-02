resource "azurerm_resource_group" "rg001" {
  name     = "rg001"
  location = "eastus"
}

resource "azurerm_virtual_network" "vnet001" {
  name                = "vnet001"
  location            = azurerm_resource_group.rg001.location
  resource_group_name = azurerm_resource_group.rg001.name
  address_space       = ["10.0.0.0/16"]

  depends_on = [
    azurerm_resource_group.rg001
  ]
}

resource "azurerm_subnet" "subnetA" {
  name                 = "subnetA"
  resource_group_name  = azurerm_resource_group.rg001.name
  virtual_network_name = azurerm_virtual_network.vnet001.name
  address_prefixes     = ["10.0.0.0/24"]

  depends_on = [
    azurerm_virtual_network.vnet001
  ]
}

resource "azurerm_subnet" "subnetB" {
  name                 = "subnetB"
  resource_group_name  = azurerm_resource_group.rg001.name
  virtual_network_name = azurerm_virtual_network.vnet001.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [
    azurerm_virtual_network.vnet001
  ]
}

resource "azurerm_network_security_group" "nsg001" {
  name                = "nsg001"
  location            = azurerm_resource_group.rg001.location
  resource_group_name = azurerm_resource_group.rg001.name

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
  location            = azurerm_resource_group.rg001.location
  resource_group_name = azurerm_resource_group.rg001.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = count.index == 0 ? azurerm_public_ip.pubip[count.index].id : null
  }

  depends_on = [
    azurerm_subnet.subnetA
  ]
}

resource "azurerm_public_ip" "pubip" {
  count               = 3
  name                = "pubip${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg001.name
  location            = azurerm_resource_group.rg001.location
  allocation_method   = count.index == 0 ? "Dynamic" : "Static"
}
