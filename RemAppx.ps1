# ===============================================================
# FIX ALL SYSPREP APPX ERRORS AT ONCE
# Removes ALL user-installed Appx packages that are NOT provisioned
# This prevents Sysprep failing one package at a time
#
# Run PowerShell as Administrator
# ===============================================================
Write-Host "Scanning for Sysprep blocking packages..." -ForegroundColor Cyan
# Get all provisioned package names (base names)
$Provisioned = Get-AppxProvisionedPackage -Online | Select-Object -ExpandProperty DisplayName
# Get all installed packages for all users
$Installed = Get-AppxPackage -AllUsers
$ProblemPackages = @()
foreach ($pkg in $Installed) {
    if ($Provisioned -notcontains $pkg.Name) {
        $ProblemPackages += $pkg
    }
}
if ($ProblemPackages.Count -eq 0) {
    Write-Host "No blocking packages found." -ForegroundColor Green
    exit
}
Write-Host ""
Write-Host "Found $($ProblemPackages.Count) Sysprep blocking package(s)." -ForegroundColor Yellow
Write-Host ""
# ---------------------------------------------------------------
# Remove all offending packages
# ---------------------------------------------------------------
foreach ($pkg in $ProblemPackages) {
    Write-Host "Removing: $($pkg.Name)" -ForegroundColor Green
    Write-Host "Package: $($pkg.PackageFullName)"
    try {
        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
        Write-Host "Removed successfully.`n"
    }
    catch {
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction SilentlyContinue
            Write-Host "Fallback removal attempted.`n"
        }
        catch {
            Write-Host "Failed removal.`n" -ForegroundColor Red
        }
    }
}
# ---------------------------------------------------------------
# Clean orphaned registry entries
# ---------------------------------------------------------------
Write-Host "Cleaning registry remnants..." -ForegroundColor Cyan
$RegPaths = @(
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications",
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife"
)
foreach ($path in $RegPaths) {
    if (Test-Path $path) {
        Get-ChildItem $path | ForEach-Object {
            try {
                Remove-Item $_.PsPath -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }
}
# ---------------------------------------------------------------
# Final verification
# ---------------------------------------------------------------
Write-Host ""
Write-Host "Rechecking..." -ForegroundColor Cyan
$Installed2 = Get-AppxPackage -AllUsers
$StillBad = @()
foreach ($pkg in $Installed2) {
    if ($Provisioned -notcontains $pkg.Name) {
        $StillBad += $pkg.Name
    }
}
if ($StillBad.Count -eq 0) {
    Write-Host "All Sysprep blocking packages removed." -ForegroundColor Green
    Write-Host "Reboot PC, then run Sysprep."
}
else {
    Write-Host "Some packages remain:" -ForegroundColor Red
    $StillBad | Sort-Object -Unique
}
Write-Host ""
Write-Host "Done."
