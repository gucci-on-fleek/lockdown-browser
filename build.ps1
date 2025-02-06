# Lockdown Browser in Windows Sandbox
# https://github.com/gucci-on-fleek/lockdown-browser
# SPDX-License-Identifier: MPL-2.0+
# SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125

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
    Add-Content -Path $log_file_path -Value $log_message
}

function initialize_vs {
    try {
        Write-Log "Initializing Visual Studio environment"
        $vs_instances = Get-VSSetupInstance
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
        Write-Log "Visual Studio environment initialized"
    }
    catch {
        Write-Log "Error initializing Visual Studio environment: $($_.Exception.Message) - $($_.Exception.StackTrace)"
        throw
    }
}

function build_detours {
    try {
        Write-Log "Building Detours"
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Log "Error: git is not installed or not available in the system's PATH"
            throw "git is not installed or not available in the system's PATH"
        }
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
    catch {
        Write-Log "Error building Detours: $($_.Exception.Message) - $($_.Exception.StackTrace)"
        throw
    }
}

function build_hook {
    try {
        Write-Log "Building hook"
        mkdir './build' -Force
        Push-Location build
        cl '/EHsc' '/LD' '/Fe:GetSystemMetrics-Hook.dll' '../src/GetSystemMetrics-Hook.cpp' '/I../Detours/include' '/link' '/nodefaultlib:oldnames.lib' '/export:DetourFinishHelperProcess,@1,NONAME' '/export:GetSystemMetrics' '../Detours\lib.X86\detours.lib' '../Detours\lib.X86\syelog.lib' 'user32.lib' # Most of these are pretty standard VS C++ compiler options, but of note is "/export:DetourFinishHelperProcess,@1,NONAME". The program will not be functional without this argument, but it isn't that well documented.
        Pop-Location
        Write-Log "Hook built"
    }
    catch {
        Write-Log "Error building hook: $($_.Exception.Message) - $($_.Exception.StackTrace)"
        throw
    }
}

function build_sandbox {
    try {
        Write-Log "Building sandbox configuration"
        $hostFolderPath = $PSScriptRoot + '/runtime_directory'
        $logFolderPath = $PSScriptRoot + '/logs'
        
        (Get-Content ./src/Sandbox.xml) -replace '{{HOST_FOLDER}}', $hostFolderPath -replace '{{LOG_FOLDER}}', $logFolderPath | Set-Content ./build/Sandbox.wsb
        (Get-Content ./src/Sandbox-with-Microphone-Camera.xml) -replace '{{HOST_FOLDER}}', $hostFolderPath -replace '{{LOG_FOLDER}}', $logFolderPath | Set-Content ./build/Sandbox-with-Microphone-Camera.wsb
        
        Write-Log "Sandbox configuration built"
    }
    catch {
        Write-Log "Error building sandbox configuration: $($_.Exception.Message) - $($_.Exception.StackTrace)"
        throw
    }
}

function copy_files {
    try {
        Write-Log "Copying files to runtime directory"
        Push-Location runtime_directory
        Copy-Item ../Detours/bin.X86/withdll.exe . # This is the program that actually injects the DLL
        Copy-Item ../build/GetSystemMetrics-Hook.dll .
        Copy-Item ../build/Sandbox.wsb .
        Copy-Item ../build/Sandbox-with-Microphone-Camera.wsb .
        Pop-Location
        Write-Log "Files copied to runtime directory"
    }
    catch {
        Write-Log "Error copying files to runtime directory: $($_.Exception.Message) - $($_.Exception.StackTrace)"
        throw
    }
}

Write-Log "----------------------------------------"
Write-Log "Build script started"
initialize_vs
build_detours
build_hook
build_sandbox
copy_files
Write-Log "Build script completed"