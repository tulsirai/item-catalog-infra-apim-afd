# Managed rule sets and versions match what the manual build's "Create a new
# WAF policy" quick-create dialog actually provisioned (confirmed via
# `az network front-door waf-policy show`), reproduced here explicitly rather
# than left to whatever Azure's current default happens to be - so this
# Terraform build doesn't silently drift from what was manually validated.
resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  name                = var.afd_waf_policy_name
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = var.afd_sku_name
  enabled             = true
  mode                = var.afd_waf_mode

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }

  tags = local.common_tags
}

# The security policy is the binding that makes the firewall policy above
# actually apply to this endpoint's domain - a firewall policy created but
# never attached to a security policy protects nothing (see the companion
# Front Door How-To's Step 8 notes).
resource "azurerm_cdn_frontdoor_security_policy" "this" {
  name                     = var.afd_security_policy_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}
