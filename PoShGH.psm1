function Get-Repositories {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Organization
    )
    begin {
        # https://docs.github.com/en/rest/repos/repos#list-organization-repositories
        $uri = "https://api.github.com/orgs/{0}/repos" -f ($Organization)

        if ([String]::IsNullOrEmpty($env:GH_TOKEN)) {
            throw "Token is null or empty. Populate the GH_TOKEN environment variable with a GitHub API authentication token."
        }

        $Headers = @{
            "Accept"               = "application/vnd.github+json"
            "Authorization"        = "Bearer $env:GH_TOKEN"
            "X-GitHub-Api-Version" = "2022-11-28"
        }
    }
    process {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers

        return $response
    }
}
function Get-RepositoryWorkflows {
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByOrganizationAndRepository')]
        [ValidateNotNullOrEmpty()]
        [String]$Organization,
        [Parameter(Mandatory, ParameterSetName = 'ByOrganizationAndRepository')]
        [ValidateNotNullOrEmpty()]
        [String]$Repository,
        [Parameter(Mandatory, ParameterSetName = 'ByFullName')]
        [ValidateNotNullOrEmpty()]
        [String]$FullName
    )
    begin {
        # https://docs.github.com/en/rest/actions/workflows#list-repository-workflows
        if ($PSCmdlet.ParameterSetName -eq 'ByOrganizationAndRepository') {
            $uri = "https://api.github.com/repos/{0}/{1}/actions/workflows" -f ($Organization, $Repository)
        }
        if ($PSCmdlet.ParameterSetName -eq 'ByFullName') {
            $uri = "https://api.github.com/repos/{0}/actions/workflows" -f ($FullName)
        }

        if ([String]::IsNullOrEmpty($env:GH_TOKEN)) {
            throw "Token is null or empty. Populate the GH_TOKEN environment variable with a GitHub API authentication token."
        }

        $Headers = @{
            "Accept"               = "application/vnd.github+json"
            "Authorization"        = "Bearer $env:GH_TOKEN"
            "X-GitHub-Api-Version" = "2022-11-28"
        }
    }
    process {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers

        return $response
    }
}
function Get-RepositoriesWithWorkflows {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Organization
    )
    process {
        $orgRepos = Get-Repositories -Organization $Organization
        
        $outputList = New-Object System.Collections.Generic.List[PSCustomObject]
        foreach ($repo in $orgRepos) {
            $repoWorkflows = Get-RepositoryWorkflows -FullName $repo.full_name
            if ([int]$repoWorkflows.total_count -gt 0) {
                $outputList.Add($repo)
            }
        }

        return $outputList
    }
}
function Get-WorkflowRuns {
    param (
        [ValidateNotNullOrEmpty()]
        [Parameter(ParameterSetName = 'ByOrgRepoWorkflowId', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ByOrgRepo', Mandatory = $true)]
        [string]$Organization,
        [ValidateNotNullOrEmpty()]
        [Parameter(ParameterSetName = 'ByOrgRepoWorkflowId', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ByOrgRepo', Mandatory = $true)]
        [string]$Repository,
        [ValidateNotNullOrEmpty()]
        [Parameter(ParameterSetName = 'ByOrgRepoWorkflowId', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ByFullNameWorkflowId', Mandatory = $true)]
        [string]$WorkflowId,
        [ValidateNotNullOrEmpty()]
        [Parameter(ParameterSetName = 'ByFullNameWorkflowId', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ByFullName', Mandatory = $true)]
        [string]$FullName
    )
    begin {
        # https://docs.github.com/en/rest/actions/workflow-runs#list-workflow-runs-for-a-repository
        # https://docs.github.com/en/rest/actions/workflow-runs#list-workflow-runs-for-a-workflow
        switch ($PSCmdlet.ParameterSetName) {
            'ByOrgRepo' {
                $uri = "https://api.github.com/repos/{0}/{1}/actions/runs" -f ($Organization, $Repository)
            }
            'ByFullName' {
                $uri = "https://api.github.com/repos/{0}/actions/runs" -f ($FullName)
            }
            'ByOrgRepoWorkflowId' {
                $uri = "https://api.github.com/repos/{0}/{1}/actions/workflows/{2}/runs" -f ($Organization, $Repository, $WorkflowId)
            }
            'ByFullNameWorkflowId' {
                $uri = "https://api.github.com/repos/{0}/actions/workflows/{1}/runs" -f ($FullName, $WorkflowId)
            }
        }

        if ([String]::IsNullOrEmpty($env:GH_TOKEN)) {
            throw "Token is null or empty. Populate the GH_TOKEN environment variable with a GitHub API authentication token."
        }

        $Headers = @{
            "Accept"               = "application/vnd.github+json"
            "Authorization"        = "Bearer $env:GH_TOKEN"
            "X-GitHub-Api-Version" = "2022-11-28"
        }
    }
    process {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers

        return $response
    }   
}
function Get-WorkflowRunLogs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByOrganizationAndRepository')]
        [ValidateNotNullOrEmpty()]
        [String]$Organization,
        [Parameter(Mandatory, ParameterSetName = 'ByOrganizationAndRepository')]
        [ValidateNotNullOrEmpty()]
        [String]$Repository,
        [Parameter(Mandatory, ParameterSetName = 'ByFullName')]
        [ValidateNotNullOrEmpty()]
        [String]$FullName,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [String]$RunId
    )
    begin {
        # https://docs.github.com/en/rest/actions/workflow-runs?#download-workflow-run-logs
        if ($PSCmdlet.ParameterSetName -eq 'ByOrganizationAndRepository') {
            $uri = "https://api.github.com/repos/{0}/{1}/actions/runs/{2}/logs" -f ($Organization, $Repository, $RunId)
            $logSaveDirectory = [IO.Path]::Combine((Get-Location), "Logs", "$Organization", "$Repository")
        }
        if ($PSCmdlet.ParameterSetName -eq 'ByFullName') {
            $uri = "https://api.github.com/repos/{0}/actions/runs/{1}/logs" -f ($FullName, $RunId)

            $nameArray = $FullName -split '/'
            $logSaveDirectory = [IO.Path]::Combine((Get-Location), "Logs", $nameArray[0], $nameArray[1])
        }

        if (!(Test-Path $logSaveDirectory)) {
            New-Item -ItemType Directory -Path $logSaveDirectory
        }

        if ([String]::IsNullOrEmpty($env:GH_TOKEN)) {
            throw "Token is null or empty. Populate the GH_TOKEN environment variable with a GitHub API authentication token."
        }

        $Headers = @{
            "Accept"               = "application/vnd.github+json"
            "Authorization"        = "Bearer $env:GH_TOKEN"
            "X-GitHub-Api-Version" = "2022-11-28"
        }

        $logSavePath = [IO.Path]::Combine($logSaveDirectory, "$RunId.zip")
    }
    process {
        Write-Verbose -Message "Saving logs from $uri to $logSavePath."
        Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers -OutFile $logSavePath
    }
}