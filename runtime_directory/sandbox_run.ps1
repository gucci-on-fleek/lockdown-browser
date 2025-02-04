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
$lockdown_installer = Get-ChildItem *LockDown*.exe | Select-Object -First 1
if (-not $lockdown_installer) {
    Write-Log "No Lockdown installer found in the current directory. Exiting..."
    exit 1
}
elseif ($lockdown_installer.Name -like "LockDownBrowser-*.exe") {
    $is_oem = $false
    $lockdown_runtime = [System.Environment]::GetFolderPath("ProgramFilesX86") + "\Respondus\LockDown Browser\LockDownBrowser.exe"
}
else {
    $is_oem = $true
    $lockdown_runtime = [System.Environment]::GetFolderPath("ProgramFilesX86") + "\Respondus\LockDown Browser OEM\LockDownBrowserOEM.exe"
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
    if ($is_oem) {
        Write-Log "Installing Lockdown Browser OEM..."
        & $lockdown_installer /s /r
        Write-Log "OEM installer executed."
        while (-not (Get-Process -Name *ISBEW64* -ErrorAction SilentlyContinue)) {
            Start-Sleep -Seconds 0.25
        }
        Wait-Process -Name *ISBEW64*
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
        Wait-Process -Name *ISBEW64*
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
    if ($is_oem) {
        # I got the urls from installing LDB OEM and looking in the regestery for :Lockdown Broswe OEM and fould all these HKCR keys."
        $urls = @("anst", "cllb", "ibz", "ielb", "jnld", "jzl", "ldb", "ldb1", "pcgs", "plb", "pstg", "rzi", "uwfb", "xmxg")
        $urls | ForEach-Object {
            try {
                Set-ItemProperty -Path "HKCR:\$_\shell\open\command" -Name "(Default)" -Value ('"' + $PSScriptRoot + '\withdll.exe" "/d:' + $PSScriptRoot + '\GetSystemMetrics-Hook.dll" ' + $lockdown_runtime + ' "%1"')
                Write-Log "Successfully set item property for URL protocol $_."
            }
            catch {
                # I had some intermittent errors, so I want them logged for debugging.
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
    try {
        if ($is_oem) {
            $script_content = @'
$url = Read-Host -Prompt "Please enter the URL"
# Change directory and run the command
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
        if ($is_oem) {
            $shortcut.IconLocation = "C:\Program Files (x86)\Respondus\LockDown Browser OEM\LockDownBrowser.ico"
        }
        else {
            $shortcut.IconLocation = "C:\Program Files (x86)\Respondus\LockDown Browser\LockDownBrowser.ico"
        }
        $shortcut.Save()
        Write-Log "Run script and shortcut created on desktop."

        # Create a pop-up to test for errors
        # Win 11/10 style message box
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.Application]::EnableVisualStyles()
        $result = [System.Windows.Forms.MessageBox]::Show("Do you want to test launch Lockdown Browser to ensure that there are no errors? (Highly recommended).", "Test LockDown Browser", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            if ($is_oem) {
                # URL is from https://github.com/gucci-on-fleek/lockdown-browser/issues/43.
                Start-Process "powershell.exe" -ArgumentList "-Command `"Set-Location 'C:\Users\WDAGUtilityAccount\Desktop\runtime_directory'; ./withdll /d:GetSystemMetrics-Hook.dll 'C:\Program Files (x86)\Respondus\LockDown Browser OEM\LockDownBrowserOEM.exe' 'ldb:dh%7BKS6poDqwsi1SHVGEJ+KMYaelPZ56lqcNzohRRiV1bzFj3Hjq8lehqEug88UjowG1mK1Q8h2Rg6j8kFZQX0FdyA==%7D'`""
            }
            else {
                Start-Process "powershell.exe" -ArgumentList "-File `"$script_path`""
            }
        }
    }
    catch {
        Write-Log "Error creating run script or shortcut: $_"
    }
}

# Main script execution
Write-Log "Script started."
Remove-SystemInfo
Install-LockdownBrowser
Register-URLProtocol
New-RunLockdownBrowserScript
Write-Log "Script completed."
