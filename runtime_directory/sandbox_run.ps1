# Lockdown Browser in Windows Sandbox
# https://github.com/gucci-on-fleek/lockdown-browser
# SPDX-License-Identifier: MPL-2.0+
# SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125

# DON'T RUN THIS ON YOUR REGULAR SYSTEM! IT WILL CAUSE **IRREVERSIBLE** DAMAGE. (Well it's been fixed, but don't try.)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Create log file on the desktop
$desktop_path = [System.Environment]::GetFolderPath("Desktop")
$log_file_path = Join-Path -Path $desktop_path -ChildPath "logs/sandbox_run.log"
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
    throw "This script is intended to run only in Windows Sandbox. Exiting..."
}

Set-Location $PSScriptRoot

$lockdown_extract_dir = "C:\Windows\Temp\Lockdown"
$lockdown_installer = Get-ChildItem *LockDown*.exe | Select-Object -First 1
if (-not $lockdown_installer) {
    throw "No Lockdown installer found in the current directory. Exiting..."
}
elseif ($lockdown_installer.Name -like "LockDownBrowser-*.exe") {
    $is_oem = $false
    $lockdown_runtime = [System.Environment]::GetFolderPath("ProgramFilesX86") + "\Respondus\LockDown Browser\LockDownBrowser.exe"
    $browser_icon = [System.Environment]::GetFolderPath("ProgramFilesX86") + "\Respondus\LockDown Browser\LockDownBrowser.ico"
    $protocols = @("rldb")
 
}
else {
    $is_oem = $true
    $lockdown_runtime = [System.Environment]::GetFolderPath("ProgramFilesX86") + "\Respondus\LockDown Browser OEM\LockDownBrowserOEM.exe"
    $browser_icon = [System.Environment]::GetFolderPath("ProgramFilesX86") + "\Respondus\LockDown Browser OEM\LockDownBrowser.ico"
    # I got the urls from installing LDB OEM and looking in the registry for :Lockdown Browser OEM and found all these HKCR keys.
    $protocols = @("anst", "cllb", "ibz", "ielb", "jnld", "jzl", "ldb", "ldb1", "pcgs", "plb", "pstg", "rzi", "uwfb", "xmxg")
}

function Remove-SystemInfo {
    Write-Log "Removing system information..."
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
    Get-ChildItem -Path "HKLM:\HARDWARE\DESCRIPTION" | Remove-ItemProperty -Name SystemBiosVersion
    Remove-Item -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS"
    $vmcompute_path = [System.Environment]::GetFolderPath("System") + "\VmComputeAgent.exe"
    takeown /f $vmcompute_path
    icacls $vmcompute_path /grant "Everyone:(D)"
    Remove-Item -Path $vmcompute_path
    Write-Log "Removed system information successfully."
}

