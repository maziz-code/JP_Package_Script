# =====================================================================
# UNIVERSAL SYSPREP APPX FIX (SAFE VERSION)
# Repairs ALL Sysprep "installed for a user but not provisioned" errors
# without removing protected system apps.
#
# Run PowerShell as Administrator
# Reboot after completion, then run Sysprep again.
# =====================================================================
Write-Host "Starting universal Sysprep Appx repair..." -ForegroundColor Cyan
# ---------------------------------------------------------------------
# 1. Get provisioned package names
# ---------------------------------------------------------------------
$Provisioned = Get-AppxProvisionedPackage -Online |
    Select-Object -ExpandProperty DisplayName
# ---------------------------------------------------------------------
# 2. Protected apps that should NOT be removed
# ---------------------------------------------------------------------
$ProtectedPatterns = @(
    "Microsoft.Windows*",
    "Microsoft.SecHealthUI*",
    "Microsoft.VCLibs*",
    "Microsoft.UI.Xaml*",
    "Microsoft.NET.Native*",
    "Microsoft.StorePurchaseApp*",
    "Microsoft.DesktopAppInstaller*",
    "Microsoft.WindowsStore*"
)
# ---------------------------------------------------------------------
# 3. Find packages installed for users but not provisioned
# ---------------------------------------------------------------------
$Installed = Get-AppxPackage -AllUsers
$BadPackages = @()
foreach ($pkg in $Installed) {
    if ($Provisioned -notcontains $pkg.Name) {
        $BadPackages += $pkg
    }
}
Write-Host "Found $($BadPackages.Count) mismatched package(s)." -ForegroundColor Yellow
# ---------------------------------------------------------------------
# 4. Process each package
# ---------------------------------------------------------------------
foreach ($pkg in $BadPackages) {
    $IsProtected = $false
    foreach ($pattern in $ProtectedPatterns) {
        if ($pkg.Name -like $pattern) {
            $IsProtected = $true
        }
    }
    Write-Host ""
    Write-Host "Processing: $($pkg.Name)" -ForegroundColor Cyan
    if ($IsProtected) {
        Write-Host "Protected system app -> Re-registering..." -ForegroundColor Yellow
        try {
            $Manifest = Join-Path $pkg.InstallLocation "AppxManifest.xml"
            if (Test-Path $Manifest) {
                Add-AppxPackage -DisableDevelopmentMode `
                    -Register $Manifest `
                    -ErrorAction SilentlyContinue
                Write-Host "Re-registered." -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Re-register failed." -ForegroundColor Red
        }
    }
    else {
        Write-Host "Non-system app -> Removing..." -ForegroundColor Yellow
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName `
                -AllUsers `
                -ErrorAction Stop
            Write-Host "Removed." -ForegroundColor Green
        }
        catch {
            Write-Host "Removal failed." -ForegroundColor Red
        }
    }
}
# ---------------------------------------------------------------------
# 5. Repair Windows component store
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "Running DISM..." -ForegroundColor Cyan
DISM /Online /Cleanup-Image /RestoreHealth
Write-Host ""
Write-Host "Running SFC..." -ForegroundColor Cyan
sfc /scannow
# ---------------------------------------------------------------------
# 6. Finish
# ---------------------------------------------------------------------
Write-Host ""
Write-Host "Completed." -ForegroundColor Green
Write-Host "IMPORTANT: Reboot PC before running Sysprep."
