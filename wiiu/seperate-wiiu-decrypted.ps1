[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Root = ".",
    [switch]$Archive,
    [string]$Install,
    [switch]$Force,
    [switch]$WhatIf
)

$zip = "C:\Program Files\7-Zip\7z.exe"
$zarchiver = "M:\Tools\zarchive\zarchive.exe"
$decryptedContentDirs = @("code", "content", "meta")
$encryptedTags = @("nus")
$decryptedTags = @("wua")

function create-WuaArchive {
    param(
        [string] $path,
        [string] $name
    )

    $appPath = Join-Path $path "code\app.xml"
    $metaPath = Join-Path $path "meta\meta.xml"
    if (-not $name) {
        $name = (Split-Path -Path $path -Leaf)
    }

    $output = Join-Path $path "$name.wua"
    if ((Test-Path $output) -and (-not $Force)) {
        Write-Verbose "WuaArchive: Skipping '$output' because it already exists. Use -Force to overwrite."
        return
    }
    $archiveRoot = Join-Path $path $name
    if ((Test-Path $archiveRoot) -and (-not $Force)) {
        Write-Verbose "WuaArchive: Skipping '$output' because '$archiveRoot' already exists. Use -Force to overwrite."
        return
    }
    
    if ((Test-Path -LiteralPath $appPath) -and (Test-Path -LiteralPath $metaPath)) {
        [xml] $metaXml = Get-Content -LiteralPath $metaPath
        [xml] $appXml = Get-Content -LiteralPath $appPath
        $id = $appXml.app.title_id.InnerText
        $version = $metaXml.menu.title_version.InnerText

        if ($id -and $version) {
            $releaseDirName = "$id`_v$version"
            $destination = Join-Path $archiveRoot $releaseDirName
        }

        if (-not (Test-Path -LiteralPath $destination)) {
            Write-Verbose "Creating Wua release directory '$destination'."
            if (-not $WhatIf) {
                New-Item -Path $destination -ItemType Directory -ErrorAction SilentlyContinue -Force
            }
        }

        $decryptedContentDirs | ForEach-Object {
            $contentPath = Join-Path $path $_
            if (Test-Path -LiteralPath $contentPath) {
                Write-Verbose "Moving '$contentPath' -> '$destination'"
                if (-not $WhatIf) {
                    Move-Item -LiteralPath $contentPath -Destination $destination
                }
            }
        }

        Write-Verbose "Creating WUA archive '$output' from '$archiveRoot'"
        if (-not $WhatIf) {
            & $zarchiver $archiveRoot $output
        }
    } else {
        Write-Verbose "Path to meta.xml not found.`nPath: $metaPath"
    }
}

function create-ZipArchive {
    param(
        [string] $path,
        [string] $name
    )

    if (-not $name) {
        $name = (Split-Path -Path $path -Leaf)
    }

    $archiveRootPath = Join-Path $path $name
    $archive = Join-Path $path "$name.zip"
    if ((Test-Path $archiveRootPath) -and (-not $Force)) {
        Write-Verbose "WuaArchive: Skipping '$output' because '$archiveRootPath' already exists. Use -Force to overwrite."
        return
    }
    if ((Test-Path $archive) -and (-not $Force)) {
        Write-Verbose "ZipArchive: Skipping '$archive' because it already exists. Use -Force to overwrite."
        return
    }

    if (-not $WhatIf) {
        $archiveRoot = New-Item -Path $archiveRootPath -ItemType Directory -ErrorAction SilentlyContinue -Force
        Get-ChildItem -LiteralPath $path -Exclude $archiveRootPath | foreach-object {
            $_ | Move-Item -Destination $archiveRoot -ErrorAction SilentlyContinue 
        }
    }

    Write-Verbose "Zipping '$archiveRoot' -> '$archive'"
    if (-not $WhatIf) {
        & $zip a $archive (Join-Path $archiveRoot '*') -tzip -mx=7 -mmt=12

        if (test-path -LiteralPath $archive) {
            Write-Verbose "Successfully created '$archive'. Removing original directory '$archiveRoot'."
            Remove-Item -LiteralPath $archiveRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-Verbose "Failed to create '$archive'. Original directory '$archiveRoot' has not been removed."
        }
    }
}

