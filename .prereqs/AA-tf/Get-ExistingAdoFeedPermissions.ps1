$ErrorActionPreference = 'Stop'
$query = [Console]::In.ReadToEnd() | ConvertFrom-Json -ErrorAction 'Stop'
$organizationUrl = [string]$query.organization_url
$projectName = [string]$query.project_name
$feedId = [string]$query.feed_id

if ([string]::IsNullOrWhiteSpace($organizationUrl)) {
    throw 'organization_url must be provided in the external data source query.'
}
if ([string]::IsNullOrWhiteSpace($projectName)) {
    throw 'project_name is required when scope is project.'
}
if ([string]::IsNullOrWhiteSpace($feedId)) {
    throw 'feed_id is required when scope is project.'
}

$permissions = [System.Collections.Generic.List[object]]::new()
$continuationToken = $null

do {
    $azArgs = @(
        'devops', 'invoke',
        '--http-method', 'GET',
        '--api-version', '7.1',
        '--organization', $organizationUrl,
        '--area', 'packaging',
        '--route-parameters', "project=`"$projectName`"", "feedId=`"$feedId/permissions`""
        '--resource', 'feeds',
        '--output', 'json'
    )
    if ($continuationToken) {
        $azArgs += @('--continuation-token', $continuationToken)
    }

    $pageJson = & az @azArgs
    if ($LASTEXITCODE -ne 0) {
        throw "az devops invoke failed with exit code $LASTEXITCODE."
    }

    $page = ConvertFrom-Json -InputObject ($pageJson -join "`n") -ErrorAction Stop
    foreach ($permission in $page.value) {
        $permissions.Add($permission)
    }

    $tokenValue = $page.continuationToken
    if ($tokenValue -is [array]) {
        $continuationToken = [string]$tokenValue[0]
    }
    else {
        $continuationToken = [string]$tokenValue
    }
} while (-not [string]::IsNullOrWhiteSpace($continuationToken))

$foundPermissions = @($permissions | Where-Object { $true })
$foundPermissions | ForEach-Object {
    ( `
        az devops invoke `
        --area 'ims' `
        --resource 'identities' `
        --http-method 'GET' `
        --api-version '7.1' `
        --organization $organizationUrl `
        --query-parameters "descriptors=`"$($_.identityDescriptor)`"" `
        --query 'value[0].{providerDisplayName:providerDisplayName}'
    )
}
