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

function Remove-BIOSInfo {
    Get-ChildItem -Path "HKLM:\HARDWARE\DESCRIPTION" | Remove-ItemProperty -Name SystemBiosVersion -ErrorAction Ignore
    Remove-Item -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -ErrorAction Ignore
}

function Remove-VmComputeAgent {
    $vmcompute_path = "C:\Windows\System32\VmComputeAgent.exe"
    takeown /f $vmcompute_path
    icacls $vmcompute_path /grant "Everyone:(D)"
    Remove-Item -Path $vmcompute_path
}

function Expand-LockdownBrowser {
    & $lockdown_installer /x "`"$lockdown_extract_dir`"" # Dumb installer needs a quoted path, even with no spaces. Also, we have to extract the program before we can even run a silent install.
    while (!(Test-Path "$lockdown_extract_dir\id.txt")) {
        # This is the easiest way to detect if the installer is finished extracting
        Start-Sleep -Seconds 0.2
    }
    Start-Sleep -Seconds 1
    Stop-Process -Name *Lockdown* -ErrorAction Ignore
}

function Install-LockdownBrowser {
    & "$lockdown_extract_dir\setup.exe" /s "/f1$PSScriptRoot\setup.iss" "/f2$PSScriptRoot\..\setup.log" # If we don't give a log file path, this doesn't work
    Wait-Process -Name "setup"
}

function Install-LockdownBrowserOEM {
    & $lockdown_installer /s /r
    $test = "C:\Program Files (x86)\Respondus\LockDown Browser OEM\"
    while (!(Test-Path "$test/am.pak")) {
        # This is the easiest way to detect if the installer is finished extracting
        Start-Sleep -Seconds 0.2
    }
    Start-Sleep -Seconds 1
    Stop-Process -Name *Setup* -ErrorAction Ignore
}

function Register-URLProtocol {
    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
    Set-ItemProperty -Path "HKCR:\rldb\shell\open\command" -Name "(Default)" -Value ('"' + $PSScriptRoot + '\withdll.exe" "/d:' + $PSScriptRoot + '\GetSystemMetrics-Hook.dll" ' + $lockdown_runtime + ' "%1"')
}

function New-RunLockdownBrowserScript {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $scriptContent = @'
cd C:\Users\WDAGUtilityAccount\Desktop\runtime_directory\
.\withdll.exe /d:GetSystemMetrics-Hook.dll "C:\Program Files (x86)\Respondus\LockDown Browser\LockDownBrowser.exe"
'@
    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $scriptPath = Join-Path -Path $desktopPath -ChildPath 'runlockdownbrowserwithoutlink.ps1'
    Set-Content -Path $scriptPath -Value $scriptContent
}

# Main script execution
Remove-BIOSInfo
Remove-VmComputeAgent

if ($lockdown_installer.Name -like "LockDownBrowserOEMSetup.exe") {
    $lockdown_runtime = "C:\Program Files (x86)\Respondus\LockDown Browser OEM\LockDownBrowserOEM.exe"
    Install-LockdownBrowserOEM
}
else {
    $lockdown_runtime = "C:\Program Files (x86)\Respondus\LockDown Browser\LockDownBrowser.exe"
    Expand-LockdownBrowser
    Install-LockdownBrowser
    Register-URLProtocol
    New-RunLockdownBrowserScript
}