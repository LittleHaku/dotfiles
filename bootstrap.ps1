# Windows Dotfiles Initialization Script
# This script installs necessary tools and sets up the dotfiles environment

# Ensure we're running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    break
}

# Define paths
$DotfilesRepo = "https://github.com/LittleHaku/dotfiles.git"
$DotfilesDir = "$env:USERPROFILE\dotfiles"

# Check for and install Winget if not present
Write-Host "Checking for winget..." -ForegroundColor Cyan
try {
    $wingetVersion = winget --version
    Write-Host "Winget is already installed: $wingetVersion" -ForegroundColor Green
} catch {
    Write-Host "Winget not found. Installing..." -ForegroundColor Yellow
    # For modern Windows 11 systems, winget should be available via the App Installer
    # For Windows 10, we need to install it manually
    Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget"
    Write-Host "Please complete the winget installation and then rerun this script" -ForegroundColor Red
    exit
}

# Install Git with Winget
Write-Host "Installing Git..." -ForegroundColor Cyan
winget install --id Git.Git -e --source winget
Write-Host "Git installed successfully" -ForegroundColor Green

# Refresh environment variables to ensure Git is in the PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

# Configure Git with user info
$gitUserName = Read-Host "Enter your Git username"
$gitEmail = Read-Host "Enter your Git email"

git config --global user.name "$gitUserName"
git config --global user.email "$gitEmail"
git config --global init.defaultBranch main
git config --global core.autocrlf input

Write-Host "Git configured successfully" -ForegroundColor Green

# Clone dotfiles repository
Write-Host "Cloning dotfiles repository..." -ForegroundColor Cyan
if (Test-Path -Path $DotfilesDir) {
    Write-Host "Dotfiles directory already exists at $DotfilesDir" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/n)"
    if ($overwrite -eq "y") {
        Remove-Item -Path $DotfilesDir -Recurse -Force
        git clone $DotfilesRepo $DotfilesDir
        Write-Host "Dotfiles repository cloned successfully" -ForegroundColor Green
    } else {
        Write-Host "Skipping cloning operation" -ForegroundColor Yellow
    }
} else {
    git clone $DotfilesRepo $DotfilesDir
    Write-Host "Dotfiles repository cloned successfully" -ForegroundColor Green
}

# Install WSL if not already installed
Write-Host "Checking WSL installation..." -ForegroundColor Cyan
try {
    wsl --status
    Write-Host "WSL is already installed" -ForegroundColor Green
} catch {
    Write-Host "Installing WSL..." -ForegroundColor Yellow
    wsl --install
    Write-Host "WSL installation initiated. You may need to restart your computer to complete the installation." -ForegroundColor Yellow
    Write-Host "After restart, WSL will continue setup automatically."
}

# Install AutoHotkey with Winget
Write-Host "Installing AutoHotkey..." -ForegroundColor Cyan
winget install --id AutoHotkey.AutoHotkey -e --source winget
Write-Host "AutoHotkey installed successfully" -ForegroundColor Green

# Define AHK directory path now that we have the dotfiles cloned
$AhkDir = "$DotfilesDir\ahk"

# Add the AHK directory to PATH for easy script access
$PathEnv = [Environment]::GetEnvironmentVariable("PATH", "User")
if (-not $PathEnv.Contains($AhkDir)) {
    [Environment]::SetEnvironmentVariable("PATH", "$PathEnv;$AhkDir", "User")
    Write-Host "Added $AhkDir to PATH" -ForegroundColor Green
}

# Create symbolic links between AHK scripts and Windows startup folder
Write-Host "Setting up AutoHotkey scripts to run at startup..." -ForegroundColor Cyan
$StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"

# Check if there are any AHK scripts to link
$AhkScripts = Get-ChildItem -Path "$AhkDir\*.ahk" -ErrorAction SilentlyContinue
if ($AhkScripts) {
    foreach ($script in $AhkScripts) {
        $shortcutPath = "$StartupFolder\$($script.BaseName).lnk"
        
        # Create a shortcut to the AHK script in the startup folder
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = $script.FullName
        $Shortcut.Save()
        
        Write-Host "Created startup shortcut for $($script.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "No AHK scripts found in $AhkDir directory" -ForegroundColor Yellow
    Write-Host "You can add your AHK scripts to this directory later" -ForegroundColor Yellow
}

# Set up SSH keys
Write-Host "Setting up SSH keys..." -ForegroundColor Cyan
$SshDir = "$env:USERPROFILE\.ssh"

# Create SSH directory if it doesn't exist
if (-not (Test-Path -Path $SshDir)) {
    New-Item -ItemType Directory -Path $SshDir -Force | Out-Null
    Write-Host "Created SSH directory" -ForegroundColor Green
}

# Check if SSH keys already exist
if ((Test-Path -Path "$SshDir\id_rsa") -or (Test-Path -Path "$SshDir\id_ed25519")) {
    Write-Host "SSH keys already exist" -ForegroundColor Green
} else {
    # Ask for key type
    $keyType = Read-Host "Choose SSH key type: (1) RSA or (2) ED25519 [default: 2]"
    if (-not $keyType -or $keyType -eq "2") {
        $keyType = "ed25519"
        $keyCommand = "ssh-keygen -t ed25519 -C `"$gitEmail`""
    } else {
        $keyType = "rsa"
        $keyCommand = "ssh-keygen -t rsa -b 4096 -C `"$gitEmail`""
    }
    
    Write-Host "Generating $keyType SSH key..." -ForegroundColor Yellow
    Invoke-Expression $keyCommand
    
    # Start the ssh-agent
    Write-Host "Starting ssh-agent..." -ForegroundColor Yellow
    Start-Service ssh-agent
    
    # Add the SSH key to the agent
    if ($keyType -eq "ed25519") {
        ssh-add "$SshDir\id_ed25519"
    } else {
        ssh-add "$SshDir\id_rsa"
    }
    
    Write-Host "SSH key generated and added to ssh-agent" -ForegroundColor Green
    
    # Copy the public key to clipboard
    if ($keyType -eq "ed25519") {
        Get-Content "$SshDir\id_ed25519.pub" | Set-Clipboard
    } else {
        Get-Content "$SshDir\id_rsa.pub" | Set-Clipboard
    }
    
    Write-Host "SSH public key copied to clipboard. You can now add it to GitHub, GitLab, etc." -ForegroundColor Green
}

# Configure Windows Terminal (if installed)
Write-Host "Checking for Windows Terminal..." -ForegroundColor Cyan
$TerminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path -Path $TerminalSettingsPath) {
    Write-Host "Windows Terminal is installed" -ForegroundColor Green
    Write-Host "You can update Windows Terminal settings manually from the dotfiles" -ForegroundColor Yellow
} else {
    Write-Host "Windows Terminal not found. Consider installing it via Winget:" -ForegroundColor Yellow
    Write-Host "winget install Microsoft.WindowsTerminal" -ForegroundColor Yellow
}

Write-Host "Dotfiles initialization complete!" -ForegroundColor Green
Write-Host "Your environment has been set up with:"
Write-Host "- Git installed and configured"
Write-Host "- Dotfiles repository cloned to $DotfilesDir"
Write-Host "- WSL installed (if needed)"
Write-Host "- SSH keys set up"
Write-Host "- AutoHotkey installed and scripts set to run at startup"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Restart your computer if WSL was just installed"
Write-Host "2. Add any additional AutoHotkey scripts to $AhkDir"