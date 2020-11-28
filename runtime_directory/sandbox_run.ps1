# Lockdown Browser in Windows Sandbox
# https://github.com/gucci-on-fleek/lockdown-browser
# SPDX-License-Identifier: MPL-2.0+
# SPDX-FileCopyrightText: 2020 gucci-on-fleek

# DON'T RUN THIS ON YOUR REGULAR SYSTEM! IT WILL CAUSE **IRREVERSIBLE** DAMAGE
# ok, it just deletes a few registry keys, but it's still not recommended

cd $PSScriptRoot

Get-ChildItem -Path "HKLM:\HARDWARE\DESCRIPTION" | Remove-ItemProperty -Name SystemBiosVersion

rm HKLM:\HARDWARE\DESCRIPTION\System\BIOS

$lockdown_installer = (ls Lockdown*)[0]

$lockdown_runtime = "C:\Program Files (x86)\Respondus\LockDown Browser\LockDownBrowser.exe"

& $lockdown_installer /x "`"C:\Windows\Temp\Lockdown`""

sleep 10

kill -Name *Lockdown*

& "C:\Windows\Temp\Lockdown\setup.exe" /s "/f1$PSScriptRoot\setup.iss" "/f2C:\Users\wdagutilityaccount\Desktop\setup.log"

while (!(Test-Path $lockdown_runtime)) {
    sleep 0.25 
}

sleep 5

./withdll /d:GetSystemMetrics-Hook.dll $lockdown_runtime
