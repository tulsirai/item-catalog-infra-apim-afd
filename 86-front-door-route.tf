# Caching is deliberately omitted (no `cache` block = pass-through, disabled)
# - the origin serves a dynamic SPA shell, not static content worth caching
# at this layer for a POC. forwarding_protocol is pinned to HttpsOnly rather
# than "match incoming request", so no plain-HTTP request can reach the
# origin even on the narrow path before https_redirect_enabled applies.
resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = var.afd_route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.this.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  link_to_default_domain = true
}
