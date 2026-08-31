# Azure Front Door Premium sits in front of the Static Web App, one layer
# outside everything else in this stack (AFD -> SWA -> APIM -> ACA -> SQL).
# Premium tier (not Standard) is required for the managed WAF rule sets - see
# afd_sku_name's description.
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = var.afd_profile_name
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = var.afd_sku_name
  tags                = local.common_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = var.afd_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  tags                     = local.common_tags
}
