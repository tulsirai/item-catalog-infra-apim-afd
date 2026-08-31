resource "azurerm_mssql_server" "this" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
  tags                         = local.common_tags
}

resource "azurerm_mssql_database" "this" {
  name      = var.sql_database_name
  server_id = azurerm_mssql_server.this.id

  sku_name                    = "GP_S_Gen5_${var.sql_max_capacity}"
  min_capacity                = var.sql_min_capacity
  auto_pause_delay_in_minutes = var.sql_auto_pause_delay
  max_size_gb                 = var.sql_max_size_gb
  storage_account_type        = "Local"

  tags = local.common_tags
}

# Required for ACA (no static outbound IP) to reach the SQL server over its
# public endpoint. This is the "Allow Azure services and resources to access
# this server" toggle from the portal, not a general public-internet opening.
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Opt-in: allows the machine running `terraform apply` (and, incidentally,
# whoever supplied the IP) through the firewall. Needed by mssql_user in
# 21-sql-user.tf, which connects directly over the SQL protocol - that
# resource will fail to create/read without this if developer_public_ip is
# unset. Also usable for manual access via the portal Query Editor, SSMS, or
# Azure Data Studio.
resource "azurerm_mssql_firewall_rule" "developer_access" {
  count            = var.developer_public_ip != null ? 1 : 0
  name             = "AllowDeveloperIP"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = var.developer_public_ip
  end_ip_address   = var.developer_public_ip
}

# Azure documents SQL firewall rule changes as taking up to 5 minutes to
# take effect - the same class of propagation delay as the RBAC race
# time_sleep.aca_rbac_propagation absorbs in role-assignments.tf, just for
# network rules instead of role assignments. mssql_user.app connects
# immediately after this rule "completes" in Terraform's graph, with no
# other resource creation in between to absorb the delay naturally - so an
# explicit wait is needed here too. If this still races in your tenant,
# increase create_duration.
resource "time_sleep" "sql_firewall_propagation" {
  count           = var.developer_public_ip != null ? 1 : 0
  depends_on      = [azurerm_mssql_firewall_rule.developer_access]
  create_duration = "30s"
}
