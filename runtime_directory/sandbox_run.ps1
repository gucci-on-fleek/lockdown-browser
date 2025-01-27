# Lockdown Browser in Windows Sandbox
# https://github.com/gucci-on-fleek/lockdown-browser
# SPDX-License-Identifier: MPL-2.0+
# SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125

# DON'T RUN THIS ON YOUR REGULAR SYSTEM! IT WILL CAUSE **IRREVERSIBLE** DAMAGE. (Well it's been fixed, but don't try.)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3

# Create log file on the desktop
$desktopPath = [System.Environment]::GetFolderPath('Desktop')
$logFilePath = Join-Path -Path $desktopPath -ChildPath 'sandbox_run.log'
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
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

if ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
    $lockdown_runtime = "C:\Program Files (x86)\Respondus\LockDown Browser OEM\LockDownBrowserOEM.exe"
}
else {
    $lockdown_runtime = "C:\Program Files (x86)\Respondus\LockDown Browser\LockDownBrowser.exe"
}

function Remove-SystemInfo {
    Write-Log "Removing system information..."
    Get-ChildItem -Path "HKLM:\HARDWARE\DESCRIPTION" | Remove-ItemProperty -Name SystemBiosVersion -ErrorAction Ignore
    Remove-Item -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -ErrorAction Ignore
    $vmcompute_path = "C:\Windows\System32\VmComputeAgent.exe"
    takeown /f $vmcompute_path
    Start-Process -FilePath "icacls" -ArgumentList "$vmcompute_path /grant `"Everyone:(D)`"" -Wait
    Remove-Item -Path $vmcompute_path -ErrorAction Ignore
}

function Install-LockdownBrowser {
    Write-Log "Installing Lockdown Browser..."
    if ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
        & $lockdown_installer /s /r
        Write-Log "OEM installer executed."
    }
    else {
        & $lockdown_installer /x "`"$lockdown_extract_dir`"" 
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
            Set-ItemProperty -Path "HKCR:\$_\shell\open\command" -Name "(Default)" -Value ('"' + $PSScriptRoot + '\withdll.exe" "/d:' + $PSScriptRoot + '\GetSystemMetrics-Hook.dll" ' + $lockdown_runtime + ' "%1"')
        }
    }
    else {
        Set-ItemProperty -Path "HKCR:\rldb\shell\open\command" -Name "(Default)" -Value ('"' + $PSScriptRoot + '\withdll.exe" "/d:' + $PSScriptRoot + '\GetSystemMetrics-Hook.dll" ' + $lockdown_runtime + ' "%1"')
    }
}

function New-RunLockdownBrowserScript {
    Write-Log "Creating run script on desktop..."
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
    if ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
        $ScriptContent = @'
# Ask for the URL
$url = Read-Host -Prompt "Please enter the URL (Working! You don't need "")"
Write-Host "Running Lockdown Browser with URL: $url"
# Define the lockdown runtime path
$lockdown_runtime = "C:\Program Files (x86)\Respondus\LockDown Browser OEM\LockDownBrowserOEM.exe"
# Change directory and run the command
cd "C:\Users\WDAGUtilityAccount\Desktop\runtime_directory"
./withdll /d:GetSystemMetrics-Hook.dll $lockdown_runtime $url
'@
    }
    else {
        # Remove existing shortcut if it exists
        $publicDesktopPath = "C:\Users\Public\Desktop"
        $shortcutPath = Join-Path -Path $publicDesktopPath -ChildPath 'LockDown Browser.lnk'
        if (Test-Path $shortcutPath) {
            Remove-Item -Path $shortcutPath -Force
            Write-Log "Removed existing LockDown Browser shortcut from public desktop."
        }
        $scriptContent = @'
cd C:\Users\WDAGUtilityAccount\Desktop\runtime_directory\
.\withdll.exe /d:GetSystemMetrics-Hook.dll $lockdown_runtime
'@
    }
    $script_path = Join-Path -Path $desktopPath -ChildPath 'runlockdownbrowser.ps1'
    Set-Content -Path $script_path -Value $scriptContent
}

# Main script execution
Write-Log "Script started."
Remove-SystemInfo
Install-LockdownBrowser
Register-URLProtocol
New-RunLockdownBrowserScript
Write-Log "Script completed."