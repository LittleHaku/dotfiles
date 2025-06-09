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

# Function to check if an app is installed via winget
function Test-WingetApp {
    param (
        [string]$AppId
    )

    try {
        # Use winget list with --id flag and suppress stderr, capture stdout
        $result = winget list --id $AppId --exact --accept-source-agreements 2>$null
        
        # Check if the command succeeded
        if ($LASTEXITCODE -eq 0) {
            # Convert result to string if it's an array and check if it contains the app ID
            $resultString = if ($result -is [array]) { $result -join "`n" } else { $result }
            return $resultString -match [regex]::Escape($AppId)
        }
        return $false
    } catch {
        return $false
    }
}

# Function to install an application with winget
function Install-WingetApp {
    param (
        [string]$AppId,
        [string]$AppName,
        [switch]$AlwaysAsk = $false
    )

    # Check if app is already installed
    if (Test-WingetApp -AppId $AppId) {
        Write-Host "`n$AppName is already installed" -ForegroundColor Green
        return $true
    }

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

# Function to install or configure an application
function Install-OrConfigureApp {
    param (
        [string]$AppId,
        [string]$AppName,
        [scriptblock]$ConfigurationScript = $null
    )

    # Check if app is already installed
    if (Test-WingetApp -AppId $AppId) {
        Write-Host "`n$AppName is already installed" -ForegroundColor Green

        # Run configuration if provided
        if ($ConfigurationScript) {
            Write-Host "Configuring $AppName..." -ForegroundColor Cyan
            & $ConfigurationScript
        }
        return $true
    }

    # App is not installed, ask if user wants to install it
    Write-Host "`n$AppName is not installed." -ForegroundColor Yellow
    Write-Host "Do you want to install ${AppName}? (y/n)" -ForegroundColor Cyan
    $install = Read-Host

    if ($install -eq "y" -or $install -eq "") {
        Write-Host "`nInstalling $AppName..." -ForegroundColor Yellow
        winget install --id=$AppId -e --source winget

        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n$AppName installed successfully" -ForegroundColor Green

            # Run configuration if provided
            if ($ConfigurationScript) {
                Write-Host "Configuring $AppName..." -ForegroundColor Cyan
                & $ConfigurationScript
            }
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
Write-Host "Cloning or updating dotfiles repository..." -ForegroundColor Cyan
if (Test-Path -Path $DotfilesDir) {
    Write-Host "`nDotfiles directory already exists at $DotfilesDir, pulling latest changes..." -ForegroundColor Yellow
    Push-Location $DotfilesDir
    git pull
    Pop-Location
    Write-Host "`nDotfiles repository updated successfully" -ForegroundColor Green
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

# WSL Configuration Setup
Write-Host "`nSetting up WSL configuration..." -ForegroundColor Cyan
$WslConfigPath = "$env:USERPROFILE\.wslconfig"

# Function to get system memory in GB
function Get-SystemMemoryGB {
    try {
        $totalMemory = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB
        return [math]::Floor($totalMemory)
    } catch {
        Write-Warning "Could not detect system memory. Using default values."
        return 16  # Default fallback
    }
}

# Function to get CPU core count
function Get-CPUCoreCount {
    try {
        $cores = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
        return $cores
    } catch {
        Write-Warning "Could not detect CPU cores. Using default values."
        return 4  # Default fallback
    }
}

# Get system specifications
$totalMemoryGB = Get-SystemMemoryGB
$totalCores = Get-CPUCoreCount

# Calculate optimal WSL resource allocation
# Memory: Use 50-75% of available RAM for WSL, but cap at reasonable limits
if ($totalMemoryGB -le 8) {
    $wslMemoryGB = 4
    $wslSwapGB = 4
} elseif ($totalMemoryGB -le 16) {
    $wslMemoryGB = 8
    $wslSwapGB = 8
} elseif ($totalMemoryGB -le 32) {
    $wslMemoryGB = 16
    $wslSwapGB = 16
} else {
    $wslMemoryGB = 24
    $wslSwapGB = 16
}

# CPU: Leave at least 1-2 cores for Windows, but ensure WSL gets at least 2
$wslProcessors = [math]::Max(2, [math]::Min($totalCores - 1, $totalCores - 2))
if ($totalCores -le 4) {
    $wslProcessors = [math]::Max(2, $totalCores - 1)
}

Write-Host "`nDetected system specs:" -ForegroundColor Yellow
Write-Host "  Total Memory: ${totalMemoryGB}GB" -ForegroundColor White
Write-Host "  Total CPU Cores: $totalCores" -ForegroundColor White
Write-Host "`nConfiguring WSL with:" -ForegroundColor Yellow
Write-Host "  Memory: ${wslMemoryGB}GB" -ForegroundColor White
Write-Host "  Processors: $wslProcessors cores" -ForegroundColor White
Write-Host "  Swap: ${wslSwapGB}GB" -ForegroundColor White

# Create WSL configuration content
$wslConfigContent = @"
[wsl2]
# Memory allocation - optimized for ${totalMemoryGB}GB system
memory=${wslMemoryGB}GB

# CPU cores - using $wslProcessors out of $totalCores total cores
processors=$wslProcessors

# Swap space
swap=${wslSwapGB}GB

# Disable page reporting so WSL retains all allocated memory claimed from Windows and releases none back when free
# pageReporting=false

# Disable memory reclaim for more consistent performance
vmIdleTimeout=-1

# Enable nested virtualization for Docker and other virtualization needs
nestedVirtualization=true

# Network settings for better connectivity
dnsProxy=true
networkingMode=mirrored
autoProxy=true

# Performance optimizations
[experimental]
sparseVhd=true
"@

# Check if .wslconfig already exists
if (Test-Path $WslConfigPath) {
    Write-Host "`n.wslconfig file already exists" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite the existing WSL configuration? (y/n)"
    if ($overwrite -eq "y") {
        # Backup existing config
        $backupPath = "$WslConfigPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $WslConfigPath $backupPath
        Write-Host "Backed up existing .wslconfig to: $backupPath" -ForegroundColor Green

        # Write new config
        Set-Content -Path $WslConfigPath -Value $wslConfigContent -Encoding UTF8
        Write-Host ".wslconfig updated successfully" -ForegroundColor Green
    } else {
        Write-Host "Keeping existing WSL configuration" -ForegroundColor Yellow
    }
} else {
    # Create new .wslconfig file
    Set-Content -Path $WslConfigPath -Value $wslConfigContent -Encoding UTF8
    Write-Host ".wslconfig created successfully at: $WslConfigPath" -ForegroundColor Green
}

Write-Host "`nDo you want to view/edit the WSL configuration file? (y/n)" -ForegroundColor Cyan
$editConfig = Read-Host
if ($editConfig -eq "y") {
    Write-Host "Opening .wslconfig in Notepad..." -ForegroundColor Yellow
    Start-Process notepad $WslConfigPath -Wait
}

#------------------------------------------------
# AUTOHOTKEY SETUP
#------------------------------------------------
Show-SectionHeader "AutoHotkey Setup"

# Configure AutoHotkey
$ahkConfigScript = {
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

$installAhk = Install-OrConfigureApp -AppId "AutoHotkey.AutoHotkey" -AppName "AutoHotkey" -ConfigurationScript $ahkConfigScript

#------------------------------------------------
# KOMOREBI TILING WINDOW MANAGER SETUP
#------------------------------------------------
Show-SectionHeader "Komorebi Tiling Window Manager"

# Configure Komorebi
$komorebiConfigScript = {
    # Install WHKD (companion hotkey daemon)
    Write-Host "`nAttempting to install WHKD (companion hotkey daemon)..." -ForegroundColor Yellow
    winget install LGUG2Z.whkd -e --source winget
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nWHKD installed successfully" -ForegroundColor Green
    } else {
        Write-Warning "`nFailed to install WHKD. Komorebi hotkeys might not work."
        Write-Warning "You may need to install WHKD (LGUG2Z.whkd) manually via winget and ensure it's in your PATH."
        # Continue with Komorebi setup, but hotkeys might be an issue.
    }

    # Refresh environment variables in the current session to find new executables
    # This helps ensure 'komorebic.exe' can be found by Get-Command and for 'komorebic fetch-asc'
    Write-Host "`nRefreshing PATH for current session..." -ForegroundColor DarkGray
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    # Fetch Komorebi application-specific configurations (applications.json)
    # This command downloads/updates 'applications.json' to $Env:USERPROFILE/applications.json
    # Your 'komorebi.json' should be (and is by default) configured to look for it there.
    Write-Host "`nFetching/Updating Komorebi application-specific configurations (applications.json)..." -ForegroundColor Cyan
    Write-Host "This will download to '$env:USERPROFILE\applications.json'." -ForegroundColor Yellow
    # Ensure komorebic is found after potential PATH update from its installation
    # The PATH refresh above should help here.
    try {
        komorebic fetch-asc
        Write-Host "'komorebic fetch-asc' command executed successfully. 'applications.json' should now be at '$env:USERPROFILE\applications.json'." -ForegroundColor Green
    } catch {
        Write-Host "Error during 'komorebic fetch-asc': $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "If 'applications.json' is needed by Komorebi, you might need to run 'komorebic fetch-asc' manually after setup." -ForegroundColor Yellow
    }

    # Define Komorebi source config directory in dotfiles and target paths for symlinks
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
    Write-Host "`nRegistering Komorebi to run at startup..." -ForegroundColor Cyan
    $StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $komorebiStartupPath = "$StartupFolder\komorebi.bat"

    # Get the full path to komorebic.exe
    try {
        # Try to get the exact path to the executable
        $komorebiExeFullPath = (Get-Command komorebic.exe -ErrorAction Stop).Source
        Write-Host "Found komorebic.exe at: $komorebiExeFullPath" -ForegroundColor Green
    }
    catch {
        # If we can't find it, check common installation locations
        $possiblePaths = @(
            "C:\Users\$env:USERNAME\scoop\apps\komorebi\current\komorebic.exe",
            "C:\Program Files\LGUG2Z\komorebi\komorebic.exe",
            "C:\Program Files (x86)\LGUG2Z\komorebi\komorebic.exe"
        )

        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                $komorebiExeFullPath = $path
                Write-Host "Found komorebic.exe at: $komorebiExeFullPath" -ForegroundColor Green
                break
            }
        }

        # If still not found, ask the user for the path
        if (-not $komorebiExeFullPath) {
            Write-Host "Unable to automatically detect komorebic.exe location." -ForegroundColor Yellow
            Write-Host "Please enter the full path to komorebic.exe:" -ForegroundColor Cyan
            $komorebiExeFullPath = Read-Host

            if (-not (Test-Path $komorebiExeFullPath)) {
                Write-Warning "The specified path does not exist. Startup script may not work properly."
            }
        }
    }

    # Remove any existing Komorebi startup files to ensure we create fresh ones
    if (Test-Path $komorebiStartupPath) {
        Remove-Item $komorebiStartupPath -Force
        Write-Host "Removed existing Komorebi startup script" -ForegroundColor Yellow
    }

    # Create Komorebi startup batch file instead of shortcut
    $komorebiDir = [System.IO.Path]::GetDirectoryName($komorebiExeFullPath)
    $batchContent = @"
@echo off
cd /d "$komorebiDir"
start "" "$komorebiExeFullPath" start --config "$env:USERPROFILE\komorebi.json" --whkd --bar
"@

    Set-Content -Path $komorebiStartupPath -Value $batchContent -Encoding ASCII
    Write-Host "Created Komorebi startup batch file" -ForegroundColor Green

    # Ensure separate WHKD shortcut is removed as 'komorebic start --whkd' handles it
    $whkdStartupPath = "$StartupFolder\whkd.lnk"
    if (Test-Path $whkdStartupPath) {
        Remove-Item $whkdStartupPath -Force
        Write-Host "Removed redundant WHKD startup shortcut. Komorebi will manage WHKD." -ForegroundColor Yellow
    }

    Write-Host "`nKomorebi configured to run at startup with command:" -ForegroundColor Green
    Write-Host "  $komorebiExeFullPath start --config $env:USERPROFILE\komorebi.json --whkd --bar" -ForegroundColor Cyan
    Write-Host "Startup script created in: $komorebiStartupPath" -ForegroundColor Green
    Write-Host "You can modify your Komorebi configuration by editing files in $KomorebiConfigDir" -ForegroundColor Cyan
}

$installKomorebi = Install-OrConfigureApp -AppId "LGUG2Z.komorebi" -AppName "Komorebi tiling window manager" -ConfigurationScript $komorebiConfigScript

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
    Install-OrConfigureApp -AppId "Microsoft.WindowsTerminal" -AppName "Windows Terminal"
}

#------------------------------------------------
# ADDITIONAL APPLICATIONS
#------------------------------------------------
Show-SectionHeader "Additional Applications Setup"
Write-Host "Installing additional useful applications..." -ForegroundColor Cyan

# Development Tools
Install-OrConfigureApp -AppId "Microsoft.VisualStudioCode" -AppName "Visual Studio Code"
Install-OrConfigureApp -AppId "Docker.DockerDesktop" -AppName "Docker Desktop"

# Configure WezTerm
$weztermConfigScript = {
    Write-Host "Setting up WezTerm configuration..." -ForegroundColor Cyan
    $WeztermConfigDir = "$env:USERPROFILE\.config\wezterm"
    $WeztermConfigFile = "$WeztermConfigDir\wezterm.lua"
    $WeztermSourceConfig = "$DotfilesDir\roles\wezterm\files\wezterm.lua"

    # Create WezTerm config directory
    if (-not (Test-Path -Path $WeztermConfigDir)) {
        New-Item -Path $WeztermConfigDir -ItemType Directory -Force | Out-Null
        Write-Host "Created WezTerm config directory: $WeztermConfigDir" -ForegroundColor Green
    }

    # Symlink WezTerm configuration if source exists
    if (Test-Path -Path $WeztermSourceConfig) {
        # Remove existing config if it exists (file or symlink)
        if (Test-Path -Path $WeztermConfigFile) {
            Remove-Item $WeztermConfigFile -Force
            Write-Host "Removed existing WezTerm config" -ForegroundColor Yellow
        }

        # Create symbolic link
        New-Item -ItemType SymbolicLink -Path $WeztermConfigFile -Target $WeztermSourceConfig -Force | Out-Null
        Write-Host "WezTerm configuration symlinked from dotfiles" -ForegroundColor Green
    } else {
        Write-Warning "WezTerm source configuration not found at: $WeztermSourceConfig"
        Write-Host "You can manually create the configuration later" -ForegroundColor Yellow
    }
}

Install-OrConfigureApp -AppId "wez.wezterm" -AppName "WezTerm" -ConfigurationScript $weztermConfigScript

# Windows Auto Night Mode (for automatic light/dark theme switching)
Install-OrConfigureApp -AppId "Armin2208.WindowsAutoNightMode" -AppName "Windows Auto Night Mode"

# Spotify with SpotX modifications (ad-free)
Install-CustomApp -AppName "Spotify with SpotX (ad-free)" -InstallCommand 'iex "& { $(iwr -useb ''https://raw.githubusercontent.com/SpotX-Official/spotx-official.github.io/main/run.ps1'') } -new_theme"'

# Productivity Applications
Install-OrConfigureApp -AppId "Doist.Todoist" -AppName "Todoist"
Install-OrConfigureApp -AppId "Obsidian.Obsidian" -AppName "Obsidian"
Install-OrConfigureApp -AppId "DigitalScholar.Zotero" -AppName "Zotero"
Install-OrConfigureApp -AppId "Notion.Notion" -AppName "Notion"

# Communication Applications
Install-OrConfigureApp -AppId "Discord.Discord" -AppName "Discord"

# Gaming Applications
Install-OrConfigureApp -AppId "Valve.Steam" -AppName "Steam"

# UI Enhancement Applications
Install-OrConfigureApp -AppId "CharlesMilette.TranslucentTB" -AppName "TranslucentTB (transparent taskbar)"
Install-OrConfigureApp -AppId "MicaForEveryone.MicaForEveryone" -AppName "Mica For Everyone (enhanced Windows UI)"
Install-OrConfigureApp -AppId "Microsoft.PowerToys" -AppName "Microsoft PowerToys"

# Utility Applications
Install-OrConfigureApp -AppId "7zip.7zip" -AppName "7-Zip"
Install-OrConfigureApp -AppId "VideoLAN.VLC" -AppName "VLC Media Player"
Install-OrConfigureApp -AppId "Stremio.Stremio" -AppName "Stremio"

# Web Browser
Install-OrConfigureApp -AppId "Zen-Team.Zen-Browser" -AppName "Zen Browser"
Install-OrConfigureApp -AppId "TorProject.TorBrowser" -AppName "Tor Browser"

#------------------------------------------------
# SUMMARY
#------------------------------------------------
Show-SectionHeader "Setup Complete"
Write-Host "Dotfiles initialization complete!" -ForegroundColor Green
Write-Host "`nYour environment has been set up with:"
Write-Host "- Git installed and configured"
Write-Host "- Dotfiles repository cloned to $DotfilesDir"
Write-Host "- WSL installed with optimized .wslconfig (if needed)"
Write-Host "- SSH keys set up"
if ($installAhk) {
    Write-Host "- AutoHotkey installed and scripts set to run at startup"
}
if ($installKomorebi) {
    Write-Host "- Komorebi tiling window manager installed and configured"
    Write-Host "- WHKD hotkey daemon installed and configured"
}

Write-Host "`nAdditional applications installed:"
Write-Host "  - Development: Visual Studio Code, Docker Desktop, WezTerm"
Write-Host "  - Productivity: Todoist, Obsidian, Zotero, Notion"
Write-Host "  - Communication: Discord"
Write-Host "  - Gaming: Steam"
Write-Host "  - Utilities & Media: Windows Terminal, Auto Night Mode, Spotify, 7-Zip, VLC Media Player, Stremio"
Write-Host "  - UI Enhancements: TranslucentTB, MicaForEveryone, Microsoft PowerToys"
Write-Host "  - Web Browsers: Zen Browser, Tor Browser"

Write-Host "`nNext steps:"
Write-Host "1. Restart your computer if WSL was just installed"
Write-Host "2. After restart, WSL changes will take effect automatically"
if ($installAhk) {
    Write-Host "3. Add any additional AutoHotkey scripts to $AhkDir"
}
if ($installKomorebi) {
    Write-Host "4. Customize your Komorebi configuration in $KomorebiConfigDir"
    Write-Host "5. Run `komorebic start --whkd --bar` to start Komorebi or restart your computer"
}

Write-Host "`nEnjoy your newly configured Windows environment!" -ForegroundColor Cyan
