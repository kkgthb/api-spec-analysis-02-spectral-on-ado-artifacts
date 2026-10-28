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

# This used to need a filter in the script I borrowed it from.  $true placeholder reminds me how to put one back.
$foundPermissions = @($permissions | Where-Object { $true })
$identityDescriptors = @(
    $foundPermissions |
    ForEach-Object { [string]$_.identityDescriptor } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Select-Object -Unique
)

$identityByDescriptor = @{}
if ($identityDescriptors.Count -gt 0) {
    $maximumDescriptorQueryLength = 1600
    $identityDescriptorBatches = [System.Collections.Generic.List[object]]::new()
    $identityDescriptorBatch = [System.Collections.Generic.List[string]]::new()
    $identityDescriptorBatchLength = 0

    foreach ($descriptor in $identityDescriptors) {
        $additionalLength = $descriptor.Length + [int]($identityDescriptorBatch.Count -gt 0)
        if ($identityDescriptorBatch.Count -gt 0 -and ($identityDescriptorBatchLength + $additionalLength) -gt $maximumDescriptorQueryLength) {
            $identityDescriptorBatches.Add($identityDescriptorBatch.ToArray())
            $identityDescriptorBatch.Clear()
            $identityDescriptorBatchLength = 0
            $additionalLength = $descriptor.Length
        }
        $identityDescriptorBatch.Add($descriptor)
        $identityDescriptorBatchLength += $additionalLength
    }
    if ($identityDescriptorBatch.Count -gt 0) {
        $identityDescriptorBatches.Add($identityDescriptorBatch.ToArray())
    }

    foreach ($identityDescriptorBatch in $identityDescriptorBatches) {
        $identityArgs = @(
            'devops', 'invoke',
            '--area', 'ims',
            '--resource', 'identities',
            '--http-method', 'GET',
            '--api-version', '7.1',
            '--organization', $organizationUrl,
            '--query-parameters', "descriptors=$($identityDescriptorBatch -join ',')", 'queryMembership=None',
            '--query', 'value[].{descriptor:descriptor,providerDisplayName:providerDisplayName}',
            '--output', 'json'
        )
        $identitiesJson = & az @identityArgs
        if ($LASTEXITCODE -ne 0) {
            throw "az devops invoke identity lookup failed with exit code $LASTEXITCODE."
        }

        $identities = ConvertFrom-Json -InputObject ($identitiesJson -join "`n") -ErrorAction Stop
        foreach ($identity in @($identities)) {
            $identityByDescriptor[[string]$identity.descriptor] = [string]$identity.providerDisplayName
        }
    }
}

foreach ($permission in $foundPermissions) {
    $descriptor = [string]$permission.identityDescriptor
    $providerDisplayName = if ($identityByDescriptor.ContainsKey($descriptor)) {
        $identityByDescriptor[$descriptor]
    }
    else {
        ''
    }
    $permission | Add-Member -NotePropertyName 'identityDescriptorProviderDisplayName' -NotePropertyValue $providerDisplayName -Force
}
ConvertTo-Json -InputObject @($foundPermissions) -Depth 100 -Compress
