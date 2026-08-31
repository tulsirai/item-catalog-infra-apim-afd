# The manual build hit a real bug here: APIM's public "API URL suffix" is
# not automatically re-added when APIM calls the backend - the backend
# request is <service_url> + <operation template> only. Setting service_url
# to already include var.api_path (rather than the bare Container App root)
# avoids that dead end entirely instead of reproducing it.
resource "azurerm_api_management_api" "item_catalog" {
  name                  = var.api_name
  resource_group_name   = azurerm_resource_group.this.name
  api_management_name   = azurerm_api_management.this.name
  revision              = "1"
  display_name          = var.api_display_name
  path                  = var.api_path
  protocols             = ["https"]
  service_url           = "https://${azurerm_container_app.this.ingress[0].fqdn}/${var.api_path}"
  subscription_required = false
}

resource "azurerm_api_management_api_operation" "get_items" {
  operation_id        = "get-items"
  api_name            = azurerm_api_management_api.item_catalog.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "Get items"
  method              = "GET"
  url_template        = "/items"
}

resource "azurerm_api_management_api_operation" "create_item" {
  operation_id        = "create-item"
  api_name            = azurerm_api_management_api.item_catalog.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "Create item"
  method              = "POST"
  url_template        = "/items"
}

resource "azurerm_api_management_api_operation" "get_item_by_id" {
  operation_id        = "get-item-by-id"
  api_name            = azurerm_api_management_api.item_catalog.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "Get item by id"
  method              = "GET"
  url_template        = "/items/{id}"

  template_parameter {
    name     = "id"
    type     = "string"
    required = true
  }
}

resource "azurerm_api_management_api_operation" "update_item" {
  operation_id        = "update-item"
  api_name            = azurerm_api_management_api.item_catalog.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "Update item"
  method              = "PUT"
  url_template        = "/items/{id}"

  template_parameter {
    name     = "id"
    type     = "string"
    required = true
  }
}

resource "azurerm_api_management_api_operation" "delete_item" {
  operation_id        = "delete-item"
  api_name            = azurerm_api_management_api.item_catalog.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "Delete item"
  method              = "DELETE"
  url_template        = "/items/{id}"

  template_parameter {
    name     = "id"
    type     = "string"
    required = true
  }
}

# An API with no product association isn't published - not reachable
# through the gateway at all, not just gated behind a subscription key
# (confirmed during the manual build). "Unlimited" mirrors the built-in
# product used there; subscription_required = false throughout, since the
# React frontend has no mechanism to send a subscription key.
resource "azurerm_api_management_product" "unlimited" {
  product_id            = "unlimited"
  api_management_name   = azurerm_api_management.this.name
  resource_group_name   = azurerm_resource_group.this.name
  display_name          = "Unlimited"
  subscription_required = false
  approval_required     = false
  published             = true
}

resource "azurerm_api_management_product_api" "item_catalog" {
  product_id          = azurerm_api_management_product.unlimited.product_id
  api_name            = azurerm_api_management_api.item_catalog.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
}
