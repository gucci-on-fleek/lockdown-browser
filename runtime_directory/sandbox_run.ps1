# Lockdown Browser in Windows Sandbox
# https://github.com/gucci-on-fleek/lockdown-browser
# SPDX-License-Identifier: MPL-2.0+
# SPDX-FileCopyrightText: 2020-2022 gucci-on-fleek

# DON'T RUN THIS ON YOUR REGULAR SYSTEM! IT WILL CAUSE **IRREVERSIBLE** DAMAGE

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3

cd $PSScriptRoot

$lockdown_extract_dir = "C:\Windows\Temp\Lockdown"
$lockdown_runtime = "C:\Program Files (x86)\Respondus\LockDown Browser\LockDownBrowser.exe"
$lockdown_installer = (ls Lockdown*)[0]

Get-ChildItem -Path "HKLM:\HARDWARE\DESCRIPTION" | Remove-ItemProperty -Name SystemBiosVersion -ErrorAction Ignore
rm HKLM:\HARDWARE\DESCRIPTION\System\BIOS -ErrorAction Ignore

# We're in a short-lived VM, so we can safely delete any necessary files
$vmcompute_path = "C:\Windows\System32\VmComputeAgent.exe"
takeown /f $vmcompute_path
icacls $vmcompute_path /grant "Everyone:(D)"
rm $vmcompute_path

& $lockdown_installer /x "`"$lockdown_extract_dir`"" # Dumb installer needs a quoted path, even with no spaces. Also, we have to extract the program before we can even run a silent install.
while (!(Test-Path $lockdown_extract_dir\id.txt)) {
    # This is the easiest way to detect if the installer is finished extracting
    sleep 0.2
}
sleep 1
kill -Name *Lockdown*

& "$lockdown_extract_dir\setup.exe" /s "/f1$PSScriptRoot\setup.iss" "/f2$PSScriptRoot\..\setup.log" # If we don't give a log file path, this doesn't work
Wait-Process -Name "setup"

# Support use of the `rldb://` URL protocol
New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
Set-ItemProperty -Path "HKCR:\rldb\shell\open\command" -Name "(Default)" -Value ('"' + $PSScriptRoot + '\withdll.exe" "/d:' + $PSScriptRoot + '\GetSystemMetrics-Hook.dll" ' + $lockdown_runtime + ' "%1"')

./withdll /d:GetSystemMetrics-Hook.dll $lockdown_runtime
