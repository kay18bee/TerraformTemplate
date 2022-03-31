output "public_ip_address" {
  value = azurerm_linux_virtual_machine.terraformvm.public_ip_address
}