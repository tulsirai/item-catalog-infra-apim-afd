# Consumption tier: pay-per-call, no idle cost - matches the scale-to-zero
# philosophy already used for SQL (auto-pause) and ACA (min_replicas = 0)
# elsewhere in this project. Developer tier would give full feature parity
# with the production gateway, but runs (and bills) continuously regardless
# of use.
resource "azurerm_api_management" "this" {
  name                = var.apim_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = "Consumption_0"

  # System-assigned is fine here (unlike the Container App's identity,
  # see 60-identity.tf) - APIM doesn't have the same bootstrap-ordering
  # problem, since nothing needs this identity to exist before APIM itself
  # is created. This is the identity APIM uses to authenticate to ACA
  # without a stored credential (see 82-apim-aca-auth.tf, 83-apim-policy.tf).
  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}
