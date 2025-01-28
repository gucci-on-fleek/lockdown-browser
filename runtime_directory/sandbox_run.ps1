# Lockdown Browser in Windows Sandbox
# https://github.com/gucci-on-fleek/lockdown-browser
# SPDX-License-Identifier: MPL-2.0+
# SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125

# DON'T RUN THIS ON YOUR REGULAR SYSTEM! IT WILL CAUSE **IRREVERSIBLE** DAMAGE. (Well it's been fixed, but don't try.)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3

# Create log file on the desktop
$desktop_path = [System.Environment]::GetFolderPath("Desktop")
$log_file_path = Join-Path -Path $desktop_path -ChildPath "sandbox_run.log"
function Write-Log {
    param (
        [string]$message
    )
    $time_stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $log_message = "$time_stamp - $message"
    Add-Content -Path $log_file_path -Value $log_message
}

# Check if running as WDAGUtilityAccount (Sandbox)
if ($env:USERNAME -ne "WDAGUtilityAccount") {
    Write-Log "This script is intended to run only in Windows Sandbox. Exiting..."
    exit 1
}

Set-Location $PSScriptRoot

$lockdown_extract_dir = [System.Environment]::GetFolderPath("System") + "\Temp\Lockdown"
$lockdown_installer = Get-ChildItem Lockdown*
if ($lockdown_installer.Count -ne 1) {
    Write-Log "Multiple or no Lockdown installers found in the current directory. Exiting..."
    exit 1
}
elseif ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
    $lockdown_runtime = [System.Environment]::GetFolderPath("ProgramFilesX86") + "\Respondus\LockDown Browser OEM\LockDownBrowserOEM.exe"
}
else {
    $lockdown_runtime = [System.Environment]::GetFolderPath("ProgramFilesX86") + "\Respondus\LockDown Browser\LockDownBrowser.exe"
}

function Remove-SystemInfo {
    Write-Log "Removing system information..."
    Get-ChildItem -Path "HKLM:\HARDWARE\DESCRIPTION" | Remove-ItemProperty -Name SystemBiosVersion -ErrorAction Ignore
    Remove-Item -Path [System.Environment]::GetFolderPath("System") + "\BIOS" -ErrorAction Ignore
    $vmcompute_path = [System.Environment]::GetFolderPath("System") + "\System32\VmComputeAgent.exe"
    takeown /f $vmcompute_path
    icacls $vmcompute_path /grant "Everyone:(D)"
    Remove-Item -Path $vmcompute_path -ErrorAction Ignore
    Write-Log "Removed system information successfully."
}

function Install-LockdownBrowser {
    Write-Log "Installing Lockdown Browser..."
    if ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
        & $lockdown_installer /s /r
        Write-Log "OEM installer executed."
    }
    else {
        & $lockdown_installer /x "`"$lockdown_extract_dir`""
        # Dumb installer needs a quoted path, even with no spaces. 
        # Also, we have to extract the program before we can even run a silent install.
        Write-Log "Extracting Lockdown Browser..."
        while (!(Test-Path "$lockdown_extract_dir\id.txt")) {
            Start-Sleep -Seconds 0.2
        }
        Start-Sleep -Seconds 1
        Stop-Process -Name *Lockdown* -ErrorAction Ignore

        if (-not (Test-Path "$lockdown_extract_dir\setup.exe")) {
            Write-Log "Setup file not found after extraction. Exiting..."
            exit 1
        }

        & "$lockdown_extract_dir\setup.exe" /s "/f1$PSScriptRoot\setup.iss" "/f2$PSScriptRoot\..\setup.log"
        Write-Log "Setup executed."
        Wait-Process -Name "setup"
    }
}

function Register-URLProtocol {
    Write-Log "Registering URL protocol..."
    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
    if ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
        $urls = @("anst", "cllb", "ibz", "ielb", "jnld", "jzl", "ldb", "ldb1", "pcgs", "plb", "pstg", "rzi", "uwfb", "xmxg")
        $urls | ForEach-Object {
            try {
                Set-ItemProperty -Path "HKCR:\$_\shell\open\command" -Name "(Default)" -Value ('"' + $PSScriptRoot + '\withdll.exe" "/d:' + $PSScriptRoot + '\GetSystemMetrics-Hook.dll" ' + $lockdown_runtime + ' "%1"')
                Write-Log "Successfully set item property for URL protocol $_."
            }
            catch {
                # I had some interminitent errors, so I want them logged for debugging.
                Write-Log "Failed to set item property for URL protocol $_. Error: $_"
            }
        }
    }
    else {
        try {
            Set-ItemProperty -Path "HKCR:\rldb\shell\open\command" -Name "(Default)" -Value ('"' + $PSScriptRoot + '\withdll.exe" "/d:' + $PSScriptRoot + '\GetSystemMetrics-Hook.dll" ' + $lockdown_runtime + ' "%1"')
            Write-Log "Successfully set item property for URL protocol rldb."
        }
        catch {
            Write-Log "Failed to set item property for URL protocol rldb. Error: $_"
        }    
    }
}

function New-RunLockdownBrowserScript {
    Write-Log "Creating run script on desktop..."
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
    if ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
        $script_content = @"
# Ask for the URL
$url = Read-Host -Prompt "Please enter the URL"
Write-Host "Running Lockdown Browser with URL: $url"
# Define the lockdown runtime path
$lockdown_runtime = [System.Environment]::GetFolderPath("ProgramFilesX86") + "Respondus\LockDown Browser OEM\LockDownBrowserOEM.exe"
# Change directory and run the command
cd "C:\Users\WDAGUtilityAccount\Desktop\runtime_directory"
./withdll /d:GetSystemMetrics-Hook.dll $lockdown_runtime $url
"@
    }
    else {
        # Remove existing shortcut if it exists
        $public_desktop_path = "C:\Users\Public\Desktop"
        $shortcut_path = Join-Path -Path $public_desktop_path -ChildPath "LockDown Browser.lnk"
        if (Test-Path $shortcut_path) {
            Remove-Item -Path $shortcut_path -Force
            Write-Log "Removed existing LockDown Browser shortcut from public desktop."
        }
        $script_content = @"
cd C:\Users\WDAGUtilityAccount\Desktop\runtime_directory\
.\withdll.exe /d:GetSystemMetrics-Hook.dll $lockdown_runtime
"@
    }
    $script_path = Join-Path -Path $desktop_path -ChildPath "runlockdownbrowser.ps1"
    Set-Content -Path $script_path -Value $script_content
}

# Main script execution
Write-Log "Script started."
Remove-SystemInfo
Install-LockdownBrowser
Register-URLProtocol
New-RunLockdownBrowserScript
Write-Log "Script completed."