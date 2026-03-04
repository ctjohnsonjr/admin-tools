[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Root = ".",
    [switch]$Force,
    [switch]$WhatIf,
    [int]$ReadSize = 1024
)

if (-not (Test-Path $Root)) {
    Write-Error "Root path '$Root' does not exist."
    exit 1
}

$partZeros = Get-ChildItem -Path $Root -File -Filter "*.part0.iso" -ErrorAction SilentlyContinue
$partZeros | ForEach-Object {
    $baseName = $_.BaseName -replace "\.part0$"
    $partsPathExpression = Join-Path $Root "$baseName.part?.iso"
    $output = Join-Path $Root "$baseName.iso"
    Write-Host "Combining parts for '$output'"
    if ($WhatIf) {
        Write-Host "Get-Content -Path '$partsPathExpression' -AsByteStream -Read $ReadSize | Set-Content -Path '$output' -AsByteStream"
    } 
    else {
        Get-Content -Path $partsPathExpression -AsByteStream -Read $ReadSize | Set-Content -Path $output -AsByteStream
    }
}