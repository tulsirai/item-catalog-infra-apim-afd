# AzureRM has no resource for Microsoft.Web/staticSites/linkedBackends - this
# is the SWA "Link" action from the portal (APIs -> Production -> Link ->
# API Management). AzAPI is the only supported path.
#
# Linked to APIM, not the Container App directly - this is the entire point
# of this variant. Microsoft's own SWA API docs confirm API Management is a
# supported linked-backend type, same "Bring your own" mechanism already
# used for Container Apps in the plain-ACA build.
#
# The `region` field is pinned explicitly (not left to provider default):
# https://github.com/Azure/terraform-provider-azapi/issues/629 documents
# spurious replace-on-plan behavior when it's omitted and the provider falls
# back to a default value.
resource "azapi_resource" "swa_linked_backend" {
  type      = "Microsoft.Web/staticSites/linkedBackends@2023-01-01"
  name      = var.apim_name
  parent_id = azurerm_static_web_app.this.id

  body = {
    properties = {
      backendResourceId = azurerm_api_management.this.id
      region            = azurerm_resource_group.this.location
    }
  }

  depends_on = [azurerm_api_management.this]
}
