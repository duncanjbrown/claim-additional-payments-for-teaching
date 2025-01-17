module "container" {
  source                = "./modules/container"
  app_rg_name           = format("%s-%s", var.rg_prefix, "app")
  container_version     = var.input_container_version
  rg_prefix             = var.rg_prefix
  rg_location           = var.input_region
  common_tags           = local.tags
  app_name              = var.app_name
  db_host                 = data.azurerm_postgresql_server.app.fqdn
  db_admin_username       = data.azurerm_postgresql_server.app.administrator_login
  db_name                 = local.db_name
  environment             = var.environment
  canonical_hostname      = var.canonical_hostname
  bypass_dfe_sign_in      = var.bypass_dfe_sign_in
}

module "app_service" {
  source                  = "./modules/app_service"
  app_rg_name             = local.app_rg_name
  input_container_version = var.input_container_version
  rg_prefix               = var.rg_prefix
  rg_location             = var.input_region
  common_tags             = local.tags
  app_name                = var.app_name
  db_host                 = data.azurerm_postgresql_server.app.fqdn
  db_admin_username       = data.azurerm_postgresql_server.app.administrator_login
  db_name                 = local.db_name
  environment             = var.environment
  canonical_hostname      = var.canonical_hostname
  bypass_dfe_sign_in      = var.bypass_dfe_sign_in
  pr_number               = var.pr_number
}
