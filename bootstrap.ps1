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

# Function to display section header
function Show-SectionHeader {
    param (
        [string]$Title
    )

    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
}

# Function to install an application with winget
function Install-WingetApp {
    param (
        [string]$AppId,
        [string]$AppName,
        [switch]$AlwaysAsk = $false
    )

    Write-Host "`nDo you want to install ${AppName}? (y/n)" -ForegroundColor Cyan
    $install = Read-Host

    if ($install -eq "y" -or $install -eq "") {
        Write-Host "`nInstalling $AppName..." -ForegroundColor Yellow
        winget install --id=$AppId -e --source winget

        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n$AppName installed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "`nFailed to install $AppName. Please check the error and try again." -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "`nSkipping $AppName installation" -ForegroundColor Yellow
        return $false
    }
}

# Function to execute a custom installation command
function Install-CustomApp {
    param (
        [string]$AppName,
        [string]$InstallCommand
    )

    Write-Host "`nDo you want to install ${AppName}? (y/n)" -ForegroundColor Cyan
    $install = Read-Host

    if ($install -eq "y" -or $install -eq "") {
        Write-Host "`nInstalling $AppName..." -ForegroundColor Yellow
        try {
            Invoke-Expression $InstallCommand
            Write-Host "`n$AppName installed successfully" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "`nFailed to install ${AppName}: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "`nSkipping $AppName installation" -ForegroundColor Yellow
        return $false
    }
}

#------------------------------------------------
# PACKAGE MANAGER SETUP
#------------------------------------------------
Show-SectionHeader "Package Manager Setup"
Write-Host "Checking for winget..." -ForegroundColor Cyan
try {
    $wingetVersion = winget --version
    Write-Host "`nWinget is already installed: $wingetVersion" -ForegroundColor Green
} catch {
    Write-Host "`nWinget not found. Installing..." -ForegroundColor Yellow
    # For modern Windows 11 systems, winget should be available via the App Installer
    # For Windows 10, we need to install it manually
    Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget"
    Write-Host "`nPlease complete the winget installation and then rerun this script" -ForegroundColor Red
    exit
}

#------------------------------------------------
# GIT SETUP
#------------------------------------------------
Show-SectionHeader "Git Setup"
Write-Host "Checking for Git..." -ForegroundColor Cyan
if (Get-Command git.exe -ErrorAction SilentlyContinue) {
    Write-Host "`nGit is already installed: $(git --version)" -ForegroundColor Green
} else {
    Write-Host "`nGit not found. Installing Git..." -ForegroundColor Yellow
    winget install --id Git.Git -e --source winget
    Write-Host "`nGit installed successfully" -ForegroundColor Green
}

# Refresh environment variables to ensure Git is in the PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Configure Git with user info
Write-Host "`nChecking Git global configuration..." -ForegroundColor Cyan
$currentGitUserName = git config --global user.name
$currentGitEmail = git config --global user.email

if ($currentGitUserName -and $currentGitEmail) {
    Write-Host "`nGit is already configured with:" -ForegroundColor Green
    Write-Host "  User Name: $currentGitUserName" -ForegroundColor Green
    Write-Host "  Email:     $currentGitEmail" -ForegroundColor Green
} else {
    Write-Host "`nGit user.name or user.email not configured globally." -ForegroundColor Yellow
    $gitUserName = Read-Host "Enter your Git username"
    $gitEmail = Read-Host "Enter your Git email"

    git config --global user.name "$gitUserName"
    git config --global user.email "$gitEmail"
    git config --global init.defaultBranch main # Set these regardless, good defaults
    git config --global core.autocrlf input     # Set these regardless, good defaults
    Write-Host "`nGit configured successfully" -ForegroundColor Green
}

#------------------------------------------------
# DOTFILES SETUP
#------------------------------------------------
Show-SectionHeader "Dotfiles Setup"
Write-Host "Cloning dotfiles repository..." -ForegroundColor Cyan
if (Test-Path -Path $DotfilesDir) {
    Write-Host "`nDotfiles directory already exists at $DotfilesDir" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/n)"
    if ($overwrite -eq "y") {
        Remove-Item -Path $DotfilesDir -Recurse -Force
        git clone $DotfilesRepo $DotfilesDir
        Write-Host "`nDotfiles repository cloned successfully" -ForegroundColor Green
    } else {
        Write-Host "`nSkipping cloning operation" -ForegroundColor Yellow
    }
} else {
    git clone $DotfilesRepo $DotfilesDir
    Write-Host "`nDotfiles repository cloned successfully" -ForegroundColor Green
}

#------------------------------------------------
# WSL SETUP
#------------------------------------------------
Show-SectionHeader "Windows Subsystem for Linux"
Write-Host "Checking WSL installation..." -ForegroundColor Cyan
try {
    wsl --status
    Write-Host "`nWSL is already installed" -ForegroundColor Green
} catch {
    Write-Host "`nInstalling WSL..." -ForegroundColor Yellow
    wsl --install
    Write-Host "`nWSL installation initiated. You may need to restart your computer to complete the installation." -ForegroundColor Yellow
    Write-Host "After restart, WSL will continue setup automatically."
}

#------------------------------------------------
# AUTOHOTKEY SETUP
#------------------------------------------------
Show-SectionHeader "AutoHotkey Setup"
$installAhk = Install-WingetApp -AppId "AutoHotkey.AutoHotkey" -AppName "AutoHotkey"

if ($installAhk) {
    # Define AHK directory path now that we have the dotfiles cloned
    $AhkDir = "$DotfilesDir\ahk"

    # Add the AHK directory to PATH for easy script access
    $PathEnv = [Environment]::GetEnvironmentVariable("PATH", "User")
    if (-not $PathEnv.Contains($AhkDir)) {
        [Environment]::SetEnvironmentVariable("PATH", "$PathEnv;$AhkDir", "User")
        Write-Host "`nAdded $AhkDir to PATH" -ForegroundColor Green
    }

    # Create symbolic links between AHK scripts and Windows startup folder
    Write-Host "`nSetting up AutoHotkey scripts to run at startup..." -ForegroundColor Cyan
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
        Write-Host "`nNo AHK scripts found in $AhkDir directory" -ForegroundColor Yellow
        Write-Host "You can add your AHK scripts to this directory later" -ForegroundColor Yellow
    }
}

