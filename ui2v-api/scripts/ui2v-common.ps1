Add-Type -AssemblyName System.Net.Http

function Resolve-Ui2vAbsolutePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Path))
}

function Ensure-Ui2vParentDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    }
}

function Test-Ui2vAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    try {
        Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 3 | Out-Null
        return $true
    }
    catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 404) {
            return $true
        }

        return $false
    }
}

function Resolve-Ui2vOutputPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $true)]
        [bool]$Overwrite
    )

    $resolvedOutput = Resolve-Ui2vAbsolutePath -Path $OutputFile
    if ((Test-Path -LiteralPath $resolvedOutput) -and (-not $Overwrite)) {
        throw "Output file already exists: $resolvedOutput. Use -Overwrite to replace it."
    }

    return $resolvedOutput
}

function Assert-Ui2vAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl
    )

    if (-not (Test-Ui2vAvailable -Url $BaseUrl)) {
        throw "UI2V is not reachable at $BaseUrl. Start the UI2V desktop app first."
    }
}

function Submit-Ui2vJob {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$PayloadJson,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedMediaTypePattern
    )

    $handler = [System.Net.Http.HttpClientHandler]::new()
    $client = [System.Net.Http.HttpClient]::new($handler)
    try {
        $content = [System.Net.Http.StringContent]::new($PayloadJson, [System.Text.Encoding]::UTF8, 'application/json')
        $response = $client.PostAsync($Url, $content).GetAwaiter().GetResult()
        try {
            $mediaType = ''
            if ($response.Content.Headers.ContentType) {
                $mediaType = [string]$response.Content.Headers.ContentType.MediaType
            }

            $response.EnsureSuccessStatusCode() | Out-Null

            if ($mediaType -like $ExpectedMediaTypePattern) {
                $bytes = $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
                return [pscustomobject]@{
                    Kind = 'binary'
                    MediaType = $mediaType
                    Bytes = $bytes
                }
            }

            $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            return [pscustomobject]@{
                Kind = 'json'
                MediaType = $mediaType
                Body = $body
            }
        }
        finally {
            $response.Dispose()
        }
    }
    finally {
        $client.Dispose()
        $handler.Dispose()
    }
}

function Invoke-Ui2vJob {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$Endpoint,

        [Parameter(Mandatory = $true)]
        [hashtable]$Payload,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedMediaTypePattern,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $true)]
        [int]$PollIntervalSeconds,

        [Parameter(Mandatory = $true)]
        [int]$TimeoutMinutes,

        [Parameter(Mandatory = $true)]
        [string]$JobLabel
    )

    $submitUrl = "$BaseUrl/$Endpoint"
    $payloadJson = $Payload | ConvertTo-Json -Compress
    Write-Host "Submitting $JobLabel to $submitUrl"
    $submitResponse = Submit-Ui2vJob -Url $submitUrl -PayloadJson $payloadJson -ExpectedMediaTypePattern $ExpectedMediaTypePattern

    if ($submitResponse.Kind -eq 'binary') {
        Ensure-Ui2vParentDirectory -Path $OutputFile
        [System.IO.File]::WriteAllBytes($OutputFile, $submitResponse.Bytes)
        return Get-Item -LiteralPath $OutputFile
    }

    $submitBody = $submitResponse.Body
    try {
        $job = $submitBody | ConvertFrom-Json
    }
    catch {
        throw "$JobLabel returned neither expected media bytes nor JSON job metadata. Raw response: $submitBody"
    }

    if (-not $job.requestId) {
        throw "Submit response is missing requestId. Raw response: $submitBody"
    }

    $requestId = [string]$job.requestId
    $statusUrl = "$BaseUrl/status/$requestId"
    $resultUrl = "$BaseUrl/result/$requestId"
    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)

    Write-Host "Waiting for request $requestId"
    do {
        $status = Invoke-RestMethod -Uri $statusUrl -Method Get -TimeoutSec 60
        $statusValue = [string]$status.status

        if ($statusValue -eq 'completed') {
            Ensure-Ui2vParentDirectory -Path $OutputFile
            Invoke-WebRequest -Uri $resultUrl -OutFile $OutputFile -TimeoutSec 600
            return Get-Item -LiteralPath $OutputFile
        }

        if ($statusValue -eq 'failed') {
            $statusJson = $status | ConvertTo-Json -Depth 8
            throw "$JobLabel failed: $statusJson"
        }

        Write-Host "Current status: $statusValue"
        Start-Sleep -Seconds $PollIntervalSeconds
    } while ((Get-Date) -lt $deadline)

    throw "Timed out waiting for $JobLabel after $TimeoutMinutes minutes."
}
