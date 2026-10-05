# Configure the azuredevops provider
provider "azuredevops" {
  alias           = "demo"
  org_service_url = var.ado_org_url
  use_cli         = true # Log into Azure DevOps as whoever is currently logged in within the Azure CLI
}
