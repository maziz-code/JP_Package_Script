# =====================================================================
# UNIVERSAL SYSPREP FIX SCRIPT
# Fixes:
# "installed for a user, but not provisioned for all users"
# Example: Microsoft.WidgetsPlatformRuntime
#
# Safe for deployment to multiple PCs
# Run as Administrator
# Reboot after script, then run Sysprep
# =====================================================================
Write-Host "Starting Sysprep Appx Repair..." -ForegroundColor Cyan
# ---------------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------------
$Targets = @(
    "Microsoft.WidgetsPlatformRuntime",
    "MicrosoftWindows.Client.WebExperience",
    "MicrosoftWindows.Client.CBS",
    "MicrosoftWindows.Client.Core",
    "MicrosoftWindows.Client.Photon"
)
# ---------------------------------------------------------------------
# STEP 1 - Remove target packages for all users
# ---------------------------------------------------------------------
foreach ($name in $Targets) {
    Write-Host ""
    Write-Host "Checking installed package: $name" -ForegroundColor Yellow
    $Pkgs = Get-AppxPackage -AllUsers | Where-Object {
        $_.Name -like "$name*"
    }
    foreach ($pkg in $Pkgs) {
        Write-Host "Removing $($pkg.PackageFullName)" -ForegroundColor Green
        try {
            Remove-AppxPackage `
                -Package $pkg.PackageFullName `
                -AllUsers `
                -ErrorAction Stop
        }
        catch {
            try {
                Remove-AppxPackage `
                    -Package $pkg.PackageFullName `
                    -ErrorAction SilentlyContinue
            } catch {}
        }
    }
}
# ---------------------------------------------------------------------
# STEP 2 - Remove provisioned copies if present
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "Checking provisioned packages..." -ForegroundColor Cyan
$Prov = Get-AppxProvisionedPackage -Online
foreach ($pkg in $Prov) {
    foreach ($name in $Targets) {
        if ($pkg.DisplayName -like "$name*") {
            Write-Host "Removing provisioned $($pkg.PackageName)" -ForegroundColor Green
            try {
                Remove-AppxProvisionedPackage `
                    -Online `
                    -PackageName $pkg.PackageName `
                    -ErrorAction SilentlyContinue
            } catch {}
        }
    }
}
# ---------------------------------------------------------------------
# STEP 3 - Disable Widgets Feature
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "Disabling Widgets..." -ForegroundColor Cyan
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds /t REG_DWORD /d 0 /f | Out-Null
# ---------------------------------------------------------------------
# STEP 4 - Repair image
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "Running DISM..." -ForegroundColor Cyan
DISM /Online /Cleanup-Image /RestoreHealth
Write-Host ""
Write-Host "Running SFC..." -ForegroundColor Cyan
sfc /scannow
# ---------------------------------------------------------------------
# STEP 5 - Clear temp appx state
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "Clearing Store cache..." -ForegroundColor Cyan
Start-Process wsreset.exe -Wait -ErrorAction SilentlyContinue
# ---------------------------------------------------------------------
# FINISH
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "Completed successfully." -ForegroundColor Green
Write-Host "IMPORTANT:"
Write-Host "1. Reboot the PC"
Write-Host "2. Login as local Administrator only"
Write-Host "3. Run Sysprep again"
