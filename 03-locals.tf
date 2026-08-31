locals {
  common_tags = {
    environment = var.environment
    application = "item-catalog"
    managed-by  = "terraform"
    purpose     = "azure-platform-poc"
  }
}
