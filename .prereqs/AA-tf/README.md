# Publish private Spectral rulesets with Terraform

This example provisions the Azure Artifacts side of a private npm registry for Spectral rulesets. It also creates Entra security groups for publishers and consumers, then grants those groups the minimum feed roles, within Azure DevOps _("ADO")_, needed for their workflows.

_(Do not point this example code at an employer tenant or organization without approval.)_

## What Terraform manages

- Two Entra security groups: `<nickname>.EnterpriseSpectralRulesets.Publishers` and
	`<nickname>.EnterpriseSpectralRulesets.Consumers`.
- Membership for the publisher service principals and consumer principals
	supplied as object IDs.
- A project-scoped Azure Artifacts feed named `<nickname>FeedForEnterpriseSpectralRulesets`, with the following access grants:
    - `contributor` access for `<nickname>.EnterpriseSpectralRulesets.Publishers`
    - `reader` access for `<nickname>.EnterpriseSpectralRulesets.Consumers`

Sadly, the  Terraform provider does not expose feed-view or upstream
configuration resources.

After applying, verify the feed's `@local` view is the only view and configure upstreams as disabled in Azure DevOps. Do not assume the Terraform provider has enforced those settings.

## Prerequisites

- Terraform 1.10 or newer.
- Azure CLI authenticated to a demo Entra tenant, with:
    - permission to:
        - create Entra security groups
        - manage their membership
    - ADO access to a demo organization and demo project, including permission to:
        - create a feed
        - manage feed permissions.

Sign in before running Terraform.  For example:

```powershell
az login --tenant <demo-tenant-id>
```

Set the values used by the helper scripts in the current user's environment.  For example:

```powershell
[Environment]::SetEnvironmentVariable('DEMOS_my_entra_tenant_id', '<demo-tenant-id>', 'User')
[Environment]::SetEnvironmentVariable('DEMOS_my_ado_organization_url', 'https://dev.azure.com/<demo-org>', 'User')
[Environment]::SetEnvironmentVariable('DEMOS_my_ado_project_name', '<demo-project-name>', 'User')
[Environment]::SetEnvironmentVariable('DEMOS_my_workload_nickname', '<demo-workload-nickname>', 'User')
```

You will have to further modify this codebase and better parameterize it if you want to make anyone but your own CLI-logged-in Entra principal the owner/member of the Entra groups being created.

## Run

From this directory, initialize and inspect the plan.  For example:

```powershell
.\zzz-run-something-like-this-to-plan.ps1
```

The helper scripts read tenant, organization URL, and project ID from the current user's environment variables.

The provider uses the active Azure CLI identity; no credentials are stored in this repository.