#------------------------------------------------
# KOMOREBI TILING WINDOW MANAGER SETUP
#------------------------------------------------
Show-SectionHeader "Komorebi Tiling Window Manager"
$installKomorebi = Install-WingetApp -AppId "LGUG2Z.komorebi" -AppName "Komorebi tiling window manager"

if ($installKomorebi) {
    # Install WHKD (companion hotkey daemon)
    Write-Host "`nInstalling WHKD (companion hotkey daemon)..." -ForegroundColor Yellow
    winget install LGUG2Z.whkd -e --source winget
    Write-Host "`nWHKD installed successfully" -ForegroundColor Green

    # Define Komorebi config paths
    $KomorebiConfigDir = "$DotfilesDir\komorebi"
    $WhkdConfigDir = "$DotfilesDir\whkd"
    $KomorebiConfigTarget = "$env:USERPROFILE\komorebi.json"
    $KomorebiBarConfigTarget = "$env:USERPROFILE\komorebi.bar.json"
    $WhkdConfigTarget = "$env:USERPROFILE\.config\whkdrc"

    # Create symbolic links for Komorebi configuration
    Write-Host "`nSetting up Komorebi configuration..." -ForegroundColor Cyan

    # Check if source config files exist in dotfiles repo
    $KomorebiConfigSource = "$KomorebiConfigDir\komorebi.json"
    $KomorebiBarConfigSource = "$KomorebiConfigDir\komorebi.bar.json"
    $WhkdConfigSource = "$WhkdConfigDir\whkdrc"

    # Create .config directory if it doesn't exist
    $ConfigDir = "$env:USERPROFILE\.config"
    if (-not (Test-Path -Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
        Write-Host "Created .config directory" -ForegroundColor Green
    }

    # Create directory if it doesn't exist
    if (-not (Test-Path -Path $KomorebiConfigDir)) {
        New-Item -ItemType Directory -Path $KomorebiConfigDir -Force | Out-Null
        Write-Host "Created Komorebi config directory at $KomorebiConfigDir" -ForegroundColor Green
    }

    # Function to create symbolic links from existing config files
    function Create-ConfigLink {
        param (
            [string]$SourcePath,
            [string]$TargetPath,
            [string]$ConfigName
        )

        # Check if source config exists
        if (-not (Test-Path -Path $SourcePath)) {
            Write-Host "Warning: $ConfigName config file not found at $SourcePath" -ForegroundColor Yellow
            Write-Host "Please make sure to add your $ConfigName config to your dotfiles repository" -ForegroundColor Yellow
            return
        }

        # Remove existing file if it exists
        if (Test-Path -Path $TargetPath) {
            Remove-Item -Path $TargetPath -Force
            Write-Host "Removed existing $ConfigName config" -ForegroundColor Yellow
        }

        # Create symbolic link
        New-Item -ItemType SymbolicLink -Path $TargetPath -Target $SourcePath -Force | Out-Null
        Write-Host "Linked $ConfigName config from dotfiles" -ForegroundColor Green
    }

    # Create the symbolic links for all Komorebi configs
    Create-ConfigLink -SourcePath $KomorebiConfigSource -TargetPath $KomorebiConfigTarget -ConfigName "Komorebi"
    Create-ConfigLink -SourcePath $KomorebiBarConfigSource -TargetPath $KomorebiBarConfigTarget -ConfigName "Komorebi-bar"
    Create-ConfigLink -SourcePath $WhkdConfigSource -TargetPath $WhkdConfigTarget -ConfigName "WHKD"

    # Register Komorebi and WHKD to run at startup
    Write-Host "`nRegistering Komorebi and WHKD to run at startup..." -ForegroundColor Cyan
    $StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $komorebiStartupPath = "$StartupFolder\komorebi.lnk"
    $whkdStartupPath = "$StartupFolder\whkd.lnk"

    $WshShell = New-Object -ComObject WScript.Shell

    # Create Komorebi shortcut
    $KomorebiShortcut = $WshShell.CreateShortcut($komorebiStartupPath)
    $KomorebiShortcut.TargetPath = "komorebic.exe"
    $KomorebiShortcut.Arguments = "start --whkd --bar"
    $KomorebiShortcut.Save()

    # Create WHKD shortcut
    $WhkdShortcut = $WshShell.CreateShortcut($whkdStartupPath)
    $WhkdShortcut.TargetPath = "whkd.exe"
    $WhkdShortcut.Save()

    Write-Host "`nKomorebi setup complete and configured to run at startup" -ForegroundColor Green
    Write-Host "You can modify your Komorebi configuration by editing files in $KomorebiConfigDir" -ForegroundColor Cyan
}

#------------------------------------------------
# SSH KEYS SETUP
#------------------------------------------------
Show-SectionHeader "SSH Keys Setup"
Write-Host "Setting up SSH keys..." -ForegroundColor Cyan
$SshDir = "$env:USERPROFILE\.ssh"

# Create SSH directory if it doesn't exist
if (-not (Test-Path -Path $SshDir)) {
    New-Item -ItemType Directory -Path $SshDir -Force | Out-Null
    Write-Host "`nCreated SSH directory" -ForegroundColor Green
}

# Check if SSH keys already exist
if ((Test-Path -Path "$SshDir\id_rsa") -or (Test-Path -Path "$SshDir\id_ed25519")) {
    Write-Host "`nSSH keys already exist" -ForegroundColor Green
} else {
    # Ask for key type
    $keyType = Read-Host "`nChoose SSH key type: (1) RSA or (2) ED25519 [default: 2]"
    if (-not $keyType -or $keyType -eq "2") {
        $keyType = "ed25519"
        $keyCommand = "ssh-keygen -t ed25519 -C `"$gitEmail`""
    } else {
        $keyType = "rsa"
        $keyCommand = "ssh-keygen -t rsa -b 4096 -C `"$gitEmail`""
    }

    Write-Host "`nGenerating $keyType SSH key..." -ForegroundColor Yellow
    Invoke-Expression $keyCommand

    # Start the ssh-agent
    Write-Host "`nStarting ssh-agent..." -ForegroundColor Yellow
    Start-Service ssh-agent

    # Add the SSH key to the agent
    if ($keyType -eq "ed25519") {
        ssh-add "$SshDir\id_ed25519"
    } else {
        ssh-add "$SshDir\id_rsa"
    }

    Write-Host "`nSSH key generated and added to ssh-agent" -ForegroundColor Green

    # Copy the public key to clipboard
    if ($keyType -eq "ed25519") {
        Get-Content "$SshDir\id_ed25519.pub" | Set-Clipboard
    } else {
        Get-Content "$SshDir\id_rsa.pub" | Set-Clipboard
    }

    Write-Host "`nSSH public key copied to clipboard. You can now add it to GitHub, GitLab, etc." -ForegroundColor Green
}

#------------------------------------------------
# WINDOWS TERMINAL SETUP
#------------------------------------------------
Show-SectionHeader "Windows Terminal Setup"
Write-Host "Checking for Windows Terminal..." -ForegroundColor Cyan
$TerminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path -Path $TerminalSettingsPath) {
    Write-Host "`nWindows Terminal is installed" -ForegroundColor Green
    Write-Host "You can update Windows Terminal settings manually from the dotfiles" -ForegroundColor Yellow
} else {
    Install-WingetApp -AppId "Microsoft.WindowsTerminal" -AppName "Windows Terminal"
}

