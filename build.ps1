# Lockdown Browser in Windows Sandbox
# https://github.com/gucci-on-fleek/lockdown-browser
# SPDX-License-Identifier: MPL-2.0+
# SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3

Set-Location $PSScriptRoot

# Import the VSSetup module to use Get-VSSetupInstance function
Import-Module VSSetup

mkdir "./logs" -Force
$log_file_path = Join-Path -Path $PSScriptRoot -ChildPath "logs/Build.log"

function write_log {
    param (
        [string]$message
    )
    $time_stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $log_message = "$time_stamp - $message"
    Add-Content -Path $log_file_path -Value $log_message
}

function initialize_vs_environment {
    write_log "Initializing Visual Studio environment"
    $vs_instances = Get-VSSetupInstance
    if (-not $vs_instances -or $vs_instances.Length -eq 0) {
        write_log "Error: No Visual Studio Build Tools instances found"
        throw "No Visual Studio instances found"
    }
    
    $vs_path = $vs_instances[0].InstallationPath

    try {
        Push-Location -Path $vs_path
        # Run the vcvars32.bat and then output all env variables via 'set'
        $cmd = "cmd.exe"
        $vc_args = '/c "VC\Auxiliary\Build\vcvars32.bat'
        $environment_output = & $cmd $vc_args
    }
    finally {
        Pop-Location
    }

    if (-not $environment_output) {
        write_log "Error: Failed to retrieve Visual Studio environment variables"
        throw "Failed to retrieve Visual Studio environment variables"
    }

    foreach ($line in $environment_output) {
        $split_index = $line.IndexOf("=")
        if ($split_index -gt 0) {
            $key = $line.Substring(0, $split_index).Trim()
            $value = $line.Substring($split_index + 1).Trim()
            if ($key -and $value) {
                Set-Item -Force -Path "env:$key" -Value $value
            }
        }
    }
    write_log "Visual Studio environment initialized"
}

# Helper function to execute a script block in a given directory
function invoke_command_in_directory {
    param (
        [Parameter(Mandatory)]
        [string]$directory,
        [Parameter(Mandatory)]
        [ScriptBlock]$script
    )
    Push-Location $directory
    try {
        & $script
    }
    finally {
        Pop-Location
    }
}

function build_detours {
    write_log "Building Detours"
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        write_log "Error: git is not installed or not available in the system's PATH"
        throw "git is not installed or not available in the system's PATH"
    }
    git submodule update --init

    # List of directories to run nmake in
    $nmake_directories = @(
        "Detours\src",
        "Detours\samples\syelog",
        "Detours\samples\withdll"
    )

    foreach ($dir in $nmake_directories) {
        invoke_command_in_directory -Directory $dir -Script { nmake }
    }
    write_log "Detours built"
}

function build_hook {
    write_log "Building hook"
    $build_dir = Join-Path $PSScriptRoot "build"
    if (-not (Test-Path $build_dir)) {
        mkdir $build_dir -Force
    }
    invoke_command_in_directory -Directory $build_dir -Script {
        cl '/EHsc' '/LD' '/Fe:GetSystemMetrics-Hook.dll' '../src/GetSystemMetrics-Hook.cpp' '/I../Detours/include' `
            '/link' '/nodefaultlib:oldnames.lib' '/export:DetourFinishHelperProcess,@1,NONAME' '/export:GetSystemMetrics' `
            '../Detours\lib.X86\detours.lib' '../Detours\lib.X86\syelog.lib' 'user32.lib'
    }
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
    initialize_vs_environment
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
