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
function write_log {
    param (
        [string]$message
    )
    $time_stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $log_message = "$time_stamp - $message"
    Write-Host $log_message
    $log_message | Out-File -FilePath $log_file_path -Append -Encoding UTF8
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    write_log "Error: git is not installed or not available in the system's PATH"
    throw "git is not installed or not available in the system's PATH"
}

# If removal flag -Clean is passed, delete specified directories and files
if ($Clean) {
    write_log "Removal flag specified (-Clean): Cleaning directories and files"
    git clean -xd -f --exclude='Lockdown*.exe' --exclude='logs'  # By default you need the force flag -f.
    write_log "Removal complete"
}

# If the log flag (-Logs) is passed, create a one logs file.
if ($Logs) {
    write_log "Logs being put in one file as requested by -logs flag"
    $allLogsPath = Join-Path $PSScriptRoot "logs/all-logs.log"
    if (Test-Path $allLogsPath) { Remove-Item $allLogsPath -Force }
    Get-ChildItem -Path "./logs" -Filter *.log | Sort-Object Name | ForEach-Object {
        Add-Content -Path $allLogsPath -Value "=== $($_.Name) ==="
        Add-Content -Path $allLogsPath -Value ""
        Get-Content $_.FullName | Add-Content -Path $allLogsPath
        Add-Content -Path $allLogsPath -Value ""
        Add-Content -Path $allLogsPath -Value ""
    }
    write_log "Logs put in one file to $allLogsPath"
    exit
}

function initialize_vs {
    write_log "Initializing Visual Studio environment"
    # Import the VSSetup module to use Get-VSSetupInstance function
    Install-Module VSSetup -Scope CurrentUser
    Import-Module VSSetup
    # Bypasses error on not finding length of $vs_instances. - Voidless7125
    $vs_instances = @(Get-VSSetupInstance)
    if (-not $vs_instances -or $vs_instances.Length -eq 0) {
        $answer = Read-Host "No Visual Studio Build Tools instances found. This can sometimes be wrong. If you have installed this press Y. (y/N)"
        if ($answer -ne "y") {
            write_log "Error: No Visual Studio Build Tools instances found"
            throw "No Visual Studio instances found"
        }
        else {
            write_log "Bypassing Visual Studio environment initialization as per user request"
            return
        }
    }
    Push-Location $vs_instances[0].InstallationPath
    $cmd_args = '/c .\VC\Auxiliary\Build\vcvars32.bat'
    $cmd_args += ' & set "' # The 'set "' command (with the trailing quotation mark) reveals hidden environment variables
    
    $cmd_out = & 'cmd' $cmd_args
    Pop-Location

    $env_vars = @{}
    $cmd_out | ForEach-Object {
        if ($_ -match '=') {
            $key, $value = $_ -split '='
            $env_vars[$key] = $value
        }
    }
    $env_vars.Keys | ForEach-Object {
        if ($_ -and $env_vars[$_]) {
            set-item -force -path "env:\$($_)"  -value "$($env_vars[$_])"
        }
    }
    write_log "Visual Studio environment initialized"
}

function build_detours {
    write_log "Building Detours"
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
    write_log "Detours built"
}

function build_hook {
    write_log "Building hook"
    mkdir './build' -Force
    Push-Location build
    cl '/EHsc' '/LD' '/Fe:GetSystemMetrics-Hook.dll' '../src/GetSystemMetrics-Hook.cpp' '/I../Detours/include' '/link' '/nodefaultlib:oldnames.lib' '/export:DetourFinishHelperProcess,@1,NONAME' '/export:GetSystemMetrics' '../Detours\lib.X86\detours.lib' '../Detours\lib.X86\syelog.lib' 'user32.lib'  # Most of these are pretty standard VS C++ compiler options, but of note is "/export:DetourFinishHelperProcess,@1,NONAME". The program will not be functional without this argument, but it isn't that well documented.
    Pop-Location
    write_log "Hook built"
}

function build_sandbox {
    write_log "Building sandbox configuration"
    $host_folder_path = Join-Path -Path $PSScriptRoot -ChildPath 'runtime_directory'
    $log_folder_path = Join-Path -Path $PSScriptRoot -ChildPath 'logs'
    (Get-Content ./src/Sandbox.xml) -replace '{{HOST_FOLDER}}', $host_folder_path -replace '{{LOG_FOLDER}}', $log_folder_path | Set-Content ./build/Sandbox.wsb
    (Get-Content ./src/Sandbox-with-Microphone-Camera.xml) -replace '{{HOST_FOLDER}}', $host_folder_path -replace '{{LOG_FOLDER}}', $log_folder_path | Set-Content ./build/Sandbox-with-Microphone-Camera.wsb
    write_log "Sandbox configuration built"
}

function copy_files {
    write_log "Copying files to runtime directory"
    Push-Location runtime_directory
    Copy-Item ../Detours/bin.X86/withdll.exe . # This is the program that actually injects the DLL
    Copy-Item ../build/GetSystemMetrics-Hook.dll .
    Copy-Item ../build/Sandbox.wsb .
    Copy-Item ../build/Sandbox-with-Microphone-Camera.wsb .
    Pop-Location
    write_log "Files copied to runtime directory"
}

try {
    write_log "----------------------------------------"
    write_log "Build script started"
    write_log "Collecting system information..."
    $sysInfo = systeminfo 2>&1 | Out-String
    $regexFilter = 'Registered Owner|Time Zone|Wireless|Wi-Fi|Network Card|Bluetooth|DHCP|IP address|Connection Name|NIC|Status:|Realtek|Wintun|\b\d{1,3}(\.\d{1,3}){3}\b|fe80::'
    $sysInfo -split "`n" | ForEach-Object {
        if (($_ -ne "") -and ($_ -notmatch $regexFilter)) {
            write_log $_.Trim()
        }
    }
    initialize_vs
    build_detours
    build_hook
    build_sandbox
    copy_files
    write_log "Build script completed"
}
catch {
    write_log "An error occurred: $($_.Exception.Message) - $($_.Exception.StackTrace)"
    throw
}