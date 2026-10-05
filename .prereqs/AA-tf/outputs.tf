output "project_names_list" {
  value = data.azuredevops_projects.allprojs.projects.*.name
}