#------------------------------------------------
# ADDITIONAL APPLICATIONS
#------------------------------------------------
Show-SectionHeader "Additional Applications Setup"
Write-Host "Installing additional useful applications..." -ForegroundColor Cyan

# Windows Auto Night Mode (for automatic light/dark theme switching)
Install-WingetApp -AppId "Armin2208.WindowsAutoNightMode" -AppName "Windows Auto Night Mode"

# Spotify with SpotX modifications (ad-free)
Install-CustomApp -AppName "Spotify with SpotX (ad-free)" -InstallCommand 'iex "& { $(iwr -useb ''https://raw.githubusercontent.com/SpotX-Official/spotx-official.github.io/main/run.ps1'') } -new_theme"'

# Productivity Applications
Install-WingetApp -AppId "Doist.Todoist" -AppName "Todoist"
Install-WingetApp -AppId "Notion.Notion" -AppName "Notion"

# Communication Applications
Install-WingetApp -AppId "Discord.Discord" -AppName "Discord"

# Gaming Applications
Install-WingetApp -AppId "Valve.Steam" -AppName "Steam"

# UI Enhancement Applications
Install-WingetApp -AppId "CharlesMilette.TranslucentTB" -AppName "TranslucentTB (transparent taskbar)"
Install-WingetApp -AppId "MicaForEveryone.MicaForEveryone" -AppName "Mica For Everyone (enhanced Windows UI)"