function Install-LockdownBrowser {
    if ($is_oem) {
        Write-Log "Installing Lockdown Browser OEM..."
        & $lockdown_installer /s /r
        Write-Log "OEM installer executed."
        while (-not (Get-Process -Name *ISBEW64*)) {
            Start-Sleep -Seconds 0.25
        }
        Wait-Process -Name *ISBEW64*
    }
    else {
        # Dumb installer needs a quoted path, even with no spaces.
        # Also, we have to extract the program before we can even run a silent install.
        & $lockdown_installer /x "`"$lockdown_extract_dir`""
        Write-Log "Extracting Lockdown Browser..."
        Wait-Process -Name *Lockdown* # For some weird reason, if the extracter gets killed the installer can fail sometimes on missing a file.
        # You get get a prompt saying it's been extracted, so just click okay.
        if (-not (Test-Path "$lockdown_extract_dir\setup.exe")) {
            throw "Setup file not found after extraction. Exiting..."
        }
        Write-Log "Installing Lockdown Browser..."
        & "$lockdown_extract_dir\setup.exe" /s "/f1$PSScriptRoot\setup.iss" "/f2$PSScriptRoot\..\logs\setup.log"
        Write-Log "Setup executed."
        Wait-Process -Name *ISBEW64*
        $shortcut = "C:\Users\Public\Desktop\LockDown Browser.lnk"
        1..20 | ForEach-Object {
            if (Test-Path $shortcut) { return }
            Start-Sleep -Milliseconds 500
            # It needs to be 500, its not reliable at 100.
        }
        if (Test-Path $shortcut) {
            Remove-Item $shortcut -Force
            Write-Log "Removed existing LockDown Browser shortcut."
        }
        else {
            Write-Log "Shortcut not found after waiting."
        }
    }
}

function Register-URLProtocol {
    Write-Log "Registering URL protocol(s)..."
    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
    foreach ($protocol in $protocols) {
        Set-ItemProperty -Path "HKCR:\$protocol\shell\open\command" -Name "(Default)" -Value ('"' + $PSScriptRoot + '\withdll.exe" "/d:' + $PSScriptRoot + '\GetSystemMetrics-Hook.dll" ' + $lockdown_runtime + ' "%1"')
        Write-Log "Successfully set item property for URL protocol $protocol."
    }
}

function New-RunLockdownBrowserScript {
    Write-Log "Creating run script on desktop..."
    # Build the script content.
    if ($is_oem) {
        $script_content = @'
$url = Read-Host -Prompt "Please enter the URL"
Set-Location "C:\Users\WDAGUtilityAccount\Desktop\runtime_directory"
./withdll /d:GetSystemMetrics-Hook.dll "C:\Program Files (x86)\Respondus\LockDown Browser OEM\LockDownBrowserOEM.exe" $url
'@
    }
    else {
        $script_content = @"
Set-Location C:\Users\WDAGUtilityAccount\Desktop\runtime_directory\
.\withdll.exe /d:GetSystemMetrics-Hook.dll "C:\Program Files (x86)\Respondus\LockDown Browser\LockDownBrowser.exe"
"@
    }
    $script_path = Join-Path -Path $desktop_path -ChildPath "Run-LockdownBrowser.ps1"
    Set-Content -Path $script_path -Value $script_content
    Set-ItemProperty -Path $script_path -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
    $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut("$desktop_path\Lockdown Browser.lnk")
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-File `"$script_path`""
    $shortcut.WorkingDirectory = $desktop_path
    $shortcut.WindowStyle = 1
    $shortcut.IconLocation = $browser_icon
    $shortcut.Save()

    # Remove existing Start Menu shortcut if it exists.
    $start_shortcut_path = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Respondus\LockDown Browser.lnk"
    1..20 | ForEach-Object {
        if (Test-Path $start_shortcut_path) { return }
        Start-Sleep -Milliseconds 100
    }
    if (Test-Path $start_shortcut_path) {
        Remove-Item $start_shortcut_path -Force
        Write-Log "Removed existing LockDown Browser start menu shortcut."
    }
    else {
        Write-Log "Start Menu Shortcut not found after waiting."
    }

    # Create new Start Menu shortcut.
    $wscriptShell = New-Object -ComObject WScript.Shell
    $start_menu_shortcut_object = $wscriptShell.CreateShortcut($start_shortcut_path)
    $start_menu_shortcut_object.TargetPath = "powershell.exe"
    $start_menu_shortcut_object.Arguments = "-File `"$script_path`""
    $start_menu_shortcut_object.WorkingDirectory = Split-Path $script_path
    $start_menu_shortcut_object.IconLocation = $browser_icon
    $start_menu_shortcut_object.Save()
    Write-Log "Run script, shortcut, and start menu shortcut created."

    # Display warnings based on Windows version.
    $os = Get-CimInstance Win32_OperatingSystem
    $version = [Version]$os.Version
    if ($version.Build -lt 22000) {
        [System.Windows.Forms.MessageBox]::Show("Warning: On Windows 10, you will be detected if you minimize the window.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
    elseif ($version.Build -ge 22000 -and $version.Build -lt 27686) {
        [System.Windows.Forms.MessageBox]::Show("Warning: On Windows 11 (22H2-24H2), the camera and mic may not work. Versions after 27686 don't have this issue.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }

    # Ask the user if they want to test launch LockDown Browser.
    $result = [System.Windows.Forms.MessageBox]::Show("Do you want to test launch Lockdown Browser to ensure that there are no errors? (Highly recommended).", "Test LockDown Browser", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        if ($is_oem) {
            # URL is from https://github.com/gucci-on-fleek/lockdown-browser/issues/43.
            Start-Process "powershell.exe" -ArgumentList "-Command `"Set-Location 'C:\Users\WDAGUtilityAccount\Desktop\runtime_directory'; ./withdll /d:GetSystemMetrics-Hook.dll 'C:\Program Files (x86)\Respondus\LockDown Browser OEM\LockDownBrowserOEM.exe' 'ldb:dh%7BKS6poDqwsi1SHVGEJ+KMYaelPZ56lqcNzohRRiV1bzFj3Hjq8lehqEug88UjowG1mK1Q8h2Rg6j8kZQX0FdyA==%7D'`""
        }
        else {
            Start-Process "powershell.exe" -ArgumentList "-File `"$script_path`""
        }
    }
}

try {
    # Functions in PowerShell are supposed to be like this, just learned.
    Write-Log "----------------------------------------"
    Write-Log "Script started."
    Remove-SystemInfo
    Install-LockdownBrowser
    Register-URLProtocol
    New-RunLockdownBrowserScript
    Write-Log "Script completed."
}
catch {
    Write-Log "An error occurred: $_"
    [System.Windows.Forms.MessageBox]::Show("An error occurred: $($_.Exception.Message) This has been logged into the logs folder on the host.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}
