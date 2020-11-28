<!-- Lockdown Browser in Windows Sandbox
     https://github.com/gucci-on-fleek/lockdown-browser
     SPDX-License-Identifier: MPL-2.0+
     SPDX-FileCopyrightText: 2020 gucci-on-fleek
-->
# Lockdown Browser in Windows Sandbox

## Building

Run `build.ps1`. You’ll need the "Visual Studio C++ Tools" and "git" to be installed.

## Running

1. Build the project as shown above.
2. [Install the Windows Sandbox.](https://www.howtogeek.com/399290/how-to-use-windows-10s-new-sandbox-to-safely-test-apps/)
3. Download the "Respondus Lockdown Browser" and place it in `runtime_directory\`.
4. Double-click `Sandbox.wsb` (it’s in `runtime_directory\`)
5. Wait. It’ll take about a minute, but eventually the Lockdown Browser will open.
