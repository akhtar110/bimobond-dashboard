# Deploy Flutter web build to the droplet at http://134.209.2.225
# Requires OpenSSH (scp) and SSH access to the server.
#
# Usage:
#   .\scripts\deploy_droplet.ps1
#   .\scripts\deploy_droplet.ps1 -SshUser root -RemotePath /var/www/bimo-dashboard

param(
    [string]$Host = "134.209.2.225",
    [string]$SshUser = "root",
    [string]$RemotePath = "/var/www/bimo-dashboard"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Push-Location $Root
try {
    flutter build web --release
    $target = "${SshUser}@${Host}:${RemotePath}/"
    Write-Host "Uploading build/web to $target"
    ssh "${SshUser}@${Host}" "mkdir -p $RemotePath"
    scp -r build/web/* $target
    Write-Host "Done. Open http://${Host}/ in the browser."
    Write-Host "API base URL: http://${Host}"
}
finally {
    Pop-Location
}
