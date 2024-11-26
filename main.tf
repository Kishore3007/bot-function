provider "azurerm" {
  features {}
  subscription_id = "b53485cb-5756-436f-9d59-bcd7e1019395"
}

resource "azurerm_resource_group" "rg-weatherbot" {
  name     = "rg-weatherbot"
  location = "Central US"
}

resource "azurerm_storage_account" "st-weatherbot" {
  name                     = "stpythonweatherbot"
  resource_group_name       = azurerm_resource_group.rg-weatherbot.name
  location                 = azurerm_resource_group.rg-weatherbot.location
  account_tier              = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "appcontainer" {
  name                  = "functionappcontainer"
  storage_account_id    = azurerm_storage_account.st-weatherbot.id
}

resource "azurerm_storage_blob" "function_zip" {
  name                   = "weatherbot.zip"
  storage_account_name   = azurerm_storage_account.st-weatherbot.name
  storage_container_name = azurerm_storage_container.appcontainer.name
  type                   = "Block"
  source                 = "C:/myproject/botfunction/weatherbot.zip"  # Ensure this path is correct
}

resource "azurerm_app_service_plan" "pl-weatherbot" {
  name                     = "pl-weatherbot"
  location                 = azurerm_resource_group.rg-weatherbot.location
  resource_group_name      = azurerm_resource_group.rg-weatherbot.name
  kind                     = "FunctionApp"
  reserved                 = true  
  sku {
    tier = "Dynamic"
    size = "Y1"  
  }
}

resource "azurerm_function_app" "pythonweatherbot" {
  name                       = "my-python-weatherbot"
  location                   = azurerm_resource_group.rg-weatherbot.location
  resource_group_name        = azurerm_resource_group.rg-weatherbot.name
  app_service_plan_id        = azurerm_app_service_plan.pl-weatherbot.id
  storage_account_name       = azurerm_storage_account.st-weatherbot.name
  storage_account_access_key = azurerm_storage_account.st-weatherbot.primary_access_key
  os_type                    = "linux"
  version                    = "~4"  

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    WEBSITE_RUN_FROM_PACKAGE = "https://${azurerm_storage_account.st-weatherbot.name}.blob.core.windows.net/${azurerm_storage_container.appcontainer.name}/weatherbot.zip?${azurerm_storage_account.st-weatherbot.primary_access_key}"
  }

  site_config {
    linux_fx_version = "PYTHON|3.10"
  }

  depends_on = [azurerm_storage_account.st-weatherbot, azurerm_app_service_plan.pl-weatherbot]
}

output "function_app_url" {
  value = azurerm_function_app.pythonweatherbot.default_hostname
}
