output "ado_ruleset_feed_id" {
  value = azuredevops_feed.rulesets_feed.id
}

output "entra_publishers_group_object_id" {
  value = azuread_group.rulesets_publishers_group.id
}

output "entra_consumers_group_object_id" {
  value = azuread_group.rulesets_consumers_group.id
}
