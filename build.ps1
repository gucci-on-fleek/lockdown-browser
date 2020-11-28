cd $PSScriptRoot

function initialize_vs {
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
    mkdir './build'
    pushd build
    cl '/EHsc' '/LD' '/Fe:GetSystemMetrics-Hook.dll' '../src/GetSystemMetrics-Hook.cpp' '/I../Detours/include' '/link' '/nodefaultlib:oldnames.lib' '/export:DetourFinishHelperProcess,@1,NONAME' '/export:GetSystemMetrics' '../Detours\lib.X86\detours.lib' '../Detours\lib.X86\syelog.lib' 'user32.lib'
    popd
}

function build_sandbox {
    (Get-Content ./src/Sandbox.wsb).replace('{{HOST_FOLDER}}', $PSScriptRoot + '\runtime_directory') | Set-Content ./build/Sandbox.wsb
}

function copy_files {
    pushd runtime_directory
    cp ../Detours/bin.X86/withdll.exe .
    cp ../build/GetSystemMetrics-Hook.dll .
    cp ../build/Sandbox.wsb .
}

initialize_vs

build_detours

build_hook

build_sandbox

copy_files
