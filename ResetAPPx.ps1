# ==========================================================
# FULL APPX / SYSPREP REPAIR
# Re-register all built-in apps + repair image + clean temp state
# Run as Administrator
# ==========================================================
Write-Host "Step 1: Re-registering all installed Appx packages..." -ForegroundColor Cyan
Get-AppxPackage -AllUsers | ForEach-Object {
    $manifest = Join-Path $_.InstallLocation "AppxManifest.xml"
    if (Test-Path $manifest) {
        try {
            Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction SilentlyContinue
        } catch {}
    }
}
Write-Host "Step 2: Repairing Windows image..." -ForegroundColor Cyan
DISM /Online /Cleanup-Image /RestoreHealth
Write-Host "Step 3: Running system file check..." -ForegroundColor Cyan
sfc /scannow
Write-Host "Step 4: Clearing Store cache..." -ForegroundColor Cyan
wsreset.exe
Write-Host "Done. Reboot the PC, sign in ONLY with local Administrator, then run Sysprep." -ForegroundColor Green
