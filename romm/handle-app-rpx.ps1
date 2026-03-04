# SYNOPSIS
#   Handle (app) and (rpx) directories under a root path.
#
# DESCRIPTION
#   - For directories whose name contains "(app)", compress each immediate child directory into a .zip placed inside the parent.
#   - For directories whose name contains "(rpx)", remove each immediate child directory.
#
# PARAMETERS
#   Root  : The root path to start scanning. Defaults to current directory.
#   WhatIf: When supplied, the script will print actions without executing them.
#
# EXAMPLE
#   .\handle-app-rpx.ps1 -Root C:\temp -WhatIf

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Root = ".",
    [switch]$Force,
    [switch]$WhatIf
)

function Zip-ChildDirectories {
    param(
        [string]$ParentPath
    )

    $children = Get-ChildItem -Path $ParentPath -Directory -ErrorAction SilentlyContinue
    foreach ($child in $children) {
        $zipPath = Join-Path $ParentPath ("$($child.Name).zip")
        if (Test-Path -LiteralPath $zipPath) {
            if ($Force) {
                if (-not $WhatIf) {
                    Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue 
                }
            }
            else {
                Write-Output "Skipping '$zipPath' because it already exists. Use -Force to overwrite."
                continue
            }
        }

        Write-Output "Zipping '$($child.FullName)' -> '$zipPath'"
        if (-not $WhatIf) {
            7z a $zipPath (Join-Path $child.FullName '*') -tzip -mx=7 -mmt=12

            if (test-path -LiteralPath $zipPath) {
                Write-Output "Successfully created '$zipPath'. Removing original directory '$($child.FullName)'."
                Remove-Item -LiteralPath $child.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
            else {
                Write-Output "Failed to create '$zipPath'. Original directory '$($child.FullName)' has not been removed."
            }
        }

    }
}

function Remove-ChildDirectories {
    param(
        [string]$ParentPath
    )
    $wua = Get-ChildItem -Path $ParentPath -Filter "*wua*" -File -ErrorAction SilentlyContinue
    $children = Get-ChildItem -Path $ParentPath -Directory -ErrorAction SilentlyContinue
    if (-not $wua) {
        Write-Output "Skipping '$ParentPath' because it doesnt contain a wua file."
        return
    }
    foreach ($child in $children) {
        Write-Output "Removing '$($child.FullName)'"
        if (-not $WhatIf) {
            Remove-Item -LiteralPath $child.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

if (-not (Test-Path $Root)) {
    Write-Error "Root path '$Root' does not exist."
    exit 1
}

$dirs = Get-ChildItem -Path $Root -Directory -Force -ErrorAction SilentlyContinue
foreach ($dir in $dirs) {
    $name = $dir.Name
    if ($name -match '\(app\)' -or $name -match '\(wud\)') {
        Zip-ChildDirectories -ParentPath $dir.FullName
    }
    elseif ($name -match '\(rpx\)' -or $name -match '\(wua\)') {
        Remove-ChildDirectories -ParentPath $dir.FullName
    }

    $oldName = $dir.Name
    $newName = $oldName -replace '\(app\)','(wud)' -replace '\(rpx\)','(wua)'
    if ($newName -ne $oldName) {
        Write-Host "Renaming: $oldName -> $newName"
        if (-not $WhatIf) {
            Rename-Item -LiteralPath $dir.FullName -NewName $newName
        }
    }
}

Write-Output "Done. (WhatIf=$WhatIf)"