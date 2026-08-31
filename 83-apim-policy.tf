# Mirrors the manual "All operations > Inbound processing" policy, applied
# once at the API level so all five operations inherit it - same pattern
# already used for the shared Container App backend URL.
#
# authentication-managed-identity is Microsoft's own first-class policy for
# exactly this scenario: one Azure PaaS resource authenticating to another.
# It's the recommended choice over the alternatives considered during the
# manual build - a hand-rolled OAuth client-credentials flow would require
# storing a client secret somewhere (breaking the "no stored credentials"
# principle this project follows for every other service-to-service
# connection: ACR pull, Key Vault reads, and now this); a shared header
# validated in application code is simpler but requires an app-code change
# and is a materially weaker guarantee than a platform-validated,
# cryptographically signed AAD token. With this policy, APIM never holds or
# manages a credential at all - Entra ID issues a short-lived token on
# demand, and APIM's policy engine handles caching and refreshing it.
resource "azurerm_api_management_api_policy" "item_catalog" {
  api_name            = azurerm_api_management_api.item_catalog.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <authentication-managed-identity resource="${tolist(azuread_application.aca_auth.identifier_uris)[0]}" output-token-variable-name="msi-access-token" ignore-error="false" />
    <set-header name="Authorization" exists-action="override">
      <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
    </set-header>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML

  depends_on = [
    # Not required for this resource to be created, but avoids a brief window
    # where APIM would present a token before ACA's auth config is ready to
    # validate it against the right audience.
    azapi_resource.aca_auth_config,
    # Required to avoid a real race: this resource has no direct reference to
    # the five operations, so Terraform's default parallelism can apply this
    # policy write concurrently with one or more operation writes against the
    # same API. APIM's management plane uses optimistic concurrency (ETag)
    # internally, and a concurrent write against the same API loses with
    # `412 Precondition Failed` - hit for real on this repo's first apply.
    # Forcing the operations to finish first serializes the writes and
    # removes the race rather than just retrying past it.
    azurerm_api_management_api_operation.get_items,
    azurerm_api_management_api_operation.create_item,
    azurerm_api_management_api_operation.get_item_by_id,
    azurerm_api_management_api_operation.update_item,
    azurerm_api_management_api_operation.delete_item,
  ]
}
