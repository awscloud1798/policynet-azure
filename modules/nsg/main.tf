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

variable "rules" {
  type = map(object({
    priority    = number
    access      = string
    protocol    = optional(string, "Tcp")
    ports       = optional(list(string), ["*"])
    src_prefix  = optional(string)
    src_asg_ids = optional(list(string))
    dst_asg_ids = optional(list(string))
  }))
}

resource "azurerm_network_security_group" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg
}

resource "azurerm_network_security_rule" "this" {
  for_each                    = var.rules
  name                        = each.key
  resource_group_name         = var.rg
  network_security_group_name = azurerm_network_security_group.this.name
  direction                   = "Inbound"
  priority                    = each.value.priority
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = "*"

  destination_port_range  = length(each.value.ports) == 1 ? each.value.ports[0] : null
  destination_port_ranges = length(each.value.ports) > 1 ? each.value.ports : null

  source_address_prefix                 = each.value.src_prefix
  source_application_security_group_ids = each.value.src_asg_ids

  destination_address_prefix                 = each.value.dst_asg_ids == null ? "*" : null
  destination_application_security_group_ids = each.value.dst_asg_ids
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.this.id
}
