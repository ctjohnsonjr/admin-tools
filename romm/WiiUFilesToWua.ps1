$archiver = "{Path to zarchive.exe}"
$dir = "{Target Dir}"
$releaseContentDirs = @("code", "content", "meta")

function process-rom {
    param(
        [string] $path
    )

    $releases = Get-ChildItem $path -Directory -Exclude "*wua*"
    $releases | ForEach-Object {
        $release = $_ 
        $appPath = "$($release.FullName)\code\app.xml"
        $metaPath = "$($release.FullName)\meta\meta.xml"

        
        if ((Test-Path -LiteralPath $appPath) -and (Test-Path -LiteralPath $metaPath)) {
            [xml] $metaXml = Get-Content -LiteralPath $metaPath
            [xml] $appXml = Get-Content -LiteralPath $appPath
            $id = $appXml.app.title_id.InnerText
            $version = $metaXml.menu.title_version.InnerText

            if ($id -and $version) {
                $releaseDirName = "$id`_v$version"
                $destination = "$release\$releaseDirName"
            }

            if (-not (Test-Path -LiteralPath $destination)) {
                New-Item $destination -ItemType Directory
            }

            $releaseContentDirs | ForEach-Object {
                $path = "$release\$_"
                if (Test-Path -LiteralPath $path) {
                    Move-Item -LiteralPath $path -Destination $destination
                }
            }

            $output = "$release.wua"
            & $archiver $release $output
        } else {
            Write-Output "Path to meta.xml not found.`nPath: $metaPath"
        }
    }
}

$roms = Get-ChildItem -Path $dir -Filter "*rpx*"

$roms | ForEach-Object {
    process-rom -path $_.FullName
}