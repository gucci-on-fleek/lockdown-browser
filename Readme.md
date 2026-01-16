<!-- Lockdown Browser in Windows Sandbox
     https://github.com/gucci-on-fleek/lockdown-browser
     SPDX-License-Identifier: MPL-2.0+ OR CC-BY-SA-4.0+
     SPDX-FileCopyrightText: 2020-2026 gucci-on-fleek and Voidless7125
-->
# _Lockdown Browser_ in _Windows Sandbox_

[View Demo Video](https://github.com/user-attachments/assets/46c9f405-2c2b-4576-b06f-82daf07b1db3)

## What is this?

This repo allows you to run the [_Respondus Lockdown Browser_](https://web.respondus.com/he/lockdownbrowser/) in an isolated sandbox, completely bypassing its “security measures.” Usually, the Lockdown Browser blocks you from running it if it detects that it is being virtualized. However, this tool bypasses the detection, allowing us to virtualize it.

## Project Status

### 2026-01-16

#### Technical Comments

Sometime in [February
2025](https://github.com/gucci-on-fleek/lockdown-browser/issues/132), we
began receiving reports that the _Lockdown Browser_ was detecting the
tool in this repository. Respondus rolls out updates fairly slowly, so
this did not affect most users at first, but around [May
2025](https://github.com/gucci-on-fleek/lockdown-browser/issues/152),
most users had received the update, and were therefore detected if they
used this tool. Detection is
[often](https://github.com/gucci-on-fleek/lockdown-browser/issues/176)
followed by a [permanent
ban](https://github.com/gucci-on-fleek/lockdown-browser/issues/157), so
although there is a _chance_ that this tool might still work, it would
be quite risky to try.

As mentioned in the previous update below, I have little time or ability
to continue working on this project, so it is relatively unlikely that I
myself will update this repository to work with the latest versions of
the _Lockdown Browser_. Nevertheless, I will continue to intermittently
reply to
[issues](https://github.com/gucci-on-fleek/lockdown-browser/issues) and
[discussions](https://github.com/gucci-on-fleek/lockdown-browser/discussions),
and I will _gladly_ accept any [pull
requests](https://github.com/gucci-on-fleek/lockdown-browser/pulls) that
help improve this project. Please follow [issue
#132](https://github.com/gucci-on-fleek/lockdown-browser/issues/132) if
you are interested on status updates regarding support for newer
versions of the _Lockdown Browser_.

#### Non-Technical Comments

This project isn't dead, but—barring someone contributing a patch—it's
probably finished. I'd like to thank all the contributors over the
years: [@shirt-dev](https://github.com/shirt-dev),
[@mayed505](https://github.com/mayed505),
[@dustindog101](https://github.com/dustindog101), and especially
[@Voidless7125](https://github.com/Voidless7125). Somewhat ironically, I
would also like to thank Respondus—I strongly disagree with how their
software operates and their stance on privacy, but when they found out
about this tool, [instead of responding aggressively like some of
their
competitors](https://arstechnica.com/tech-policy/2025/11/proctorio-settles-curious-lawsuit-with-librarian-who-shared-public-youtube-videos/),
they simply patched their own software.

Finally, as a note to any non-programmers who may be reading this, I
would like to point out that this project has _never_ provided
ready-to-install binary releases; instead, it has [always required users
to download the source
code](https://github.com/gucci-on-fleek/lockdown-browser#license), which
they can then use [to create a usable version of the software
themselves](https://github.com/gucci-on-fleek/lockdown-browser#system-requirements).
I did this for three reasons:

1. First, to ensure that users would be able to inspect the source
   themselves, therefore allowing them to confirm that this tool
   functions as documented. This is the opposite of the _Lockdown
   Browser_, where users have no way to verify that the software works
   as advertised, and must therefore trust Respondus.

2. Second, my goal in releasing this repository was to show that the
   _Lockdown Browser_ was ineffective. Proponents of the _Browser_ argue
   that it's justified to trade reduced privacy for increased security,
   but if the _Browser_ is ineffective, then there is no trade-off;
   you're just sacrificing privacy for no benefit. It is important to
   publicly release the source so that anyone can reproduce this bypass
   to demonstrate the _Browser_'s poor security, but as I never
   intended for anyone to use this tool to cheat, it merely needs to be
   _possible_ to reproduce the bypass, not easy.

3. Finally, I wrote the original implementation in a single day, and
   this original implementation was only a little more than 100 lines of
   code; my belief was that nearly anyone capable of installing a C
   compiler and compiling this software would be able to independently
   reproduce this bypass, with only a few hours of work, merely by
   reading the three paragraph [“How does it work?”
   section](https://github.com/gucci-on-fleek/lockdown-browser#technical-details-how-does-it-work)
   below.

### 2024-02-10

The following was originally posted in [Discussion
#53](https://github.com/gucci-on-fleek/lockdown-browser/discussions/53);
the technical details are no longer relevant and have been elided here,
but the overall background still stands.

> \[…]
>
> #### Background
>
> Back when <ac>COVID</ac> first hit, some of my professors began to
> mandate that we use _Respondus Lockdown Browser_ and _Respondus Monitor_
> to write our exams. I was incensed that we were required to install this
> invasive software on our personal computers and submit to being recorded
> by some random company, with no option to opt-out. I argued with my
> professors that this requirement was both unnecessary and unethical, but
> they refused to budge.
>
> I proceeded to submit [a formal
> complaint](https://github.com/gucci-on-fleek/lockdown-browser/files/14229105/respondus-concerns-redacted.pdf)
> to the administration, and after a protracted series of emails, they
> eventually offered an alternative, and having no other options, I
> accepted. But this alternate writing method was fairly arduous: before
> each exam, I would drive to the campus, check out a laptop, and drive
> back home. On my personal laptop, I would start a video call with my
> professor who would watch me while I wrote the exam; on the campus
> laptop, I would use the _Lockdown Browser_ (without _Monitor_) to take
> the exam. Once I was finished, I would drive back to campus to return
> the laptop. And furthermore, I was the only student who was allowed to
> use this method—everyone else was still required to use _Respondus
> Monitor_.
>
>
> #### Development
>
> So then why did I decide to write this project?
>
> 1.  To show that the _Browser_ is ineffective.
>
>     All of my complaints were ignored because the university considers
>     “preventing cheating” to be more important than the privacy of its
>     students. But if the _Browser_ were shown as being completely
>     useless, then the university would have no reason to continue using
>     it.
>
> 2.  Help honest students protect their privacy.
>
>     Not all students were as lucky as I was to be offered an alternative
>     writing method. I released this project to help the students who
>     legitimately care about their privacy to partially alleviate some of
>     the _Browser_'s flaws.
>
>     Of course, it is certainly possible to use this project to cheat on
>     exams, but you could say that about nearly any technology. The mere
>     _possibility_ of cheating is not a valid reason to invade the
>     privacy of every student.
>
>
> #### Present Day
>
> Four years ago, I started this project. It has now been three years
> since I transferred to a different university that does not use any
> invasive monitoring software, and two years since I have had any access
> to a computer that runs _Windows_.
>
> What does this mean for the project? It means that I have little
> motivation or ability to make any significant updates to it. I do try to
> reply to
> [issues](https://github.com/gucci-on-fleek/lockdown-browser/issues) and
> [discussions](https://github.com/gucci-on-fleek/lockdown-browser/discussions)
> whenever possible, but I've been quite slow at responding for this past
> year since I've been busy with other things. I tend to respond quicker
> to [pull
> requests](https://github.com/gucci-on-fleek/lockdown-browser/pulls)
> though.
>
>
> #### Future
>
> \[…]
>
> So what comes next? Well, it's up to you. If you're able to find a way
> to patch around the _Browser_'s upcoming update, then [submit a pull
> request](https://github.com/gucci-on-fleek/lockdown-browser/pulls).
> Otherwise, you'll need to wait for someone else to do so.
>
> #### Links
>
> - [“Federal Judge: Invasive Online Proctoring "Room Scans" Are
>   Unconstitutional”,
>   EFF](https://www.eff.org/deeplinks/2022/08/federal-judge-invasive-online-proctoring-room-scans-are-also-unconstitutional)
>
> - [“After Students Challenged Proctoring Software, French Court Slaps
>   TestWe App With a Suspension”,
>   EFF](https://www.eff.org/deeplinks/2023/03/after-students-challenged-proctoring-software-french-court-slaps-testwe-app)
>
> - [“A Long Overdue Reckoning For Online Proctoring Companies May Finally
>   Be Here”,
>   EFF](https://www.eff.org/deeplinks/2021/06/long-overdue-reckoning-online-proctoring-companies-may-finally-be-here)
>
> - [“The Security Failures of Online Exam Proctoring”, Schneier on
>   Security](https://www.schneier.com/blog/archives/2020/11/the-security-failures-of-online-exam-proctoring.html)
>
> - [“The extremely shady "educational integrity" industry”, Cory
>   Doctorow](https://pluralistic.net/2022/02/16/unauthorized-paper/#cheating-anticheat)
>
> - [“The pandemic showed remote proctoring to be worse than useless”,
>   Cory
>   Doctorow](https://pluralistic.net/2021/06/24/proctor-ology/#miseducation)
>
> - [“Can You Trust Your Computer?”, Richard
>   Stallman](https://www.gnu.org/philosophy/can-you-trust.html)
>
> - [“The Right to Read”, Richard
>   Stallman](https://www.gnu.org/philosophy/right-to-read.html))

## Timeline

<dl>
<dt>

2020-11-27, 11am

<dd>

I initially begin investigating how to bypass the _Lockdown Browser_'s
restrictions.

<dt>

[2020-11-27, 11pm](https://github.com/gucci-on-fleek/lockdown-browser/commit/69e28fc9d14f26a32ffae7d3210342894b518a90)

<dd>

I finished writing the initial proof-of-concept. The tool is fully
functional at this point, although the documentation and build scripts
aren't very polished yet. Nevertheless, even today, the repository uses
the same technique used to bypass the _Browser_'s restrictions as [this
initial
release](https://github.com/gucci-on-fleek/lockdown-browser/tree/69e28fc9d14f26a32ffae7d3210342894b518a90).

<dt>

[2021-11-27](https://github.com/gucci-on-fleek/lockdown-browser/commit/190df3ccb6ffdef948c3b99ff3671c3bb1058aa1)

<dd>

The repository is released to the public.

<dt>

[2022-03-24](https://github.com/gucci-on-fleek/lockdown-browser/pull/2)

<dd>

I accept the first contribution from an external contributor.

<dt>

[2022-12-08](https://web.archive.org/web/20221208051901/https://github.com/gucci-on-fleek/lockdown-browser)

<dd>

The earliest version of the repository available from the Internet
Archive.

<dt>

[2024-02-10](https://github.com/gucci-on-fleek/lockdown-browser/discussions/53)

<dd>

The repository is linked to from Respondus's internal bug tracker.

<dt>Summer 2024

<dd>

The repository now has [100+ stars on
GitHub](https://www.star-history.com/#gucci-on-fleek/lockdown-browser)
and the [77th support request was
opened](https://github.com/gucci-on-fleek/lockdown-browser/issues/77).

<dt>

[2025-01-17](https://github.com/gucci-on-fleek/lockdown-browser/pull/84)

<dd>

[@Voidless7125](https://github.com/Voidless7125)'s first contribution is
accepted. He handles most of the support requests and contributes the
vast majority of the new code over the next year. (Thanks!)

<dt>

[February 2025](https://github.com/gucci-on-fleek/lockdown-browser/issues/132)

<dd>

Respondus releases their first update that detects and blocks this tool.
However, Respondus rolls out updates slowly, so most users are still
unaffected.

<dd>

[2025-04-30](https://github.com/gucci-on-fleek/lockdown-browser/issues/170)

A user confirms that Respondus is aware of this repository.

<dt>

[May 2025](https://github.com/gucci-on-fleek/lockdown-browser/issues/152)

<dd>

The update has rolled out to most users, so this tool no longer works
for most users.

<dt>

2026-01-16

<dd>

This repository has received a total of [259
stars](https://github.com/gucci-on-fleek/lockdown-browser/stargazers)
and [180 support
requests](https://github.com/gucci-on-fleek/lockdown-browser/discussions/180).

</dl>

## Why the _Lockdown Browser_ is bad

First, I am uncomfortable installing random software on my computer. I only install software that is open source or from a trusted publisher, and this software is neither.

Second, the _Lockdown Browser_ is essentially indistinguishable from malware. Read the following list of documented behaviors and see how similar these behaviors are to actual malware.

- They recommend [disabling your antivirus software](https://archive.md/rj0Z7#73%).
- The only way to exit it is to [physically power off your computer](https://archive.md/cp1L3#34%).
- It [disables the Task Manager](https://archive.md/HgFeS#33%).
- It [tracks all open software](https://archive.md/4OFCQ#33%).

And, of course, there are privacy issues. Cheating is no doubt an issue, but school-mandated surveillance software is a step too far. This is the most significant issue. I strongly recommend reading the following links from the EFF, a non-profit that focuses on defending digital privacy.

- _[Proctoring Apps Subject Students to Unnecessary Surveillance](https://www.eff.org/deeplinks/2020/08/proctoring-apps-subject-students-unnecessary-surveillance)_
- _[Students Are Pushing Back Against Proctoring Surveillance Apps](https://www.eff.org/deeplinks/2020/09/students-are-pushing-back-against-proctoring-surveillance-apps)_
- _[Senate Letter to Proctoring Companies](https://www.eff.org/document/senate-letter-proctoring-companies-12-3-2020)_

## Purpose

This tool is **not designed to facilitate cheating**. Instead, I built it for three purposes:

First, it is designed to show school administrators that the _Lockdown Browser_ is entirely ineffective. Respondus claims that it is the [“gold standard”](https://web.respondus.com/he/lockdownbrowser/) and that it cannot be bypassed, but that is false. I, a random University student, bypassed the _Lockdown Browser_ in **a single day**. This removes all of the (supposed) benefits of the _Lockdown Browser_, and thus makes [the issues](#why-the-lockdown-browser-is-bad) look even worse.

Second, it is designed to prevent students from having to install invasive spyware on their personal computers. Sometimes, administrators won’t listen and will still force the _Lockdown Browser_ on their students. This tool allows you to run the _Lockdown Browser_ in an isolated sandbox, thus preventing the _Lockdown Browser_ from modifying or spying on the rest of your computer. This tool is designed to run in the _Windows Sandbox_, but users should be able to adapt it to run in other Virtual Machine software quickly. This is especially valuable for Linux users since the _Lockdown Browser_ does not run on Linux and otherwise refuses to run in a VM.

Finally, this tool allows you to take screenshots of the _Lockdown Browser_. Typically, the _Lockdown Browser_ prevents you from taking screenshots of its window; however, this tool bypasses that restriction by running it inside the _Windows Sandbox_. Taking screenshots can provide accountability since nothing guarantees that no one changed your answers after submitting your test.

## Disclaimer

This repository does not contain any materials belonging to Respondus Inc. You must supply your legally-acquired _Lockdown Browser_ `.exe` yourself. Any supporting and auxiliary files were either created by myself or gathered from various OSS projects with proper attribution. This project is not endorsed by Respondus Inc. or anyone except myself.

This project is intended merely as a proof-of-concept. While this tool could be used to facilitate cheating, this is not my intent. Any consequences of using this tool in a real exam are entirely your responsibility.

Also, I’d like to point out that Respondus has explicitly granted permission for this type of research. [From their website](https://archive.md/WTat2#54%):
  > Hacker Tested, Market Approved – Hundreds of universities and schools around the world use LockDown Browser. It seems that at least one person (or team) at each institution makes it a quest to “break out” or beat the system. Some of the best minds have taken our software to task over the years, and we’ve addressed each issue that’s been raised. (Yes, **you have our blessing… go ahead and see if you can break it.**)

## System Requirements

- Windows 10/11 **Pro** or **Enterprise**

- [Visual Studio C++ Tools](https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=BuildTools)

  (Make sure to include the “MSVC C++ build tools” and “Windows SDK” components.)

- [git](https://git-scm.com/download/win)

## Building

Make sure to **clone** the repository and run `build.ps1`. Then, [install the _Windows Sandbox_](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-install). That’s it!

## Running

1. Build the project as shown above.
2. Download the _Respondus Lockdown Browser_ and place it in `runtime_directory\`.
3. Double-click `Sandbox.wsb` (it’s in `runtime_directory\`)

   (_Alternative_) If you want to pass your microphone and camera to the _Lockdown Browser_, run `Sandbox-with-Microphone-Camera.wsb` instead.
4. Go to your test and open it. The _Lockdown Browser_ will launch, and you can then use it to complete your test.

## Versions

The `release` branch (default) always points to the latest stable
release. You should use this branch since it is the most
well-tested. To switch to this branch (not generally necessary since
it’s the default), run:

```powershell
git switch release
```

The `master` branch will always point to the latest development version.
This branch has been tested and should _generally_ be safe to use, but
it will often have minor issues that have not been fixed yet. You should
use this branch if it contains a feature or fix you need that is not in
the `release` branch or if the `release` branch isn’t working for you
and you’re feeling adventurous. To switch to this branch, run the following:

```powershell
git switch master
```

The `dev` branch contains in-progress work, is often broken, and should
only be used if you were specifically asked to test it. To switch to
this branch, run the following:

```powershell
git switch dev
```

If something isn’t working but was previously, you can always switch to
a previous release by running:

```powershell
git switch --detach <tag>
```

where `<tag>` is the tag of the release you want to switch to. You can
[browse the list of releases on
GitHub](https://github.com/gucci-on-fleek/lockdown-browser/releases) in
case you’re unsure which tag to choose.

## Common Issues

### The _Browser_ updates itself, then it stops working

This tool does not support having the _Lockdown Browser_ update itself. Instead, whenever an update is available for the _Browser_, you should download a fresh installer from wherever you originally downloaded it. The URL should be similar in format to:

```text
https://download.respondus.com/lockdown/download7.php?id=XXXXXXXXX
```

### You get a “Terminal Services” error message

If the _Lockdown Browser_ fails to launch, you can open the shortcut on the VM’s desktop. If you are on an older version, you’ll need to instead open a PowerShell prompt inside the VM and run:

```powershell
cd C:\Users\WDAGUtilityAccount\Desktop\runtime_directory\
.\withdll.exe /d:GetSystemMetrics-Hook.dll "C:\Program Files (x86)\Respondus\LockDown Browser\LockDownBrowser.exe"
```

(OEM versions of the _Lockdown Browser_ **must** have a URL at the end; `ldb:dh%7BKS6poDqwsi1SHVGEJ+KMYaelPZ56lqcNzohRRiV1bzFj3Hjq8lehqEug88UjowG1mK1Q8h2Rg6j8kFZQX0FdyA==%7D` is a good default)

Of course, this is usually symptomatic of another issue, so please ensure you have followed all the earlier instructions.

### Build issues

If you have to build issues, please run `.\build.ps1 -Clean` to reset your workplace to a fresh start.

If you still have issues, run `.\build.ps1 -Logs` for logging into one file you can send us.

### Other issues

If you have made sure that you have followed all the instructions, please feel free to [open a new issue](https://github.com/gucci-on-fleek/lockdown-browser/issues/new/choose). Ensure you include any error messages and your _Lockdown Browser_ version.

## Technical Details (How does it work?)

This repo consists of simple tools cobbled together into a coherent package.

The _Lockdown Browser_ detects a few BIOS-related registry keys in `HKLM:\HARDWARE\DESCRIPTION`. Therefore, `sandbox_run.ps1` deletes these keys/values.

- When the _Lockdown Browser_ detects that `VmComputeAgent.exe` is running, it realizes it is in a VM and refuses to launch. This program is part of the _Windows Sandbox_, and cannot be stopped without crashing the VM.  However, when the _Browser_ checks all the running programs, it also opens and examines each image file. If `sandbox_run.ps1` deletes the image file, the _Lockdown Browser_ acts like the program isn’t even running.

The _Lockdown Browser_ calls `GetSystemMetrics(SM_REMOTESESSION)` to determine if it runs in an RDP session. Since this function is in `user32.dll`, there aren’t any trivial ways to fix this. However, [_Microsoft Detours_](https://github.com/microsoft/Detours) allows you to intercept and replace any function in any `.dll`. A small hook (`GetSystemMetrics-Hook.cpp`) is used with `Detours` to intercept the function call and return a false value.

Because this tool runs in the _Windows Sandbox_, no state is retained between sessions. Therefore, this tool provides a scripted installer for the _Lockdown Browser_. The _Lockdown Browser_’s installer is a little tricky to script, so the installation is a little hacky, but it works. And again, the _Sandbox_ is completely isolated from the rest of your system, so the _Lockdown Browser_ cannot cause any harm to your computer.

## Support

If you’re having any difficulties installing the prerequisites or have any other questions, please [start a new discussion](https://github.com/gucci-on-fleek/lockdown-browser/discussions/new?category=q-a), and we’ll be happy to help. If you’re experiencing any bugs while building the project or running the _Windows Sandbox_, please [open a new issue](https://github.com/gucci-on-fleek/lockdown-browser/issues/new?template=bug-report.yml). If you want to submit a patch, please [open a new pull request](https://github.com/gucci-on-fleek/lockdown-browser/compare).

I will also usually reply to emails, but I have a _very_ busy schedule, so it may take a while (many months) for me to respond, and I will often ask you to post an issue on GitHub. So, to reiterate, the best way to get support is to post [an issue](https://github.com/gucci-on-fleek/lockdown-browser/issues/new) or [a discussion](https://github.com/gucci-on-fleek/lockdown-browser/discussions/new) here on GitHub.

## License

All code is licensed under the [_Mozilla Public License_, version 2.0](https://www.mozilla.org/en-US/MPL/2.0/) or greater. The documentation is licensed under [CC-BY-SA, version 4.0](https://creativecommons.org/licenses/by-sa/4.0/legalcode) or greater, in addition to the MPL. The _Detours_ submodule has an MIT licence as detailed in `Detours/LICENSE.md`.

In addition to the formal licence terms, I would appreciate it if users do not distribute any binaries: I intend this project to be merely a proof-of-concept, and any binaries circulating on the internet diminish this status. Of course, you are well within your rights to ignore this request, but I would appreciate it if you would respect my wishes. Thanks!
