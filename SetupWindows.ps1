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

function Set-BinFolder {
    Write-Output "Setting up bin folders..."

    # Create a local bin folder for my apps and scripts in a windowsy way
    $applocalbin = "$HOME\AppData\Local\Bin"

    $local = "$HOME\.local"

    if (-not (Test-Path -Path $applocalbin)) {
        New-Item -ItemType Directory $applocalbin
    }
    
    if (-not (Test-Path -Path $local)) {
        New-Item -ItemType Directory $local\bin
        $localbin.Attributes = $localbin.Attributes -bor [System.IO.FileAttributes]::Hidden
    }
    
    New-Item -ItemType SymbolicLink -Path "$local\bin" -Target "$applocalbin"

    return true
}

function Test-Stuff{

}

$apps = @{
    "eza"   = "eza-community.eza"
    "git"   = "Git.Git"
    "7zip"  = "7zip.7zip"
    "vscode"= "Microsoft.VisualStudioCode"
}

Ensure-AppsInstalled -Apps $apps
