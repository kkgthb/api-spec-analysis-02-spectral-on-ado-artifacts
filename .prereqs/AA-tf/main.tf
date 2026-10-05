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

data "azuredevops_client_config" "current_ado_context" {
  provider = azuredevops.demo
}

data "azuredevops_project" "the_ado_project" {
  provider = azuredevops.demo
  name     = var.ado_project_name
}

data "azuredevops_descriptor" "entra_publishers_group_in_ado" {
  provider = azuredevops.demo
  # TODO:  figure out if this storage key is right or if I'll need it to be 
  # "[TEAM FOUNDATION]\${azuread_group.rulesets_publishers_group.display_name}"
  storage_key = azuread_group.rulesets_publishers_group.id
}

data "azuredevops_descriptor" "entra_consumers_group_in_ado" {
  provider = azuredevops.demo
  # TODO:  figure out if this storage key is right or if I'll need it to be 
  # "[TEAM FOUNDATION]\${azuread_group.rulesets_consumers_group.display_name}"
  storage_key = azuread_group.rulesets_consumers_group.id
}

resource "azuredevops_feed" "rulesets_feed" {
  provider   = azuredevops.demo
  name       = "${var.workload_nickname}FeedForEnterpriseSpectralRulesets"
  project_id = data.azuredevops_project.the_ado_project.id
  # TODO manually:  set visibility to be private / Specific People
  # TODO manually:  set "upstream enabled?" to FALSE
  # TODO manually:  set upstream sources to explicitly empty list
}

resource "azuredevops_feed_permission" "rulesets_feed_contributor_grant" {
  provider            = azuredevops.demo
  feed_id             = azuredevops_feed.rulesets_feed.id
  project_id          = data.azuredevops_project.the_ado_project.id
  identity_descriptor = data.azuredevops_descriptor.entra_publishers_group_in_ado.descriptor
  # "contributor" makes, for example, "npm publish" work.
  role = "contributor"
}

resource "azuredevops_feed_permission" "rulesets_feed_reader_grant" {
  provider            = azuredevops.demo
  feed_id             = azuredevops_feed.rulesets_feed.id
  project_id          = data.azuredevops_project.the_ado_project.id
  identity_descriptor = data.azuredevops_descriptor.entra_consumers_group_in_ado.descriptor
  # "reader" makes, for example, "npm login" followed by "spectral lint" work.
  role = "reader"
}

# TODO manually:  create an Azure Artifacts Feed View named "@local" 
# on azuredevops_feed.rulesets_feed.id 
# with private Visibility 
# and it being TRUE that it's the default.

# TODO manually:  if the following Azure Artifacts Feed Views 
# auto-create on azuredevops_feed.rulesets_feed.id, then delete them:
# 1. "@prerelease"
# 2. "@release"

# TODO:  if not already there (auto & undeleteable?), create an 
# azuredevops_feed_permission grant of "owner" 
# on azuredevops_feed.rulesets_feed.id 
# to the "[data.azuredevops_client_config.current_ado_context.name]\Project Collection Administrators" identity descriptor
# TODO:  document why this is desirable (break-glass maybe?),
# and if it's not, document that 
# if it ever were to become non-auto, actually, we'd move it to the delete list.

# TODO manually:  if any of the following azuredevops_feed_permission 
# auto-created on azuredevops_feed.rulesets_feed.id, then delete them:
# 1. "owner" for data.azuread_client_config.current_entra_context.object_id
# 2. "collaborator" for the parent ADO project's "build service".
#    Unsure exactly how it'd show up.  Some guesses are:
#       A. "${var.ado_project_name} Build Service (${data.azuredevops_client_config.current_ado_context.name})"
#       B. option A, but with spaces back into it if they exist in the project's details?
#       C. a GUID
# 3. "owner" for "[${var.ado_project_name}]\Project Administrators".
#    (This helps ensure that your feed is all yours, 
#    in big wide open ADO projects.  No need to let meddlers introduce drift.)
# 4. "collaborator" for "[${var.ado_project_name}]\Contributors".
#    (If your ADO project's collaborators want in, 
#    they can ask to be added to one of your Entra security groups for this feed.)


