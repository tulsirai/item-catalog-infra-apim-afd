# User-assigned (not system-assigned) so the identity exists and can be
# RBAC-granted *before* the Container App that uses it is created. A
# system-assigned identity is created in the same API call as the Container
# App itself, which means its first revision would try to pull from ACR and
# read the Key Vault secret before any role assignment referencing that
# identity could possibly exist yet - a guaranteed failure on first apply.
# See infra README "Container App identity" for the full rationale.
resource "azurerm_user_assigned_identity" "aca" {
  name                = "${var.container_app_name}-identity"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.common_tags
}
