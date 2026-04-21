# ============================================================
# Fix Sysprep Error:
# ReincubateLtd.CamoStudio installed for user but not provisioned
# Removes Camo Studio for ALL users + provisioned package
# Run PowerShell as Administrator
# ============================================================
Write-Host "Starting Camo Studio removal..." -ForegroundColor Cyan
$PackageName = "ReincubateLtd.CamoStudio"
# ------------------------------------------------------------
# 1. Remove installed package for all existing users
# ------------------------------------------------------------
Write-Host "`nChecking installed Appx packages..." -ForegroundColor Yellow
$InstalledPackages = Get-AppxPackage -AllUsers | Where-Object {
    $_.Name -like "$PackageName*"
}
if ($InstalledPackages) {
    foreach ($pkg in $InstalledPackages) {
        Write-Host "Removing installed package: $($pkg.PackageFullName)" -ForegroundColor Green
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host "Removed successfully."
        }
        catch {
            Write-Host "Failed normal removal. Trying fallback..." -ForegroundColor Red
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction SilentlyContinue
            } catch {}
        }
    }
}
else {
    Write-Host "No installed user package found."
}
# ------------------------------------------------------------
# 2. Remove provisioned package from Windows image
# ------------------------------------------------------------
Write-Host "`nChecking provisioned packages..." -ForegroundColor Yellow
$Provisioned = Get-AppxProvisionedPackage -Online | Where-Object {
    $_.DisplayName -like "$PackageName*"
}
if ($Provisioned) {
    foreach ($prov in $Provisioned) {
        Write-Host "Removing provisioned package: $($prov.PackageName)" -ForegroundColor Green
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop
            Write-Host "Removed successfully."
        }
        catch {
            Write-Host "Failed to remove provisioned package." -ForegroundColor Red
        }
    }
}
else {
    Write-Host "No provisioned package found."
}
# ------------------------------------------------------------
# 3. Cleanup orphaned registry entries
# ------------------------------------------------------------
Write-Host "`nCleaning Appx registry references..." -ForegroundColor Yellow
$RegPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife"
)
foreach ($path in $RegPaths) {
    if (Test-Path $path) {
        Get-ChildItem $path | Where-Object {
            $_.PSChildName -like "$PackageName*"
        } | ForEach-Object {
            try {
                Remove-Item $_.PsPath -Recurse -Force
                Write-Host "Removed registry key: $($_.PSChildName)"
            } catch {}
        }
    }
}
# ------------------------------------------------------------
# 4. Final verification
# ------------------------------------------------------------
Write-Host "`nVerifying removal..." -ForegroundColor Yellow
$Check1 = Get-AppxPackage -AllUsers | Where-Object {$_.Name -like "$PackageName*"}
$Check2 = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like "$PackageName*"}
if (!$Check1 -and !$Check2) {
    Write-Host "`nCamo Studio fully removed. Safe to run Sysprep." -ForegroundColor Green
}
else {
    Write-Host "`nSome remnants still exist. Reboot and run script again." -ForegroundColor Red
}
Write-Host "`nDone." -ForegroundColor Cyan
