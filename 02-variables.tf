variable "subscription_id" {
  description = "Azure subscription ID to deploy into. Leave null to use the az CLI's active subscription."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "West US 2"
}

variable "environment" {
  description = "Environment tag/suffix (dev, dev-iac, qa, ...). Kept as a variable so a parallel environment can be stood up without renaming every resource by hand."
  type        = string
  default     = "dev"
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
  default     = "rg-itemcatalog-dev"
}

# ---------------------------------------------------------------------------
# Azure SQL
# ---------------------------------------------------------------------------

variable "sql_server_name" {
  description = "Azure SQL logical server name (globally unique)."
  type        = string
  default     = "sql-itemcatalog-poc-dev-westus2"
}

variable "sql_database_name" {
  description = "Azure SQL database name."
  type        = string
  default     = "ItemCatalogDb"
}

variable "sql_admin_login" {
  description = "Azure SQL server administrator login. Not used by the running application (see db_app_user)."
  type        = string
  default     = "agia"
}

variable "sql_admin_password" {
  description = "Azure SQL server administrator password. Supply via TF_VAR_sql_admin_password; never set a default or commit a value."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.sql_admin_password) >= 8
    error_message = "sql_admin_password must be at least 8 characters (Azure SQL policy minimum)."
  }
}

variable "db_app_user" {
  description = "Least-privilege SQL login used by the running application (DB_USER). Distinct from sql_admin_login; the login/user itself is created via T-SQL, not Terraform (azurerm has no SQL login/user resource)."
  type        = string
  default     = "itemcatalog_app"
}

variable "db_app_password" {
  description = "Password for db_app_user. Stored only in Key Vault (secret db-password) and referenced by ACA via managed identity - never written to app-facing Terraform config. Supply via TF_VAR_db_app_password."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_app_password) >= 8
    error_message = "db_app_password must be at least 8 characters."
  }
}

variable "sql_min_capacity" {
  description = "Serverless minimum vCores."
  type        = number
  default     = 0.5
}

variable "sql_max_capacity" {
  description = "Serverless maximum vCores (also selects the GP_S_Gen5_<n> SKU)."
  type        = number
  default     = 2
}

variable "sql_auto_pause_delay" {
  description = "Minutes of inactivity before the database auto-pauses."
  type        = number
  default     = 60
}

variable "sql_max_size_gb" {
  description = "Maximum database size in GB."
  type        = number
  default     = 32
}

variable "developer_public_ip" {
  description = "Public IPv4 address to allow through the SQL server firewall. Required for the mssql_user resource (21-sql-user.tf) to connect from wherever `terraform apply` runs, and useful for connecting yourself via the portal Query Editor / SSMS / Azure Data Studio. Find yours with `curl -s https://api.ipify.org`. Leave null only if you have another way to reach the server (e.g. already-allowlisted CI runner)."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

variable "key_vault_name" {
  description = "Key Vault name."
  type        = string
  default     = "kv-itemcatalog-dev"
}

variable "db_password_secret_name" {
  description = "Name of the Key Vault secret holding db_app_password."
  type        = string
  default     = "db-password"
}

# ---------------------------------------------------------------------------
# Container Registry
# ---------------------------------------------------------------------------

variable "acr_name" {
  description = "Azure Container Registry name (globally unique, alphanumeric only)."
  type        = string
  default     = "acritemcatalogpoc"
}

# ---------------------------------------------------------------------------
# Container Apps
# ---------------------------------------------------------------------------

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace name backing the Container Apps environment."
  type        = string
  default     = "law-itemcatalog-dev"
}

variable "container_app_environment_name" {
  description = "Container Apps environment name."
  type        = string
  default     = "cae-itemcatalog-dev"
}

variable "container_app_name" {
  description = "Container App name."
  type        = string
  default     = "ca-itemcatalog-api-dev"
}

variable "container_image_repository" {
  description = "ACR repository name for the application image."
  type        = string
  default     = "item-catalog-service"
}

variable "container_image_tag" {
  description = "Image tag to deploy."
  type        = string
  default     = "1.0.0"
}

variable "container_cpu" {
  description = "vCPU allocated to the container (must pair with a valid memory value per ACA's fixed cpu/memory combinations)."
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memory allocated to the container."
  type        = string
  default     = "1Gi"
}

variable "container_min_replicas" {
  description = "Minimum replica count. 0 enables scale-to-zero."
  type        = number
  default     = 0
}

