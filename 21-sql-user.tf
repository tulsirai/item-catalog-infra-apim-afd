# Replaces the manual "Query editor -> CREATE USER -> ALTER ROLE" steps from
# the first deployment. azurerm has no resource for SQL logins/database
# users (it's out of ARM's scope entirely), so this connects directly over
# the SQL protocol as the server admin and creates a contained database user
# scoped to sql_database_name - the same least-privilege login the running
# application uses (DB_USER/DB_PASSWORD).
#
# db_ddladmin is included alongside db_datareader/db_datawriter because the
# application relies on Hibernate's ddl-auto=update to create its schema on
# first startup rather than a separate migration step - discovered the hard
# way when the first deployment's Container App returned 500s with
# "CREATE TABLE permission denied" until this role was granted.
resource "mssql_user" "app" {
  server {
    host = azurerm_mssql_server.this.fully_qualified_domain_name
    login {
      username = var.sql_admin_login
      password = var.sql_admin_password
    }
  }

  database = azurerm_mssql_database.this.name
  username = var.db_app_user
  password = var.db_app_password
  roles    = ["db_datareader", "db_datawriter", "db_ddladmin"]

  # Needs firewall access to connect, and needs to wait for that rule to
  # actually propagate - see developer_access / sql_firewall_propagation in
  # 20-sql.tf.
  depends_on = [time_sleep.sql_firewall_propagation]
}
