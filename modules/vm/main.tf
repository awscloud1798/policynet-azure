variable "name" {
  type = string
}

variable "rg" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "listen_port" {
  type = number
}

variable "public_ip_id" {
  type    = string
  default = null
}

resource "azurerm_network_interface" "this" {
  name                = "nic-${var.name}"
  location            = var.location
  resource_group_name = var.rg

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_id
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                  = var.name
  resource_group_name   = var.rg
  location              = var.location
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.this.id]
  custom_data           = base64encode(templatefile("${path.module}/cloud-init.tftpl", { port = var.listen_port }))

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

output "nic_id" {
  value = azurerm_network_interface.this.id
}

output "private_ip" {
  value = azurerm_network_interface.this.private_ip_address
}
