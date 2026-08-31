resource "azurerm_container_app" "this" {
  name                         = var.container_app_name
  resource_group_name          = azurerm_resource_group.this.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca.id]
  }

  registry {
    server   = azurerm_container_registry.this.login_server
    identity = azurerm_user_assigned_identity.aca.id
  }

  # Versionless secret URI so Key Vault secret rotation doesn't require a
  # Terraform change - ACA resolves the latest version at read time.
  secret {
    name                = "db-password"
    key_vault_secret_id = azurerm_key_vault_secret.db_password.versionless_id
    identity            = azurerm_user_assigned_identity.aca.id
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.container_min_replicas
    max_replicas = var.container_max_replicas

    container {
      name   = "item-catalog-service"
      image  = "${azurerm_container_registry.this.login_server}/${var.container_image_repository}:${var.container_image_tag}"
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "DB_HOST"
        value = azurerm_mssql_server.this.fully_qualified_domain_name
      }
      env {
        name  = "DB_PORT"
        value = "1433"
      }
      env {
        name  = "DB_NAME"
        value = azurerm_mssql_database.this.name
      }
      env {
        name  = "DB_USER"
        value = var.db_app_user
      }
      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }
    }
  }

  # Ensures the identity already has AcrPull + Key Vault Secrets User (and
  # RBAC has had time to propagate) before the first revision tries to pull
  # the image or read the secret, and that the app's SQL login already
  # exists before Hibernate's first startup attempt (see role-assignments.tf,
  # 21-sql-user.tf). The one dependency this can't express: the image itself
  # must already be pushed to ACR before this apply runs - azurerm has no
  # resource representing "image exists in registry," so that step stays a
  # documented external prerequisite (README.md).
  depends_on = [time_sleep.aca_rbac_propagation, mssql_user.app]

  tags = local.common_tags
}
