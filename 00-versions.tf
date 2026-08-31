terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # Only used for the two resource types azurerm does not expose:
    # SWA linked backends and Container Apps auth configs (see linked-backend.tf,
    # container-app-auth.tf).
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    # Used solely to absorb Azure RBAC propagation delay before the Container
    # App's first revision starts (see role-assignments.tf).
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
    # azurerm has no resource for SQL logins/database users - this connects
    # directly over the SQL protocol to create the app's least-privilege
    # login (see 21-sql-user.tf), replacing what was a manual T-SQL step.
    mssql = {
      source  = "betr-io/mssql"
      version = "~> 0.2"
    }
    # Creates the Entra ID app registration APIM's managed identity requests
    # a token for, and the matching service principal (see 82-apim-aca-auth.tf).
    # azurerm has no resource for either.
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}