function create-TaggedDirectory {
    param(
        [string] $path,
        [string[]] $tags,
        [string] $filter
    )

    $parent = Split-Path -Path $path -Parent
    $taggedDirPath = "$path $(Join-String -InputObject $tags -FormatString "({0})" -Separator " ")"
    if ((Test-Path -LiteralPath $taggedDirPath) -and (-not $Force)) {
        Write-Verbose "Skipping '$taggedDirPath' because it already exists. Use -Force to overwrite."
        return
    }

    Write-Verbose "Creating tagged directory '$taggedDirPath' for content matching filter '$filter'."
    if (-not $WhatIf) {
        $taggedDir = New-Item -Path $taggedDirPath -ItemType Directory -ErrorAction SilentlyContinue -Force         
        $targetContent = Get-ChildItem -LiteralPath $path | where-object { $_.Name -match $filter }
        $targetContent | ForEach-Object {
            Move-Item -LiteralPath $_.FullName -Destination $taggedDir.FullName -ErrorAction SilentlyContinue
        }       
    }

    return $taggedDir
}

function move-ToConsolidateDirectories {
    param(
        [string] $path
    )
    $games = Get-ChildItem -Path $path -Filter "*[Game]*" -Directory
    $games | ForEach-Object {
        $game = $_ 
        $gameWithTags = ($game.FullName -replace "\[.*\]", "").Trim()
        $gameTag_split = $gameWithTags -split " \("
        $game = $gameTag_split[0] ?? $gameWithTags
        $tag = $gameTag_split[1]?.TrimEnd(")") ?? ""
        $allTypes = Get-ChildItem -Path $path | Where-Object { $_.Name -match "^$(Split-Path -Leaf $game)(\s*($|\[))" -and $_.Name -match $tag }

        Write-Verbose "Moving '$(($allTypes | Split-Path -Leaf) -join ", ")' -> '$gameWithTags'"
        if (-not $WhatIf) {
            $outputDir = New-Item -Path $gameWithTags -ItemType Directory -ErrorAction SilentlyContinue
        }

        $allTypes | ForEach-Object {
            if (-not $WhatIf) {
                $_ | Get-ChildItem | Move-Item -Destination $outputDir
            }
            if (-not ($_ | Get-ChildItem)) {
                Write-Verbose "Removing empty directory '$($_.FullName)'"
                if (-not $WhatIf) {
                    Remove-Item -LiteralPath $_ -Force
                }
            }
        }
    }
}

# Main script logic
if (-not (Test-Path $Root)) {
    Write-Error "Root path '$Root' does not exist."
    exit 1
}

$exclude = ($encryptedTags + $decryptedTags) -join '|'
$games = Get-ChildItem -Path $Root -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch $exclude }
$games | foreach-object {
    $gameDir = $_
    Write-Verbose "Processing game directory '$($gameDir.FullName)'"
    $decryptedfound = $decryptedContentDirs | Where-Object { Test-Path -LiteralPath (Join-Path $gameDir $_) -PathType Container }
    if ($decryptedfound) {
        $filter = $decryptedContentDirs -join "|"
        $taggedDir = create-TaggedDirectory -path $gameDir.FullName -tags $decryptedTags -filter $filter
        if ($Archive) {
            Write-Verbose "Creating WUA archive for '$($gameDir.FullName)'"
            if ($WhatIf) { $taggedDir = $gameDir}
            create-WuaArchive -path $taggedDir.FullName -name $gameDir.Name
            if (-not $WhatIf)
            {
                $archiveRoot = Join-Path $taggedDir.FullName $gameDir.Name
                if (Test-Path -LiteralPath "$archiveRoot.wua") {
                    Write-Verbose "Successfully created '$archiveRoot.wua'. Removing tagged directory '$archiveRoot'."
                    Remove-Item -LiteralPath $archiveRoot -Recurse -Force -ErrorAction SilentlyContinue
                }
                else {
                    Write-Verbose "Failed to create '$archiveRoot.wua'. Tagged directory '$($taggedDir.FullName)' has not been removed."
                }
            }
        }
    }

    $encryptedfound = $gameDir | Get-ChildItem -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match ".h3$|.app$|^title" }
    if ($encryptedfound) {
        $filter = ".h3$|.app$|^title"
        $taggedDir = create-TaggedDirectory -path $gameDir.FullName -tags $encryptedTags -filter $filter
        if($Install) {
            Write-Verbose "Installing '$($taggedDir.FullName)' to $Install"
            if (-not $WhatIf) {
                $taggedDir | copy-item -Destination $Install -Recurse -ErrorAction SilentlyContinue -Force
            }
        }
        if ($Archive) {
            Write-Verbose "Creating Zip archive for '$($gameDir.FullName)'"
            if ($WhatIf) { $taggedDir = $gameDir}
            create-ZipArchive -path $taggedDir.FullName -name $gameDir.Name
        }
    }

    if (-not ($gameDir | Get-ChildItem -ErrorAction SilentlyContinue)) {
        Write-Verbose "Removing empty directory '$($gameDir.FullName)'"
        if (-not $WhatIf) {
            Remove-Item -LiteralPath $gameDir.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

}

move-ToConsolidateDirectories -path $Root