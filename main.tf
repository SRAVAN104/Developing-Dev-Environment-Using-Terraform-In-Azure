terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.0"
    }
  }
}
provider "azurerm" {
  features {}

}
resource "azurerm_resource_group" "mtc-la" {
  name     = "mtc-resources"
  location = "East Us"
  tags = {
    env = "dev"
  }
}

resource "azurerm_virtual_network" "mtc-vn" {
  name                = "mtc-networks"
  resource_group_name = azurerm_resource_group.mtc-la.name
  location            = azurerm_resource_group.mtc-la.location
  address_space       = ["10.128.0.0/12"]

  tags = {
    env = "dev"
  }

}

resource "azurerm_subnet" "mtc-la" {
  name                 = "mtc-subnet"
  resource_group_name  = azurerm_resource_group.mtc-la.name
  virtual_network_name = azurerm_virtual_network.mtc-vn.name
  address_prefixes     = ["10.128.1.0/24"]

}

resource "azurerm_network_security_group" "mtc-sg" {
  name                = "mtc-securitygroup"
  location            = azurerm_resource_group.mtc-la.location
  resource_group_name = azurerm_resource_group.mtc-la.name

  tags = {
    env = "dev"
  }

}
resource "azurerm_network_security_rule" "mtc-dev-rule" {
  name                        = "mtc-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.mtc-la.name
  network_security_group_name = azurerm_network_security_group.mtc-sg.name

}

resource "azurerm_subnet_network_security_group_association" "mtc-sga" {
  subnet_id                 = azurerm_subnet.mtc-la.id
  network_security_group_id = azurerm_network_security_group.mtc-sg.id

}

resource "azurerm_public_ip" "mtc-ip" {
  name                = "mtc-ip"
  resource_group_name = azurerm_resource_group.mtc-la.name
  location            = azurerm_resource_group.mtc-la.location
  allocation_method   = "Dynamic"

  tags = {
    env = "dev"
  }

}

resource "azurerm_network_interface" "mtc-ni" {
  name                = "mtc-ni"
  location            = azurerm_resource_group.mtc-la.location
  resource_group_name = azurerm_resource_group.mtc-la.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mtc-la.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mtc-ip.id
  }

  tags = {
    env = "dev"
  }
}


resource "azurerm_linux_virtual_machine" "mtc-vm" {
  name                = "mtc-machine"
  resource_group_name = azurerm_resource_group.mtc-la.name
  location            = azurerm_resource_group.mtc-la.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.mtc-ni.id,
  ]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  tags = {
    env = "dev"
  }
}
