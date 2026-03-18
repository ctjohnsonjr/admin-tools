[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $MyrientPath,
    [Parameter(Mandatory = $false)]
    [string] $Destination = "M:/Myrient/Downloads/",
    [Parameter(Mandatory = $false)]
    [switch] $DryRun,
    [Parameter(Mandatory = $false)]
    [string[]] $Filter
)

$args = @(
    "copy",
    "Myrient:$MyrientPath",
    $Destination,
    "--multi-thread-streams", "0",
    "-vP"
)
if ($DryRun) {
    $args += "--dry-run"
}

if($Filter) {
    foreach ($pattern in $Filter) {
        $args += "--filter"
        $args += $pattern
    }
}

Write-Output "Executing: rclone $($args -join ' ')"
rclone @args