variable "container_max_replicas" {
  description = "Maximum replica count for DEV/POC."
  type        = number
  default     = 2
}

# ---------------------------------------------------------------------------
# Static Web App
# ---------------------------------------------------------------------------

variable "static_web_app_name" {
  description = "Static Web App name."
  type        = string
  default     = "swa-itemcatalog-ui-dev"
}

variable "static_web_app_sku" {
  description = "Static Web App SKU tier (Free or Standard). Standard is required for the linked-backend feature."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard"], var.static_web_app_sku)
    error_message = "static_web_app_sku must be Free or Standard."
  }
}

# ---------------------------------------------------------------------------
# API Management
# ---------------------------------------------------------------------------

variable "apim_name" {
  description = "API Management instance name (globally unique)."
  type        = string
  default     = "apim-itemcatalog-dev-afd"
}

variable "apim_publisher_name" {
  description = "APIM publisher/organization name shown in the developer portal."
  type        = string
  default     = "item-catalog"
}

variable "apim_publisher_email" {
  description = "APIM publisher contact email. No default on purpose - not something to commit even as a placeholder default; set your own in terraform.tfvars."
  type        = string
}

variable "api_name" {
  description = "APIM API name."
  type        = string
  default     = "item-catalog-api"
}

variable "api_display_name" {
  description = "APIM API display name."
  type        = string
  default     = "Item Catalog API"
}

variable "api_path" {
  description = "APIM API URL suffix. The public gateway path becomes <api_path>/<operation-template>; the backend service_url is set to already include this same path (see 81-apim-api.tf), avoiding the path-mapping bug the manual build hit."
  type        = string
  default     = "api/v1"
}

variable "aca_auth_app_registration_name" {
  description = "Azure AD app registration name representing the ACA API's audience for the APIM -> ACA managed-identity token handoff. Distinct from the Container App's own name - this is an Entra ID object, not an Azure resource."
  type        = string
  default     = "ca-itemcatalog-api-auth-dev-afd"
}

# ---------------------------------------------------------------------------
# Azure Front Door
# ---------------------------------------------------------------------------

variable "afd_sku_name" {
  description = "Front Door tier. Premium (not Standard) is required for the managed WAF rule sets this build depends on - Standard is CDN/load-balancing only, with no WAF capability."
  type        = string
  default     = "Premium_AzureFrontDoor"

  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.afd_sku_name)
    error_message = "afd_sku_name must be Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "afd_profile_name" {
  description = "Front Door profile name."
  type        = string
  default     = "afd-itemcatalog-dev-afd"
}

variable "afd_endpoint_name" {
  description = "Front Door endpoint name - becomes a subdomain of the regional *.azurefd.net domain (e.g. <name>-<hash>.z01.azurefd.net). Globally unique."
  type        = string
  default     = "itemcatalog-dev-afd"
}

variable "afd_origin_group_name" {
  description = "Front Door origin group name."
  type        = string
  default     = "itemcatalog-dev-afd-origin-group"
}

variable "afd_origin_name" {
  description = "Front Door origin name, pointing at the Static Web App's default hostname."
  type        = string
  default     = "swa-itemcatalog-ui-origin"
}

variable "afd_route_name" {
  description = "Front Door route name."
  type        = string
  default     = "itemcatalog-dev-afd-route"
}

variable "afd_waf_policy_name" {
  description = "Front Door WAF (firewall) policy name. Must be alphanumeric only - no hyphens or underscores allowed."
  type        = string
  default     = "wafitemcatalogdevafd"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]+$", var.afd_waf_policy_name))
    error_message = "afd_waf_policy_name must be alphanumeric only (no hyphens or underscores)."
  }
}

variable "afd_security_policy_name" {
  description = "Front Door security policy name - the binding between the WAF policy and the endpoint domain it applies to."
  type        = string
  default     = "itemcatalog-dev-afd-security-policy"
}

variable "afd_waf_mode" {
  description = "WAF policy mode. The manual build's quick-create flow defaulted to Detection (logs only, blocks nothing) and had to be switched to Prevention by hand after confirming it wouldn't block legitimate traffic - see the companion Front Door How-To. That validation is already done, so this Terraform reproduction defaults straight to Prevention rather than repeating the two-step manual process."
  type        = string
  default     = "Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.afd_waf_mode)
    error_message = "afd_waf_mode must be Detection or Prevention."
  }
}
