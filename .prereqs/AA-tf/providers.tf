provider "azuread" {
  alias     = "demo"
  tenant_id = var.entra_tenant_id
  use_cli   = true
}

provider "azuredevops" {
  alias           = "demo"
  org_service_url = var.ado_org_url
  use_cli         = true # Log into Azure DevOps as whoever is currently logged in within the Azure CLI
}
