[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory)]
    [string]$Source,
    [Parameter(Position=1, Mandatory)]
    [string]$Destination,
    [switch]$WhatIf,
    [string]$ArchiveDirectoryName = "_cbz",
    [switch]$RemoveEmptyArchive
)
$ArchiveRepos = Get-ChildItem $Source -Recurse -Depth 1 | Where-Object {$_.Name -eq $ArchiveDirectoryName}

$ArchiveRepos | ForEach-Object {
    $archiveDir = $_
    $mangaName = $_.Parent.Name
    $hostedDir = Get-ChildItem -Path $Destination -Filter $mangaName -Directory

    $move_source = Join-Path $archiveDir.FullName "*"
    $move_destination = $hostedDir.FullName
    Write-Host "[Moving] $source `n`t-> $destination"
    if (-not $WhatIf) {
        Move-Item $move_source $move_destination -Force
    }

    if (($RemoveEmptyArchive) `
        -and (-not $WhatIf) `
        -and (-not (Test-Path $move_source))) {
        Remove-Item $archiveDir.FullName
    }
}