# Reminder:  to run this Terraform code successfully, 
# you must be logged into the Azure DevOps CLI as an Entra principal that has adequate permissions to manipulate 
# both Azure DevOps and Entra.

Push-Location("$PsScriptRoot")

terraform destroy `
    -var entra_tenant_id="$([Environment]::GetEnvironmentVariable('DEMOS_my_entra_tenant_id', 'User'))" `
    -var ado_org_url="$([Environment]::GetEnvironmentVariable('DEMOS_my_ado_organization_url', 'User'))" `
    -var workload_nickname="$([Environment]::GetEnvironmentVariable('DEMOS_my_workload_nickname', 'User'))" `
    -input=false `
    -auto-approve

Pop-Location