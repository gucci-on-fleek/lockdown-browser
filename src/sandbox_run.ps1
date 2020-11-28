# DON'T RUN THIS ON YOUR REGULAR SYSTEM! IT WILL CAUSE **IRREVERSIBLE** DAMAGE
# ok, it just deletes a few registry keys, but it's still not recommended

Get-ChildItem -Path "HKLM:\HARDWARE\DESCRIPTION" | Remove-ItemProperty -Name SystemBiosVersion

rm HKLM:\HARDWARE\DESCRIPTION\System\BIOS

$lockdown_installer = (ls Lockdown*)[0]

& $lockdown_installer /s

$lockdown_runtime = "C:\Program Files (x86)\Respondus\LockDown Browser\LockDownBrowser.exe"

./withdll /d:GetSystemMetrics-Hook.dll $lockdown_runtime
