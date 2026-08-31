# One origin (this Static Web App), so session affinity and the load
# balancing block's sample-size/latency-sensitivity settings have nothing to
# do their job on - left at Azure's own defaults, same as the manual build.
resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = var.afd_origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  session_affinity_enabled = false

  health_probe {
    interval_in_seconds = 100
    path                = "/"
    protocol            = "Https" # matches the route's HttpsOnly forwarding protocol below - an HTTP probe against an HTTPS-enforcing origin risks reading a redirect as "unhealthy"
    request_type        = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

# No dedicated "origin type" field exists in this resource (unlike the
# portal's "Static Web App" picker, which is UX sugar over the same
# host_name/origin_host_header pair set explicitly here). Private Link is
# not supported for a Static Web App origin - confirmed in the manual build -
# so certificate_name_check_enabled plus the origin-restriction config on the
# SWA side (documented in the README, applied outside Terraform) are what
# actually secure this origin.
resource "azurerm_cdn_frontdoor_origin" "this" {
  name                          = var.afd_origin_name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id

  enabled                        = true
  host_name                      = azurerm_static_web_app.this.default_host_name
  origin_host_header             = azurerm_static_web_app.this.default_host_name
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}
