# Lockdown Browser in Windows Sandbox
# https://github.com/gucci-on-fleek/lockdown-browser
# SPDX-License-Identifier: MPL-2.0+
# SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3

Set-Location $PSScriptRoot

function initialize_vs {
    Set-PSRepository PSGallery -InstallationPolicy Trusted
    Install-Module VSSetup -Scope CurrentUser
    Push-Location (Get-VSSetupInstance)[0].InstallationPath
    $cmd_args = '/c .\VC\Auxiliary\Build\vcvars32.bat'
    $cmd_args += ' & set "'# The 'set "' command (with the trailing quotation mark) reveals hidden environment variables

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
}

function build_detours {
    git submodule init
    git submodule update
    Push-Location Detours
    Push-Location src
    nmake
    Pop-Location
    Push-Location samples\syelog
    nmake
    Pop-Location
    Push-Location samples\withdll
    nmake
    Pop-Location
    Pop-Location
}

function build_hook {
    mkdir './build' -Force
    Push-Location build
    cl '/EHsc' '/LD' '/Fe:GetSystemMetrics-Hook.dll' '../src/GetSystemMetrics-Hook.cpp' '/I../Detours/include' '/link' '/nodefaultlib:oldnames.lib' '/export:DetourFinishHelperProcess,@1,NONAME' '/export:GetSystemMetrics' '../Detours\lib.X86\detours.lib' '../Detours\lib.X86\syelog.lib' 'user32.lib' # Most of these are pretty standard VS C++ compiler options, but of note is "/export:DetourFinishHelperProcess,@1,NONAME". The program will not be functional without this argument, but it isn't that well documented.
    Pop-Location
}

function build_sandbox {
    # Sadly, the Sandbox doesn't support relative host paths, so we have to find-and-replace at build time.
    (Get-Content ./src/Sandbox.xml).replace('{{HOST_FOLDER}}', $PSScriptRoot + '/runtime_directory') | Set-Content ./build/Sandbox.wsb
    (Get-Content ./src/Sandbox-with-Microphone-Camera.xml).replace('{{HOST_FOLDER}}', $PSScriptRoot + '/runtime_directory') | Set-Content ./build/Sandbox-with-Microphone-Camera.wsb
}

function copy_files {
    Push-Location runtime_directory
    Copy-Item ../Detours/bin.X86/withdll.exe . # This is the program that actually injects the DLL
    Copy-Item ../build/GetSystemMetrics-Hook.dll .
    Copy-Item ../build/Sandbox.wsb .
    Copy-Item ../build/Sandbox-with-Microphone-Camera.wsb .
    Pop-Location
}

initialize_vs
build_detours
build_hook
build_sandbox
copy_files
