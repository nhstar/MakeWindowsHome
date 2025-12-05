# This is used to set me up with some comfort feelings in Windows, and Powershell setups, as well as
# getting me some familiar folders

# Setup a bin folder in AppData
function Ensure-AppsInstalled {
    <#
    .SYNOPSIS
        Ensures a list of applications are installed via Registry or Winget.
    .DESCRIPTION
        Checks both Registry uninstall keys and Winget’s package list.
        Logs results to a file. If an app is missing, prompts before installing.
    .PARAMETER Apps
        A hashtable of app names and their Winget IDs.
        Example: @{ "eza"="eza-community.eza"; "git"="Git.Git"; "7zip"="7zip.7zip" }
    .PARAMETER LogPath
        Path to the log file. Defaults to "$env:USERPROFILE\install-log.txt".
    .EXAMPLE
        $apps = @{ "eza"="eza-community.eza"; "git"="Git.Git"; "7zip"="7zip.7zip" }
        Ensure-AppsInstalled -Apps $apps
    #>

    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Apps,

        [string]$LogPath = "$env:USERPROFILE\install-log.txt"
    )

    # --- Logging helper ---
    function Write-Log($message) {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        "$timestamp`t$message" | Out-File -FilePath $LogPath -Append
    }

    foreach ($app in $Apps.Keys) {
        $wingetId = $Apps[$app]

        # --- Registry snapshot ---
        $registryApps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                         HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                         HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                        Where-Object { $_.DisplayName -and $_.DisplayName -match $app }

        # --- Winget snapshot ---
        $wingetRaw = winget list --accept-source-agreements | Out-String
        $wingetApps = $wingetRaw -split "`n" | Where-Object { $_ -match $app }

        # --- Decision ---
        if ($registryApps -or $wingetApps) {
            Write-Output "✅ '$app' is already installed."
            Write-Log "Found '$app' installed."
        } else {
            Write-Output "⚠️ '$app' not found."
            Write-Log "'$app' not found."

            $response = Read-Host "Do you want to install '$app' via winget? (Y/N)"
            if ($response -match '^[Yy]$') {
                Write-Output "📦 Installing '$app'..."
                Write-Log "Installing '$app' via winget..."
                winget install --id $wingetId --silent --accept-package-agreements --accept-source-agreements
                Write-Log "'$app' installation attempted."
            } else {
                Write-Output "❌ Skipped installation of '$app'."
                Write-Log "Skipped installation of '$app'."
            }
        }
    }
}

function Set-MyFolders{
    <#
    .SYNOPSIS
        Sets up my home .local and .config folders
    .DESCRIPTION
        This sets up some linuxy folders in the home directory, and creates symbolic links
        back to windows style locations.  The purpose here is to let me use the same configs
        in my dotfiles repo across OSes.
    #>

    Write-Output "Setting up the bin folders..."

    ###############################
    ### Check for AppData\Local\Bin and create it if necessary
    ###############################
    if (-not (Test-Path -Path $HOME\AppData\Local\Bin)) {
        Write-Host "Local\Bin not found in AppData.  Creating."
        New-Item -ItemType Directory $HOME\AppData\Local\Bin
    } else {
        Write-Host "$HOME\AppData\Local\Bin exists"
    }

    ###############################
    ### Create a $HOME\.local
    ###############################
    $localtarget = "$HOME\.local"
    Write-Host -ForegroundColor Cyan "Checking if $localtarget folder exists ..."
    if (-not (Test-Path -Path $localtarget)) {
        Write-Host -ForgroundColor Green "Not found, creating $localtarget."
        New-Item -ItemType Directory $localtarget
    } else {
        Write-Host -ForegroundColor Yellow "$localtarget already exists."
    }
    Write-Host -ForegroundColor Cyan "Adding the 'Hidden' attribute to $localtarget..."
    $(Get-Item -Force $localtarget).Attributes = $(Get-Item -Force $localtarget).Attributes -bor [System.IO.FileAttributes]::Hidden
    
    Write-Host -ForegroundColor Cyan "Checking for bin link..."
    if (-not (Test-Path -Path $localtarget\bin)) {
        Write-Host -ForegroundColor Green "Creating SymbolicLink for bin"
        New-Item -ItemType SymbolicLink -Path $localtarget\bin -Target $HOME\AppData\Local\Bin
    } else {
        if ($(Get-Item -Force $localtarget\bin).LinkType -eq "SymbolicLink") {
            Write-Host -ForegroundColor Yellow "bin target found, its target is $(Get-Item -Force $localtarget\bin).LinkTarget"
            Write-Host -ForegroundColor Yellow "`t Is that right?"
        } else {
            Write-Host -ForegroundColor Yellow "bin target found. It doesn't appear to be a SymbolicLink."
        }
    }
    
    # create $HOME\.config and hide it
    $configtarget = "$HOME\.config"
    write-host -ForegroundColor Cyan "Checking for $configtarget..."
    if (-not (Test-Path -Path $configtarget)) {
        Write-Host -ForegroundColor Green "$configtarget not found.  Creating..."
        New-Item -ItemType Directory $configtarget
    } else {
        write-host -ForegroundColor Yellow "$configtarget exists."
    }
    Write-Host -ForegroundColor Cyan "Hiding $configtarget..."
    $(Get-Item -Force $configtarget).Attributes = $(Get-Item -Force $configtarget).Attributes -bor [System.IO.FileAttributes]::Hidden
    
    ### Check to see if there's the default Windows Powershell profile directory
    ### Make it if it doesn't exist
    if (-not (Test-Path "$HOME\.config\powershell") -and (Test-Path "$HOME\.config")) {
        if (-not (Test-Path "$HOME\Documents\Powershell")) {
            New-Item -ItemType Directory $HOME\Documents\Powershell
        }
    }
    if (-not (Test-Path "$configtarget\powershell")) {
        New-Item -ItemType SymbolicLink -Path "$HOME\.config\powershell" -Target "$HOME\Documents\Powershell"
    }

}

$apps = @{
    "eza"   = "eza-community.eza"
    "git"   = "Git.Git"
    "7zip"  = "7zip.7zip"
    "vscode"= "Microsoft.VisualStudioCode"
    "AutoHotkey" = "AutoHotkey.AutoHotkey"
    "Starship" = "Starship.Starship"
    "direnv" = "direnv.direnv"
    "WindowsTerminal" = "Microsoft.WindowsTerminal"
}

# Inform the user and wait for input

if (-not $IsWindows) {
    Write-Host -ForegroundColor Red -BackgroundColor Black "This script is only for running on Windows."
    exit
}


Write-Host "Setting up directories..."
Set-MyFolders

Write-Host "This script will install your chosen applications."
$confirmation = Read-Host "Press Enter to continue or type 'exit' to stop"

if ($confirmation -eq 'exit') {
    Write-Host "Exiting the script."
    exit
}

# Run the installation process
Ensure-AppsInstalled -Apps $apps

# Continue with the rest of your script
