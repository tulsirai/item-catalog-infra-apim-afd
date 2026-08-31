resource "azurerm_role_assignment" "aca_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca.principal_id
}

resource "azurerm_role_assignment" "aca_kv_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aca.principal_id
}

# Azure RBAC assignments can take a short time to propagate globally even
# after the Terraform resource reports as created. The Container App depends
# on this instead of on the role assignments directly, so its first revision
# doesn't race the propagation window when pulling the image / reading the
# Key Vault secret.
resource "time_sleep" "aca_rbac_propagation" {
  depends_on = [
    azurerm_role_assignment.aca_acr_pull,
    azurerm_role_assignment.aca_kv_secrets_user,
  ]
  create_duration = "30s"
}
