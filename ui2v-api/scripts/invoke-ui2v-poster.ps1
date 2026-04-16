param(
    [Parameter(Mandatory = $true)]
    [string]$Prompt,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [int]$Width = 1080,
    [int]$Height = 1080,

    [ValidateSet('png', 'jpg')]
    [string]$Format = 'png',

    [string]$Style,

    [string]$BaseUrl = 'http://127.0.0.1:5125',

    [int]$PollIntervalSeconds = 5,

    [int]$TimeoutMinutes = 20,

    [switch]$Overwrite
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ui2v-common.ps1')

$resolvedOutput = Resolve-Ui2vOutputPath -OutputFile $OutputFile -Overwrite $Overwrite.IsPresent
Assert-Ui2vAvailable -BaseUrl $BaseUrl

$payload = [ordered]@{
    prompt = $Prompt
    format = $Format
    width  = $Width
    height = $Height
}

if ($Style) {
    $payload.style = $Style
}

Invoke-Ui2vJob `
    -BaseUrl $BaseUrl `
    -Endpoint 'poster' `
    -Payload $payload `
    -ExpectedMediaTypePattern 'image/*' `
    -OutputFile $resolvedOutput `
    -PollIntervalSeconds $PollIntervalSeconds `
    -TimeoutMinutes $TimeoutMinutes `
    -JobLabel 'UI2V poster job'
