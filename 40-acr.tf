resource "azurerm_container_registry" "this" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Basic"

  # ACA authenticates via managed identity + AcrPull RBAC instead (see
  # role-assignments.tf). Admin credentials are never enabled.
  admin_enabled = false

  tags = local.common_tags
}