# Web Browser
Install-WingetApp -AppId "Zen-Team.Zen-Browser" -AppName "Zen Browser"

#------------------------------------------------
# SUMMARY
#------------------------------------------------
Show-SectionHeader "Setup Complete"
Write-Host "Dotfiles initialization complete!" -ForegroundColor Green
Write-Host "`nYour environment has been set up with:"
Write-Host "- Git installed and configured"
Write-Host "- Dotfiles repository cloned to $DotfilesDir"
Write-Host "- WSL installed (if needed)"
Write-Host "- SSH keys set up"
if ($installAhk) {
    Write-Host "- AutoHotkey installed and scripts set to run at startup"
}
if ($installKomorebi) {
    Write-Host "- Komorebi tiling window manager installed and configured"
    Write-Host "- WHKD hotkey daemon installed and configured"
}

Write-Host "`nAdditional applications installed:"
Write-Host "- Windows Terminal, Auto Night Mode, Spotify"
Write-Host "- Productivity tools: Todoist, Notion"
Write-Host "- Communication: Discord"
Write-Host "- Gaming: Steam"
Write-Host "- UI Enhancements: TranslucentTB, MicaForEveryone"
Write-Host "- Zen Browser"

Write-Host "`nNext steps:"
Write-Host "1. Restart your computer if WSL was just installed"
if ($installAhk) {
    Write-Host "2. Add any additional AutoHotkey scripts to $AhkDir"
}
if ($installKomorebi) {
    Write-Host "3. Customize your Komorebi configuration in $KomorebiConfigDir"
    Write-Host "4. Run `komorebic start --whkd --bar` to start Komorebi or restart your computer"
}

Write-Host "`nEnjoy your newly configured Windows environment!" -ForegroundColor Cyan
