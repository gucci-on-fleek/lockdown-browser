# Lockdown Browser in Windows Sandbox
# https://github.com/gucci-on-fleek/lockdown-browser
# SPDX-License-Identifier: MPL-2.0+
# SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125

# DON'T RUN THIS ON YOUR REGULAR SYSTEM! IT WILL CAUSE **IRREVERSIBLE** DAMAGE. (Well it's been fixed, but don't try.)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3

# Check if running as WDAGUtilityAccount (Sandbox)
if ($env:USERNAME -ne "WDAGUtilityAccount") {
    Write-Error "This script is intended to run only in Windows Sandbox. Exiting..."
    exit 1
}

Set-Location $PSScriptRoot

$lockdown_extract_dir = "C:\Windows\Temp\Lockdown"
$lockdown_installer = (Get-ChildItem Lockdown*)[0]

if ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
    $lockdown_runtime = "C:\Program Files (x86)\Respondus\LockDown Browser OEM\LockDownBrowserOEM.exe"
}
else {
    $lockdown_runtime = "C:\Program Files (x86)\Respondus\LockDown Browser\LockDownBrowser.exe"

}

function Remove-SystemInfo {
    Get-ChildItem -Path "HKLM:\HARDWARE\DESCRIPTION" | Remove-ItemProperty -Name SystemBiosVersion -ErrorAction Ignore
    Remove-Item -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -ErrorAction Ignore
    $vmcompute_path = "C:\Windows\System32\VmComputeAgent.exe"
    takeown /f $vmcompute_path
    icacls $vmcompute_path /grant "Everyone:(D)"
    Remove-Item -Path $vmcompute_path -ErrorAction Ignore
}

function Install-LockdownBrowser {
    if ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
        & $lockdown_installer /s /r
        # OEM intaller is random files being added, so we can't wait for a specific file to be created.
        # This broke *all my testing grr*
    }
    else {
        & $lockdown_installer /x "`"$lockdown_extract_dir`"" # Dumb installer needs a quoted path, even with no spaces. Also, we have to extract the program before we can even run a silent install.
        while (!(Test-Path "$lockdown_extract_dir\id.txt")) {
            # This is the easiest way to detect if the installer is finished extracting
            Start-Sleep -Seconds 0.2
        }
        Start-Sleep -Seconds 1
        Stop-Process -Name *Lockdown* -ErrorAction Ignore
    
        & "$lockdown_extract_dir\setup.exe" /s "/f1$PSScriptRoot\setup.iss" "/f2$PSScriptRoot\..\setup.log" # If we don't give a log file path, this doesn't work
        Wait-Process -Name "setup"
    }
}

function Register-URLProtocol {
    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
    if ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
        $urls = @("anst", "cllb", "ibz", "ielb", "jnld", "jzl", "ldb", "ldb1", "pcgs", "plb", "pstg", "rzi", "uwfb", "xmxg")
        foreach ($url in $urls) {
            Set-ItemProperty -Path "HKCR:\$url\shell\open\command" -Name "(Default)" -Value ('"' + $PSScriptRoot + '\withdll.exe" "/d:' + $PSScriptRoot + '\GetSystemMetrics-Hook.dll" ' + $lockdown_runtime + ' "%1"')
        }
    }
    else {
        Set-ItemProperty -Path "HKCR:\rldb\shell\open\command" -Name "(Default)" -Value ('"' + $PSScriptRoot + '\withdll.exe" "/d:' + $PSScriptRoot + '\GetSystemMetrics-Hook.dll" ' + $lockdown_runtime + ' "%1"')
    }
}

function New-RunLockdownBrowserScript {
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
        $scriptContent = @'
cd C:\Users\WDAGUtilityAccount\Desktop\runtime_directory\
.\withdll.exe /d:GetSystemMetrics-Hook.dll $lockdown_runtime
'@
    }
    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $scriptPath = Join-Path -Path $desktopPath -ChildPath 'runlockdownbrowserwithoutlink.ps1'
    Set-Content -Path $scriptPath -Value $scriptContent
}

# Main script execution
Remove-SystemInfo
Install-LockdownBrowser
Register-URLProtocol
New-RunLockdownBrowserScript
