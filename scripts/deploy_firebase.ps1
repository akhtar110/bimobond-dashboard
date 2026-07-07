# Build Flutter web and deploy to Firebase Hosting + API proxy function.
#
# The hosted app (https://bomibondapp.web.app) calls same-origin /api/* which is
# proxied by the `apiProxy` Cloud Function to http://134.209.2.225.
# Cloud Functions require the Firebase Blaze (pay-as-you-go) plan.
#
# Usage:
#   .\scripts\deploy_firebase.ps1
#   .\scripts\deploy_firebase.ps1 -HostingOnly

param(
    [switch]$HostingOnly
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Push-Location $Root
try {
    Write-Host "Building Flutter web (release)..."
    flutter build web --release --no-wasm-dry-run

    if (-not $HostingOnly) {
        Write-Host "Installing Cloud Functions dependencies..."
        Push-Location functions
        npm install
        Pop-Location
    }

    if ($HostingOnly) {
        Write-Host "Deploying Firebase Hosting only..."
        firebase deploy --only hosting
    } else {
        Write-Host "Deploying Firebase Hosting + apiProxy function..."
        firebase deploy --only hosting,functions
    }

    Write-Host ""
    Write-Host "Done."
    Write-Host "  Hosting: https://bomibondapp.web.app"
    if (-not $HostingOnly) {
        Write-Host "  API proxy: https://bomibondapp.web.app/api/* -> http://134.209.2.225"
    }
}
catch {
    if ($_.Exception.Message -match "Blaze") {
        Write-Host ""
        Write-Host "ERROR: Firebase Blaze plan is required to deploy the API proxy function." -ForegroundColor Red
        Write-Host "  1. Upgrade: https://console.firebase.google.com/project/bomibondapp/usage/details"
        Write-Host "  2. Re-run:  .\scripts\deploy_firebase.ps1"
        Write-Host ""
        Write-Host "Hosting-only deploy (UI without API login): .\scripts\deploy_firebase.ps1 -HostingOnly"
    }
    throw
}
finally {
    Pop-Location
}
