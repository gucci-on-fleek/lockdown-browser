# Lockdown Browser in Windows Sandbox
# https://github.com/gucci-on-fleek/lockdown-browser
# SPDX-License-Identifier: MPL-2.0+
# SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125

param(
    [switch]$Clean, # If passed, remove directories/files as specified.
    [switch]$Logs  # If passed, zip the logs folder after the build.
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3

Set-Location $PSScriptRoot

mkdir "./logs" -Force
$log_file_path = Join-Path -Path $PSScriptRoot -ChildPath "logs/Build.log"

function Write-Log {
    param (
        [string]$message
    )
    $time_stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $log_message = "$time_stamp - $message"
    Write-Host $log_message
    $log_message | Out-File -FilePath $log_file_path -Append -Encoding UTF8
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Log "Error: git is not installed or not available in the system's PATH"
    throw "git is not installed or not available in the system's PATH"
}

# If removal flag -Clean is passed, check for the .git folder; if missing, delete specified files.
if ($Clean) {
    Write-Log "Removal flag specified (-Clean): Checking for .git folder."
    $git_folder = Join-Path $PSScriptRoot ".git"
    if (-not (Test-Path $git_folder)) {
        Write-Log ".git folder is missing. Deleting specified build files."
        $files_to_delete = @(
            "runtime_directory\GetSystemMetrics-Hook.dll",
            "runtime_directory\sandbox.wsb",
            "runtime_directory\sandbox-with-Microphone-Camera.wsb",
            "runtime_directory\withdll.exe",
            "\Detours",
            "\Build"
        )
        foreach ($relative_path in $files_to_delete) {
            $file_path = Join-Path $PSScriptRoot $relative_path
            if (Test-Path $file_path) {
                Remove-Item $file_path -Force
                Write-Log "Deleted file: $file_path"
            }
            else {
                Write-Log "File not found, skipping deletion: $file_path"
            }
        }
    }
    else {
        git clean -xd -f --exclude='Lockdown*.exe' --exclude='logs'
    }
    Write-Log "Deletion complete."
}

# If the log flag (-Logs) is passed, combine all logs into a single file.
if ($Logs) {
    Write-Log "Logs being put in one file as requested by -logs flag"
    $all_logs_path = Join-Path $PSScriptRoot "logs/all-logs.log"
    if (Test-Path $all_logs_path) {
        Remove-Item $all_logs_path -Force
    }
    Get-ChildItem -Path "./logs" -Filter *.log | Sort-Object Name | ForEach-Object {
        Add-Content -Path $all_logs_path -Value "=== $($_.Name) ==="
        Add-Content -Path $all_logs_path -Value ""
        Get-Content $_.FullName | Add-Content -Path $all_logs_path
        Add-Content -Path $all_logs_path -Value "\n\n"
    }
    Write-Log "Logs put in one file to $all_logs_path"
    exit
}

function Initialize-VS {
    Write-Log "Initializing Visual Studio environment"
    Import-Module VSSetup
    $vs_instances = @(Get-VSSetupInstance)
    if (-not $vs_instances -or $vs_instances.Length -eq 0) {
        $answer = Read-Host "No Visual Studio Build Tools instances found. This can sometimes be wrong. If you have installed this press Y. (y/N)"
        if ($answer -ne '^[yY]$') {
            Write-Log "Error: No Visual Studio Build Tools instances found"
            throw "No Visual Studio instances found"
        }
        else {
            Write-Log "Bypassing Visual Studio environment initialization as per user request"
            return
        }
    }
    Push-Location $vs_instances[0].InstallationPath
    $cmd_args = '/c .\VC\Auxiliary\Build\vcvars32.bat'
    $cmd_args += ' & set "'
    $cmd_out = & 'cmd' $cmd_args
    Pop-Location

    $env_vars = @{}
    $cmd_out | ForEach-Object {
        if ($_ -match '=') {
            $key, $value = $_ -split '=', 2
            $env_vars[$key] = $value
        }
    }
    $env_vars.Keys | ForEach-Object {
        if ($_ -and $env_vars[$_]) {
            Set-Item -Force -Path "env:\$_"  -Value "$($env_vars[$_])"
        }
    }
    Write-Log "Visual Studio environment initialized"
}

function Invoke-DetoursBuild {
    Write-Log "Building Detours"
    git submodule update --init
    Push-Location Detours\src
    nmake
    Pop-Location
    Push-Location Detours\samples\syelog
    nmake
    Pop-Location
    Push-Location Detours\samples\withdll
    nmake
    Pop-Location
    Write-Log "Detours built"
}

function New-Hook {
    Write-Log "Building hook"
    mkdir './build' -Force
    Push-Location build
    cl '/EHsc' `
        '/LD' `
        '/Fe:GetSystemMetrics-Hook.dll' `
        '../src/GetSystemMetrics-Hook.cpp' `
        '/I../Detours/include' `
        '/link' '/nodefaultlib:oldnames.lib' `
        '/export:DetourFinishHelperProcess,@1,NONAME' `
        '/export:GetSystemMetrics' `
        '../Detours\lib.X86\detours.lib' `
        '../Detours\lib.X86\syelog.lib' `
        'user32.lib'
    # Most of these are pretty standard VS C++ compiler options, but of note is "/export:DetourFinishHelperProcess,@1,NONAME".
    # The program will not be functional without this argument, but it isn't that well documented.
    Pop-Location
    Write-Log "Hook built"
}

function Initialize-Sandbox {
    Write-Log "Building sandbox configuration"
    $host_folder_path = Join-Path -Path $PSScriptRoot -ChildPath 'runtime_directory'
    $log_folder_path = Join-Path -Path $PSScriptRoot -ChildPath 'logs'
    (Get-Content ./src/Sandbox.xml) -replace '{{HOST_FOLDER}}', $host_folder_path `
        -replace '{{LOG_FOLDER}}', $log_folder_path | Set-Content ./build/Sandbox.wsb
    (Get-Content ./src/Sandbox-with-Microphone-Camera.xml) -replace '{{HOST_FOLDER}}', $host_folder_path `
        -replace '{{LOG_FOLDER}}', $log_folder_path | Set-Content ./build/Sandbox-with-Microphone-Camera.wsb
    Write-Log "Sandbox configuration built"
}

function Copy-Files {
    Write-Log "Copying files to runtime directory"
    Push-Location runtime_directory
    Copy-Item ../Detours/bin.X86/withdll.exe .
    Copy-Item ../build/GetSystemMetrics-Hook.dll .
    Copy-Item ../build/Sandbox.wsb .
    Copy-Item ../build/Sandbox-with-Microphone-Camera.wsb .
    Pop-Location
    Write-Log "Files copied to runtime directory"
}

function Get-SystemInfo {
    Write-Log "Selected system information:"
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Log "Architecture: $($os.OSArchitecture)"
    Write-Log "Windows Version: $($os.Caption)"
    Write-Log "Windows Build: $($os.BuildNumber)"
    if ($os.Caption -match "(Home|Pro|Pro For Workstations|Enterprise)") {
        if ($matches[0] -eq "Home") {
            throw "Unsupported Windows edition: Home. Pro or higher is required."
        }
        Write-Log "Windows Edition: $($matches[0])"
    }
    else {
        Write-Log "Windows Edition: Unknown"
    }
    if (Test-Path "$env:windir\System32\WindowsSandbox.exe") {
        Write-Log "Windows Sandbox is installed."
    }
    else {
        throw "Windows Sandbox is not installed."
    }
    $av_status = Get-MpComputerStatus
    Write-Log "Antivirus Real-Time Protection: $($av_status.RealTimeProtectionEnabled)"
    $vpn_connections = Get-VpnConnection
    if ($vpn_connections) {
        foreach ($vpn in $vpn_connections) {
            Write-Log "VPN '$($vpn.Name)' status: $($vpn.ConnectionStatus)"
        }
    }
    else {
        Write-Log "No VPN connections found."
    }
    $vs_instances = Get-VSSetupInstance
    Write-Log "Visual Studio Instances:"
    $vs_instances | ForEach-Object { Write-Log " - $($_.InstallationPath)" }
    $repo_version = git describe --long 2>$null
    if ($repo_version) {
        Write-Log "Repository version: $repo_version"
    }
    else {
        Write-Log "Repository version not available."
    }
    $submodule_status = git submodule status 2>$null
    if ($submodule_status) {
        Write-Log "Submodule status: $submodule_status"
    }
    else {
        Write-Log "Submodule status not available."
    }
    $vs_setup_complete = Get-VSSetupInstance | Format-List | Out-String
    Write-Log "Complete Visual Studio Setup Instances:"
    Write-Log "$vs_setup_complete"
}

try {
    Write-Log "----------------------------------------"
    Write-Log "Build script started"
    Get-SystemInfo
    Initialize-VS
    Invoke-DetoursBuild
    New-Hook
    Initialize-Sandbox
    Copy-Files
    Write-Log "Build script completed"
}
catch {
    Write-Log "An error occurred: $($_.Exception.Message) - $($_.Exception.StackTrace)"
    Set-Location $PSScriptRoot  # Put you back rather than random places in the script. -Voidless7125
    throw
    pause
}
