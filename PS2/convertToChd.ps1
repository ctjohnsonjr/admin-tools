[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Root = ".",
    [switch]$WhatIf
)

$chdman = "M:\Tools\MAME\chdman.exe"

$dirs = Get-ChildItem -LiteralPath $Root -Directory
foreach ($dir in $dirs) {
    Write-Verbose "Found: $($dir.FullName)"
    $files = Get-ChildItem -LiteralPath $dir.FullName -File | Where-Object { $_.Extension -eq ".iso" -or $_.Extension -eq ".cue" -or $_.Extension -eq ".gdi" }
    foreach ($file in $files) {
        $out_file = [System.IO.Path]::ChangeExtension($file.FullName, ".chd")
        if (Test-Path $out_file) {
            Write-Verbose "Skipping '$out_file' because it already exists."
            continue
        }

        if ($WhatIf) {
            Write-Output "chdman createdvd -i `"$($file.FullName)`" -o `"$out_file`" --force"
        } else {
            try {
                & $chdman createdvd -i "$($file.FullName)" -o "$out_file" --force
                if ($LASTEXITCODE -ne 0) { throw "Command failed with exit code $LASTEXITCODE" }
            }
            catch {
                Remove-Item -LiteralPath $out_file -ErrorAction SilentlyContinue
                Write-Output "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] $($dir.FullName)" >> "$Root\\errors.log"
            }
        }
    }
}