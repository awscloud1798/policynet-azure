output "rg_name" {
  value = azurerm_resource_group.this.name
}

output "web_public_ip" {
  value = azurerm_public_ip.web.ip_address
}

output "web_private_ip" {
  value = module.vm_web.private_ip
}

output "app_private_ip" {
  value = module.vm_app.private_ip
}

output "db_private_ip" {
  value = module.vm_db.private_ip
}
