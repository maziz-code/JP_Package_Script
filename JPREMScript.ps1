# Remove-SysprepBlockingLanguagePackages.ps1
# Run as Administrator
$ErrorActionPreference = 'Continue'
# Add or remove patterns here if needed
$packagePatterns = @(
    '*MicrosoftWindows.Speech.*',
    '*Microsoft.LanguageExperiencePack*',
    '*MicrosoftWindows.TextToSpeech*',
    '*MicrosoftWindows.Client.LanguageExperiencePack*'
)
Write-Host "Scanning for Sysprep-blocking language packages..." -ForegroundColor Cyan
function Remove-InstalledPackages {
    param([string[]]$Patterns)
    $allInstalled = Get-AppxPackage -AllUsers
    foreach ($pattern in $Patterns) {
        $matches = $allInstalled | Where-Object {
            $_.Name -like $pattern -or $_.PackageFullName -like $pattern
        }
        if (-not $matches) {
            Write-Host "No installed packages found for pattern: $pattern" -ForegroundColor DarkGray
            continue
        }
        foreach ($pkg in $matches) {
            try {
                Write-Host "Removing installed package: $($pkg.PackageFullName)" -ForegroundColor Yellow
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                Write-Host "Removed installed package: $($pkg.PackageFullName)" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to remove installed package: $($pkg.PackageFullName)"
                Write-Warning $_.Exception.Message
            }
        }
    }
}
function Remove-ProvisionedPackages {
    param([string[]]$Patterns)
    $allProvisioned = Get-AppxProvisionedPackage -Online
    foreach ($pattern in $Patterns) {
        $matches = $allProvisioned | Where-Object {
            $_.DisplayName -like $pattern -or $_.PackageName -like $pattern
        }
        if (-not $matches) {
            Write-Host "No provisioned packages found for pattern: $pattern" -ForegroundColor DarkGray
            continue
        }
        foreach ($pkg in $matches) {
            try {
                Write-Host "Removing provisioned package: $($pkg.PackageName)" -ForegroundColor Yellow
                Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction Stop | Out-Null
                Write-Host "Removed provisioned package: $($pkg.PackageName)" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to remove provisioned package: $($pkg.PackageName)"
                Write-Warning $_.Exception.Message
            }
        }
    }
}
Remove-InstalledPackages -Patterns $packagePatterns
Remove-ProvisionedPackages -Patterns $packagePatterns
Write-Host ""
Write-Host "Cleanup complete. Reboot before running Sysprep again." -ForegroundColor Cyan
