provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azapi" {}

# Connection details for the SQL server/database are supplied per-resource
# (see 21-sql-user.tf), not here - the provider block itself takes no
# connection config.
provider "mssql" {}

provider "azuread" {}
