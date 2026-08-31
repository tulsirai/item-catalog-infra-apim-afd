data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = var.key_vault_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # RBAC over legacy access policies - avoids managing a separate access
  # policy list and keeps secret access under the same role-assignment model
  # used everywhere else in this configuration.
  rbac_authorization_enabled = true

  tags = local.common_tags
}

# The identity running `terraform apply` needs write access to create the
# db-password secret below. Grants at Key Vault scope, not just the secret,
# since the secret doesn't exist yet when this assignment is created.
resource "azurerm_role_assignment" "deployer_kv_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = var.db_password_secret_name
  value        = var.db_app_password
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_role_assignment.deployer_kv_secrets_officer]
}
