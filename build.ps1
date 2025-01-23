# Lockdown Browser in Windows Sandbox
# https://github.com/gucci-on-fleek/lockdown-browser
# SPDX-License-Identifier: MPL-2.0+
# SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3

cd $PSScriptRoot

function initialize_vs {
    Set-PSRepository PSGallery -InstallationPolicy Trusted
    Install-Module VSSetup -Scope CurrentUser
    pushd (Get-VSSetupInstance)[0].InstallationPath
    $cmd_args = '/c .\VC\Auxiliary\Build\vcvars32.bat'
    $cmd_args += ' & set "'# 'set "' (with the trailing quotation mark) also shows the hidden variables

    $cmd_out = & 'cmd' $cmd_args
    popd

    $env_vars = @{}
    $cmd_out | % {
        if ($_ -match '=') {
            $key, $value = $_ -split '='
            $env_vars[$key] = $value
        }
    }
    $env_vars.Keys | % {
        if ($_ -and $env_vars[$_]) {
            set-item -force -path "env:\$($_)"  -value "$($env_vars[$_])"
        }
    }
}

function build_detours {
    git submodule init
    git submodule update
    pushd Detours
    pushd src
    nmake
    popd
    pushd samples\syelog
    nmake
    popd
    pushd samples\withdll
    nmake
    popd
    popd
}


function build_hook {
    mkdir './build' -Force
    pushd build
    cl '/EHsc' '/LD' '/Fe:GetSystemMetrics-Hook.dll' '../src/GetSystemMetrics-Hook.cpp' '/I../Detours/include' '/link' '/nodefaultlib:oldnames.lib' '/export:DetourFinishHelperProcess,@1,NONAME' '/export:GetSystemMetrics' '../Detours\lib.X86\detours.lib' '../Detours\lib.X86\syelog.lib' 'user32.lib' # Most of these are pretty standard VS C++ compiler options, but of note is "/export:DetourFinishHelperProcess,@1,NONAME". The program will not be functional without this argument, but it isn't that well documented.
    popd
}

function build_sandbox {
    # Sadly, the Sandbox doesn't support relative host paths, so we have to find-and-replace at build time.
    (Get-Content ./src/Sandbox.wsb).replace('{{HOST_FOLDER}}', $PSScriptRoot + '\runtime_directory') | Set-Content ./build/Sandbox.wsb
    (Get-Content ./src/Sandbox-with-Microphone-Camera.wsb).replace('{{HOST_FOLDER}}', $PSScriptRoot + '\runtime_directory') | Set-Content ./build/Sandbox-with-Microphone-Camera.wsb
}

function copy_files {
    pushd runtime_directory
    cp ../Detours/bin.X86/withdll.exe . # This is the program that actually injects the DLL
    cp ../build/GetSystemMetrics-Hook.dll .
    cp ../build/Sandbox.wsb .
    cp ../build/Sandbox-with-Microphone-Camera.wsb .
    popd
}

initialize_vs

build_detours

build_hook

build_sandbox

copy_files
