# Mirrors the manual "Add identity provider > Create new app registration"
# step - a purpose-built Entra ID app registration that exists solely as a
# token audience, not for any interactive sign-in flow. No oauth2_permission_scope
# block is defined: the manual wizard auto-generates an unused delegated
# scope as a side effect (harmless, but unnecessary), and this design skips
# it since the APIM -> ACA handoff is an application-only (client-credentials)
# flow that never uses a delegated scope at all.
#
# identifier_uris must use the tenant ID (not an arbitrary friendly string):
# Entra ID's default tenant policy rejects custom identifier URIs unless
# they're a verified domain, the tenant ID, or the app's own ID - confirmed
# the hard way, when a plain "api://ca-itemcatalog-api-auth-dev-gw" URI was
# rejected with InvalidUniqueTenantIdentifierAsPerAppPolicy. This is also
# why the manual portal wizard defaulted to api://<client-id> rather than a
# friendly name. Using the tenant ID here instead of the app's own client ID
# avoids a self-reference chicken-and-egg problem (the client ID isn't known
# until the resource is created) - data.azurerm_client_config.current is
# already declared in 30-key-vault.tf and reused here rather than adding a
# second, azuread-specific client-config lookup.
resource "azuread_application" "aca_auth" {
  display_name    = var.aca_auth_app_registration_name
  identifier_uris = ["api://${data.azurerm_client_config.current.tenant_id}/${var.aca_auth_app_registration_name}"]
}

# An azuread_application alone is not a usable identity - the service
# principal is what actually instantiates it in the tenant (shown as an
# "Enterprise Application" in the portal), the same object the manual wizard
# auto-created alongside the registration.
resource "azuread_service_principal" "aca_auth" {
  client_id = azuread_application.aca_auth.client_id
}

# APIM's own managed identity, looked up by object (principal) ID to get its
# Application (client) ID - the value ACA's auth config needs for its
# "Allowed client applications" list. These are two different IDs: the
# object ID identifies the identity itself, the client ID is what a token's
# appid claim carries and what ACA checks the caller against.
data "azuread_service_principal" "apim" {
  object_id = azurerm_api_management.this.identity[0].principal_id
}

# Entra ID directory changes (the new app registration + service principal
# above) can have propagation delay before Container Apps' auth layer
# reliably sees them - the same class of eventual-consistency race
# time_sleep.aca_rbac_propagation and time_sleep.sql_firewall_propagation
# absorb elsewhere in this project, just for AAD objects instead of RBAC
# role assignments or SQL firewall rules.
resource "time_sleep" "aad_propagation" {
  depends_on = [
    azuread_service_principal.aca_auth,
    data.azuread_service_principal.apim,
  ]
  create_duration = "30s"
}
