# Resource group creation
resource "azurerm_resource_group" "resource_gp" {
  name     = "TerraDemo"
  location = var.resource_group_location
}
# Create virtual network
resource "azurerm_virtual_network" "terraformnetwork" {
  name                = "VnetTerra"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource_gp.location
  resource_group_name = "TerraDemo"
}

# Create subnet
resource "azurerm_subnet" "terraformsubnet" {
  name                 = "SnetTerra"
  resource_group_name  = "TerraDemo"
  virtual_network_name = azurerm_virtual_network.terraformnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "terraformpublicip" {
  name                = "PIPTerra"
  location            = azurerm_resource_group.resource_gp.location
  resource_group_name = "TerraDemo"
  allocation_method   = "Static"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "terraformnsg" {
  name                = "NSGTerra"
  location            = azurerm_resource_group.resource_gp.location
  resource_group_name = "TerraDemo"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "terraformnic" {
  name                = "NICTerra"
  location            = azurerm_resource_group.resource_gp.location
  resource_group_name = "TerraDemo"

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.terraformsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraformpublicip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.terraformnic.id
  network_security_group_id = azurerm_network_security_group.terraformnsg.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "storageaccount" {
  name                     = "terrastorage1122334"
  location                 = azurerm_resource_group.resource_gp.location
  resource_group_name      = "TerraDemo"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "terraformvm" {
  name                            = "VMTerra"
  location                        = azurerm_resource_group.resource_gp.location
  resource_group_name             = "TerraDemo"
  network_interface_ids           = [azurerm_network_interface.terraformnic.id]
  size                            = "Standard_DS1_v2"
  admin_username                  = "testuser"
  admin_password                  = "Karanuser1234"
  disable_password_authentication = false

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storageaccount.primary_blob_endpoint
  }
}
