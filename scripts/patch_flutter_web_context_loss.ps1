# Patches Flutter web engine race during hot restart (LateInitializationError:
# _handledContextLostEvent). Upstream fix: flutter/flutter#185116
#
# Re-run after `flutter upgrade`, `flutter precache --web`, or cache repair.

$ErrorActionPreference = 'Stop'

$flutterRoot = if ($env:FLUTTER_ROOT) { $env:FLUTTER_ROOT } else { 'C:\src\flutter' }
$webSdk = Join-Path $flutterRoot 'bin\cache\flutter_web_sdk'

$targets = @(
    (Join-Path $webSdk 'lib\_engine\engine\canvaskit\surface.dart'),
    (Join-Path $webSdk 'lib\_skwasm_impl\skwasm_impl\surface.dart')
)

$old = '  late Completer<void>? _handledContextLostEvent;'
$new = '  Completer<void>? _handledContextLostEvent;'

foreach ($file in $targets) {
    if (-not (Test-Path $file)) {
        Write-Warning "Skipped (not found): $file"
        continue
    }

    $content = Get-Content $file -Raw
    if ($content -match [regex]::Escape($new)) {
        Write-Host "Already patched: $file"
        continue
    }
    if ($content -notmatch [regex]::Escape($old)) {
        Write-Warning "Pattern not found (Flutter may already include the fix): $file"
        continue
    }

    $content = $content.Replace($old, $new)
    Set-Content -Path $file -Value $content -NoNewline
    Write-Host "Patched: $file"
}

Write-Host 'Done. Stop and re-run `flutter run` for the change to take effect.'
