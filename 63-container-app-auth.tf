# AzureRM has no resource for Microsoft.App/containerApps/authConfigs -
# AzAPI is the only supported path.
#
# unauthenticatedClientAction = Return401, not the RedirectToLoginPage
# default: RedirectToLoginPage is built for interactive browser logins, not
# server-to-server API calls. A direct unauthenticated request gets
# redirected toward a login page (surfacing as an unhelpful 400), and a
# proxied request fails outright (surfacing as a 500 "Backend call
# failure"), since the caller has no way to follow an interactive redirect.
# Return401 lets a caller carrying a valid token through while direct calls
# cleanly get 401 instead of a broken redirect.
#
# Unlike the plain-ACA build, the trusted caller here is APIM (via the
# identityProviders.azureActiveDirectory block below), not a SWA linked
# backend - this variant's SWA links to APIM instead (see 71-linked-backend.tf),
# so there is no "Azure Static Web Apps (Linked)" provider to configure.
resource "azapi_resource" "aca_auth_config" {
  type      = "Microsoft.App/containerApps/authConfigs@2024-03-01"
  name      = "current"
  parent_id = azurerm_container_app.this.id

  body = {
    properties = {
      platform = {
        enabled = true
      }
      globalValidation = {
        unauthenticatedClientAction = "Return401"
      }
      identityProviders = {
        azureActiveDirectory = {
          enabled = true
          registration = {
            clientId = azuread_application.aca_auth.client_id
          }
          validation = {
            allowedAudiences = tolist(azuread_application.aca_auth.identifier_uris)
            # "Allowed client applications" - only APIM's own managed
            # identity may call in. Left unset (allowedPrincipals) is the
            # "Identity requirement: any identity" choice from the manual
            # build - irrelevant here since no signed-in user is involved,
            # only a service-to-service call.
            defaultAuthorizationPolicy = {
              allowedApplications = [data.azuread_service_principal.apim.client_id]
            }
          }
        }
      }
    }
  }

  depends_on = [azurerm_container_app.this, time_sleep.aad_propagation]
}
