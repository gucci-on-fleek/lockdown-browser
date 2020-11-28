<!-- Lockdown Browser in Windows Sandbox
     https://github.com/gucci-on-fleek/lockdown-browser
     SPDX-License-Identifier: MPL-2.0+
     SPDX-FileCopyrightText: 2020 gucci-on-fleek
-->
# _Lockdown Browser_ in _Windows Sandbox_

## What is this?

This repo allows you to run the [_Respondus Lockdown Browser_](https://web.respondus.com/he/lockdownbrowser/) in an isolated sandbox. Normally, the _Browser_ blocks you from running it if it detects that it is being virtualized. However, this tool bypasses the detection, allowing us to virtualize it.

## Disclaimer
**THIS TOOL IS NOT DESIGNED TO FACILITATE CHEATING!!!** The point of this tool is to prevent students from having to install invasive spyware on their personal computers, not to encourage or facilitate any form of academic dishonesty. I designed this tool for philosophical issues—I am uncomfortable installing random software from sketchy publishers on my personal computer—and this is its only intended use. Cheating is bad, but your loss of freedom by installing the _Browser_ is worse. If you do choose to use this tool contrary to my intent, **I AM NOT RESPONSABLE FOR ANY CONSEQUENCES THAT YOU FACE**. 

Also, this repository does not contain any intellectual property belonging to Respondus Inc. You must supply your legally-acquired _Browser_ `.exe` yourself. Any supporting and auxiliary files were either created by myself or gathered from various OSS projects with proper attribution.

## Building

Run `build.ps1`. You’ll need the “Visual Studio C++ Tools” and “git” to be installed.

## Running

1. Build the project as shown above.
2. [Install the _Windows Sandbox_.](https://www.howtogeek.com/399290/how-to-use-windows-10s-new-sandbox-to-safely-test-apps/)
3. Download the _Respondus Lockdown Browser_ and place it in `runtime_directory\`.
4. Double-click `Sandbox.wsb` (it’s in `runtime_directory\`)
5. Wait. It’ll take about a minute, but eventually the _Browser_ will open, completely automatically.

## Technical Details (How does it work?)

This repo consists of a few fairly simple tools cobbled together into a coherent package. 

The _Browser_ detects a few BIOS-related registry keys in `HKLM:\HARDWARE\DESCRIPTION`. Therefore, `sandbox_run.ps1` deletes these keys/values.

The _Browser_ calls `GetSystemMetrics(SM_REMOTESESSION)` to determine if it is running in and RDP session. Since this function is in `user32.dll`, there aren’t any trivial ways to fix this. However, [_Microsoft Detours_](https://github.com/microsoft/Detours) allows for you to intercept and replace any function in any `.dll`. A small hook (`GetSystemMetrics-Hook.cpp`) is used with `Detours` to intercept the function call and return a false value.

Because this tool runs in the _Windows Sandbox_, no state is retained between sessions. Therefore, this tool provides a scripted installer for the _Browser_. The _Browser_’s installer is a little tricky to script, so the installation is a little hacky, but it works. And again, the _Sandbox_ is completely isolated from the rest of your system, so the _Browser_ cannot cause any harm to your computer.
