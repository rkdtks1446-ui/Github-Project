$ErrorActionPreference = 'Stop'
$repo = 'rkdtks1446-ui/Gitgub-Project'
$seedPath = Join-Path $PSScriptRoot '..\data\backlog-seed.json'
$seed = Get-Content -Raw -Encoding UTF8 $seedPath | ConvertFrom-Json

$oldPrompt = $env:GIT_TERMINAL_PROMPT
$oldInteractive = $env:GCM_INTERACTIVE
$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE = 'never'

try {
    $credentialLines = "protocol=https`nhost=github.com`n`n" | git credential fill 2>$null
    $credential = @{}
    foreach ($line in $credentialLines) {
        if ($line -match '^([^=]+)=(.*)$') {
            $credential[$matches[1]] = $matches[2]
        }
    }
    $token = $credential['password']
    if ([string]::IsNullOrWhiteSpace($token)) {
        throw 'No cached GitHub credential. Authenticate with Git Credential Manager first.'
    }

    $headers = @{
        Accept = 'application/vnd.github+json'
        Authorization = "Bearer $token"
        'User-Agent' = 'Gitgub-Project-backlog-seed'
        'X-GitHub-Api-Version' = '2022-11-28'
    }

    function Invoke-GitHubApi {
        param(
            [Parameter(Mandatory)][string]$Method,
            [Parameter(Mandatory)][string]$Path,
            [object]$Body
        )

        $request = @{
            Method = $Method
            Uri = "https://api.github.com$Path"
            Headers = $headers
        }
        if ($PSBoundParameters.ContainsKey('Body')) {
            $request.ContentType = 'application/json; charset=utf-8'
            $request.Body = ConvertTo-Json -InputObject $Body -Depth 12 -Compress
        }
        Invoke-RestMethod @request
    }

    $labelSpecs = @(
        @{ name = 'type: feature'; color = '1F883D'; description = 'User-facing feature' }
        @{ name = 'type: bug'; color = 'D1242F'; description = 'Reproducible defect' }
        @{ name = 'type: chore'; color = '6E7781'; description = 'Maintenance or technical work' }
        @{ name = 'priority: P0'; color = 'B60205'; description = 'Immediate priority' }
        @{ name = 'priority: P1'; color = 'FBCA04'; description = 'Sprint priority' }
        @{ name = 'priority: P2'; color = 'D4C5F9'; description = 'Follow-up priority' }
        @{ name = 'area: discovery'; color = '0E8A16'; description = 'Requirements and research' }
        @{ name = 'area: design'; color = 'C5DEF5'; description = 'UX and accessibility' }
        @{ name = 'area: frontend'; color = '1D76DB'; description = 'Frontend implementation' }
        @{ name = 'area: backend'; color = '5319E7'; description = 'Data and business logic' }
        @{ name = 'area: testing'; color = 'F9D0C4'; description = 'Quality and testing' }
        @{ name = 'area: release'; color = '0052CC'; description = 'CI and release work' }
        @{ name = 'size: XS'; color = 'EDEDED'; description = '1 story point' }
        @{ name = 'size: S'; color = 'BFD4F2'; description = '2 story points' }
        @{ name = 'size: M'; color = '84B6EB'; description = '3 story points' }
        @{ name = 'size: L'; color = '1D76DB'; description = '5 story points' }
    )

    $existingLabels = @(Invoke-GitHubApi GET "/repos/$repo/labels?per_page=100")
    foreach ($label in $labelSpecs) {
        if (-not ($existingLabels | Where-Object { $_.name -eq $label.name })) {
            Invoke-GitHubApi POST "/repos/$repo/labels" $label | Out-Null
        }
    }

    $existingMilestones = @(Invoke-GitHubApi GET "/repos/$repo/milestones?state=all&per_page=100")
    $milestones = @{}
    foreach ($milestoneSpec in $seed.milestones) {
        $milestone = $existingMilestones | Where-Object { $_.title -eq $milestoneSpec.title } | Select-Object -First 1
        if (-not $milestone) {
            $milestone = Invoke-GitHubApi POST "/repos/$repo/milestones" @{
                title = $milestoneSpec.title
                description = $milestoneSpec.description
            }
            $existingMilestones += $milestone
        }
        $milestones[$milestoneSpec.title] = $milestone.number
    }

    $existingIssues = @(Invoke-GitHubApi GET "/repos/$repo/issues?state=all&per_page=100")
    foreach ($issueSpec in $seed.issues) {
        $issue = $null
        if ($issueSpec.existing_number) {
            $issue = $existingIssues | Where-Object { $_.number -eq $issueSpec.existing_number } | Select-Object -First 1
        }
        if (-not $issue) {
            $marker = "backlog-key: $($issueSpec.key)"
            $issue = $existingIssues | Where-Object { $_.body -and $_.body.Contains($marker) } | Select-Object -First 1
        }

        $body = "$($issueSpec.body)`n`n<!-- backlog-key: $($issueSpec.key) -->"
        $payload = @{
            title = $issueSpec.title
            body = $body
            labels = @($issueSpec.labels)
            milestone = $milestones[$issueSpec.milestone]
        }
        if ($issue) {
            Invoke-GitHubApi PATCH "/repos/$repo/issues/$($issue.number)" $payload | Out-Null
            $issueCount++
        }
        else {
            $createdIssue = Invoke-GitHubApi POST "/repos/$repo/issues" $payload
            $existingIssues += $createdIssue
            $issueCount++
        }
    }

    "Backlog sync complete: $($labelSpecs.Count) labels defined, $($seed.milestones.Count) milestones, $issueCount issues created or updated."
}
finally {
    $token = $null
    if ($credential) { $credential.Clear() }
    $env:GIT_TERMINAL_PROMPT = $oldPrompt
    $env:GCM_INTERACTIVE = $oldInteractive
}