terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

resource "azurerm_resource_group" "task_board" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_service_plan" "task_board" {
  name                = var.app_service_plan_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "task_board" {
  name                = var.app_service_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  service_plan_id     = azurerm_service_plan.task_board.id

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }
  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.task_board.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.task_board.name};User ID=${azurerm_mssql_server.task_board.administrator_login};Password=${azurerm_mssql_server.task_board.administrator_login_password};Trusted_Connection=False; MultipleActiveResultSets=True;"
  }
}

resource "azurerm_mssql_server" "task_board" {
  name                         = var.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.resource_group_location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
}

resource "azurerm_mssql_database" "task_board" {
  name           = var.sql_database_name
  server_id      = azurerm_mssql_server.task_board.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "S0"
  zone_redundant = false
}

resource "azurerm_mssql_firewall_rule" "task_board" {
  name             = var.firewall_rule_name
  server_id        = azurerm_mssql_server.task_board.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_app_service_source_control" "task_board" {
  app_id                 = azurerm_linux_web_app.task_board.id
  repo_url               = var.repo_URL
  branch                 = "main"
  use_manual_integration = true
}
