variable "rg" {
  type = string
}

variable "location" {
  type = string
}

variable "subnets" {
  type = map(string)
  default = {
    web = "10.0.1.0/24"
    app = "10.0.2.0/24"
    db  = "10.0.3.0/24"
  }
}

resource "azurerm_virtual_network" "this" {
  name                = "pnet-vnet"
  location            = var.location
  resource_group_name = var.rg
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "this" {
  for_each             = var.subnets
  name                 = "snet-${each.key}"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]
}

output "subnet_ids" {
  value = { for k, s in azurerm_subnet.this : k => s.id }
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}
