data "azuread_client_config" "current_entra_context" {
  provider = azuread.demo
}

resource "azuread_group" "rulesets_publishers_group" {
  provider         = azuread.demo
  display_name     = "${var.workload_nickname}.EnterpriseSpectralRulesets.Publishers"
  description      = "Can publish our enterprise Spectral ruleset packages."
  security_enabled = true
  mail_enabled     = false
  # For now, will just add "self" as as the owner of this Entra group, for sake of demo.
  owners = [data.azuread_client_config.current_entra_context.object_id]
}

resource "azuread_group_member" "rulesets_publishers_group_members" {
  provider = azuread.demo
  # For now, will just add "self" as as the only member of this Entra group, for sake of demo.
  for_each         = toset([data.azuread_client_config.current_entra_context.object_id])
  group_object_id  = azuread_group.rulesets_publishers_group.id
  member_object_id = each.value
}

resource "azuread_group" "rulesets_consumers_group" {
  provider         = azuread.demo
  display_name     = "${var.workload_nickname}.EnterpriseSpectralRulesets.Readers"
  description      = "Can consume our enterprise Spectral ruleset packages."
  security_enabled = true
  mail_enabled     = false
  # For now, will just add "self" as as the owner of this Entra group, for sake of demo.
  owners = [data.azuread_client_config.current_entra_context.object_id] # Add self as a publisher, just for sake of demo
}

resource "azuread_group_member" "rulesets_consumers_group_members" {
  provider = azuread.demo
  # For now, will just add "self" as as the only member of this Entra group, for sake of demo.
  for_each         = toset([data.azuread_client_config.current_entra_context.object_id])
  group_object_id  = azuread_group.rulesets_consumers_group.id
  member_object_id = each.value
}

data "azuredevops_project" "the_ado_project" {
  provider = azuredevops.demo
  name     = var.ado_project_name
}

resource "azuredevops_feed" "rulesets_feed" {
  provider   = azuredevops.demo
  name       = "${var.workload_nickname}FeedForEnterpriseSpectralRulesets"
  project_id = data.azuredevops_project.the_ado_project.id
}

data "azuredevops_descriptor" "entra_publishers_group_in_ado" {
  provider    = azuredevops.demo
  storage_key = azuread_group.rulesets_publishers_group.id
}

resource "azuredevops_feed_permission" "rulesets_feed_contributor_grant" {
  provider            = azuredevops.demo
  feed_id             = azuredevops_feed.rulesets_feed.id
  project_id          = data.azuredevops_project.the_ado_project.id
  identity_descriptor = data.azuredevops_descriptor.entra_publishers_group_in_ado.descriptor
  role                = "contributor"
}

data "azuredevops_descriptor" "entra_consumers_group_in_ado" {
  provider    = azuredevops.demo
  storage_key = azuread_group.rulesets_consumers_group.id
}

resource "azuredevops_feed_permission" "rulesets_feed_reader_grant" {
  provider            = azuredevops.demo
  feed_id             = azuredevops_feed.rulesets_feed.id
  project_id          = data.azuredevops_project.the_ado_project.id
  identity_descriptor = data.azuredevops_descriptor.entra_consumers_group_in_ado.descriptor
  role                = "reader"
}
