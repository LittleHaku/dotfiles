# Reapply Win+L Disable Settings for Komorebi
# Run this script as Administrator if Win+L starts working again after Windows updates
#
# Usage: .\reapply_winl_disable.ps1

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script should be run as Administrator for best results!"
    Write-Host "Press Enter to continue anyway, or Ctrl+C to cancel and restart as admin..." -ForegroundColor Yellow
    Read-Host
}

Write-Host "Reapplying Win+L disable settings for Komorebi..." -ForegroundColor Cyan

try {
    # Method 1: Apply Scancode Map
    Write-Host "`nApplying Scancode Map..." -ForegroundColor Yellow

    $scancodeMapValue = [byte[]]@(
        0x00, 0x00, 0x00, 0x00,  # Header: Version
        0x00, 0x00, 0x00, 0x00,  # Header: Flags
        0x02, 0x00, 0x00, 0x00,  # Number of mappings
        0x00, 0x00, 0x26, 0x00,  # Map L key (0x26) to nothing (0x00)
        0x00, 0x00, 0x00, 0x00   # Null terminator
    )

    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "Scancode Map" -Value $scancodeMapValue -Type Binary
    Write-Host "✓ Scancode Map applied" -ForegroundColor Green

    # Method 2: Apply Group Policy settings
    Write-Host "`nApplying Group Policy settings..." -ForegroundColor Yellow

    # Ensure lock workstation functionality remains enabled
    $policyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
    if (-not (Test-Path $policyPath)) {
        New-Item -Path $policyPath -Force | Out-Null
    }
    Set-ItemProperty -Path $policyPath -Name "DisableLockWorkstation" -Value 0 -Type DWord
    Write-Host "✓ Lock workstation functionality preserved" -ForegroundColor Green

    # Windows Key Policy settings
    $explorerPolicyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    if (-not (Test-Path $explorerPolicyPath)) {
        New-Item -Path $explorerPolicyPath -Force | Out-Null
    }
    Set-ItemProperty -Path $explorerPolicyPath -Name "NoWinKeys" -Value 0 -Type DWord
    Write-Host "✓ Windows Key policies configured" -ForegroundColor Green

    # Disable Win+L specifically
    $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $advancedPath)) {
        New-Item -Path $advancedPath -Force | Out-Null
    }
    Set-ItemProperty -Path $advancedPath -Name "DisabledHotkeys" -Value "L" -Type String
    Write-Host "✓ Win+L hotkey disabled" -ForegroundColor Green

    Write-Host "`n🎉 Win+L disable settings reapplied successfully!" -ForegroundColor Green
    Write-Host "`nIMPORTANT:" -ForegroundColor Yellow
    Write-Host "• Restart your computer for all changes to take effect" -ForegroundColor White
    Write-Host "• If issues persist, check that Komorebi is configured to use Win+L" -ForegroundColor White
    Write-Host "`nAlternative lock methods:" -ForegroundColor Cyan
    Write-Host "• Ctrl+Alt+Del → Lock" -ForegroundColor White
    Write-Host "• Win+Ctrl+L (if configured in AutoHotkey)" -ForegroundColor White
    Write-Host "• Lock button in Start Menu" -ForegroundColor White

} catch {
    Write-Error "Failed to apply Win+L disable settings: $($_.Exception.Message)"
    Write-Host "`nManual alternative:" -ForegroundColor Yellow
    Write-Host "Import the registry file: disable_winl.reg" -ForegroundColor White
    Write-Host "Then restart your computer" -ForegroundColor White
}

Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
Read-Host
