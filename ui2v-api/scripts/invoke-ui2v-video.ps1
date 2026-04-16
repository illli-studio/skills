param(
    [Parameter(Mandatory = $true)]
    [string]$Prompt,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [int]$Width = 1080,
    [int]$Height = 1080,

    [ValidateSet('mp4', 'webm')]
    [string]$Format = 'mp4',

    [ValidateSet('low', 'medium', 'high', 'ultra', 'cinema')]
    [string]$Quality = 'medium',

    [string]$Style,

    [string]$BaseUrl = 'http://127.0.0.1:5125',

    [int]$PollIntervalSeconds = 8,

    [int]$TimeoutMinutes = 30,

    [switch]$Overwrite
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ui2v-common.ps1')

$resolvedOutput = Resolve-Ui2vOutputPath -OutputFile $OutputFile -Overwrite $Overwrite.IsPresent
Assert-Ui2vAvailable -BaseUrl $BaseUrl

$payload = [ordered]@{
    prompt  = $Prompt
    format  = $Format
    width   = $Width
    height  = $Height
    quality = $Quality
}

if ($Style) {
    $payload.style = $Style
}

Invoke-Ui2vJob `
    -BaseUrl $BaseUrl `
    -Endpoint 'video' `
    -Payload $payload `
    -ExpectedMediaTypePattern 'video/*' `
    -OutputFile $resolvedOutput `
    -PollIntervalSeconds $PollIntervalSeconds `
    -TimeoutMinutes $TimeoutMinutes `
    -JobLabel 'UI2V video job'
