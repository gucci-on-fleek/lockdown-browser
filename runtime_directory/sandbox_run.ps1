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

$lockdown_extract_dir = "C:\Windows\Temp\Lockdown"
$lockdown_installer = Get-ChildItem Lockdown* | Select-Object -First 1
if (-not $lockdown_installer) {
    Write-Log "No Lockdown installer found in the current directory. Exiting..."
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
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
    Get-ChildItem -Path "HKLM:\HARDWARE\DESCRIPTION" | Remove-ItemProperty -Name SystemBiosVersion -ErrorAction Ignore
    Remove-Item -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -ErrorAction Ignore
    $vmcompute_path = [System.Environment]::GetFolderPath("System") + "\VmComputeAgent.exe"
    takeown /f $vmcompute_path
    icacls $vmcompute_path /grant "Everyone:(D)"
    Remove-Item -Path $vmcompute_path -ErrorAction Ignore
    Write-Log "Removed system information successfully."
}

function Install-LockdownBrowser {
    if ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
        Write-Log "Installing Lockdown Browser OEM..."
        & $lockdown_installer /s /r
        Write-Log "OEM installer executed."
        Wait-Process -Name *setup*
    }
    else {
        & $lockdown_installer /x "`"$lockdown_extract_dir`""
        # Dumb installer needs a quoted path, even with no spaces. 
        # Also, we have to extract the program before we can even run a silent install.
        Write-Log "Extracting Lockdown Browser..."
        Wait-Process -Name *Lockdown* # For some weird reason, if the extracter gets killed the installer can fail sometimes on missing a file.
        # You get get a prompt saying it's been extracted, so just click okay.
        if (-not (Test-Path "$lockdown_extract_dir\setup.exe")) {
            Write-Log "Setup file not found after extraction. Exiting..."
            exit 1
        }
        Write-Log "Installing Lockdown Browser..."
        & "$lockdown_extract_dir\setup.exe" /s "/f1$PSScriptRoot\setup.iss" "/f2$PSScriptRoot\..\setup.log"
        Write-Log "Setup executed."
        Wait-Process -Name "setup"
    }
    # Remove existing shortcut if it exists
    $public_desktop_path = "C:\Users\Public\Desktop"
    $shortcut_path = Join-Path -Path $public_desktop_path -ChildPath "LockDown Browser.lnk"
    if (Test-Path $shortcut_path) {
        Remove-Item -Path $shortcut_path -Force
        Write-Log "Removed existing LockDown Browser shortcut from public desktop."
    }
}

function Register-URLProtocol {
    Write-Log "Registering URL protocol(s)..."
    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
    if ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
        # I got the urls from installing LDB OEM and looking in the regestery for :Lockdown Broswe OEM and fould all these HKCR keys."
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
    if ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
        $script_content = @'
# Ask for the URL
$url = Read-Host -Prompt "Please enter the URL"
# Change directory and run the command
Set-Location "C:\Users\WDAGUtilityAccount\Desktop\runtime_directory"
./withdll /d:GetSystemMetrics-Hook.dll "C:\Program Files (x86)\Respondus\LockDown Browser OEM\LockDownBrowserOEM.exe" $url
'@
    }
    else {
        $script_content = @'
Set-Location C:\Users\WDAGUtilityAccount\Desktop\runtime_directory\
.\withdll.exe /d:GetSystemMetrics-Hook.dll "C:\Program Files (x86)\Respondus\LockDown Browser\LockDownBrowser.exe"
'@
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