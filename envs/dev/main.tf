resource "azurerm_resource_group" "this" {
  name     = "pnet-rg"
  location = var.location
}

module "network" {
  source   = "../../modules/network"
  rg       = azurerm_resource_group.this.name
  location = var.location
}

# Only the web VM gets a public IP
resource "azurerm_public_ip" "web" {
  name                = "pip-web"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

module "vm_web" {
  source         = "../../modules/vm"
  name           = "vm-web"
  rg             = azurerm_resource_group.this.name
  location       = var.location
  subnet_id      = module.network.subnet_ids["web"]
  ssh_public_key = var.ssh_public_key
  listen_port    = 80
  public_ip_id   = azurerm_public_ip.web.id
}

module "vm_app" {
  source         = "../../modules/vm"
  name           = "vm-app"
  rg             = azurerm_resource_group.this.name
  location       = var.location
  subnet_id      = module.network.subnet_ids["app"]
  ssh_public_key = var.ssh_public_key
  listen_port    = 8080
}

module "vm_db" {
  source         = "../../modules/vm"
  name           = "vm-db"
  rg             = azurerm_resource_group.this.name
  location       = var.location
  subnet_id      = module.network.subnet_ids["db"]
  ssh_public_key = var.ssh_public_key
  listen_port    = 5432
}
