/* Lockdown Browser in Windows Sandbox
 * https://github.com/gucci-on-fleek/lockdown-browser
 * SPDX-License-Identifier: MPL-2.0+
 * SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125
 */
#include <windows.h>
#include <winternl.h>
#include <stdio.h>

#define win32_checked(result)                                           \
    do                                                                  \
    {                                                                   \
        if (!(result))                                                  \
        {                                                               \
            printf("Error: %ld (line %d)\n", GetLastError(), __LINE__); \
            return result;                                              \
        }                                                               \
    } while (0)

#define nt_checked(result)                                     \
    do                                                         \
    {                                                          \
        if (!(result))                                         \
        {                                                      \
            printf("Error: %d (line %d)\n", result, __LINE__); \
            return result;                                     \
        }                                                      \
    } while (0)

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    const LPWSTR lpCmdLine = GetCommandLineW();

    int pNumArgs;
    const LPWSTR *argv = CommandLineToArgvW(lpCmdLine, &pNumArgs);
    const LPWSTR lpApplicationName = argv[0];

    const LPWSTR lpNewCmdLine = lpCmdLine + lstrlenW(lpApplicationName) + 1;

    STARTUPINFOW lpStartupInfo = {0};
    PROCESS_INFORMATION lpCreateProcessInformation;
    win32_checked(CreateProcessW(
        lpApplicationName,
        lpNewCmdLine,
        NULL,
        NULL,
        FALSE,
        CREATE_SUSPENDED,
        NULL,
        NULL,
        &lpStartupInfo,
        &lpCreateProcessInformation));

    PROCESS_BASIC_INFORMATION lpGetProcessInformation;
    nt_checked(NtQueryInformationProcess(
        lpCreateProcessInformation.hProcess,
        ProcessBasicInformation,
        &lpGetProcessInformation,
        sizeof(lpGetProcessInformation),
        NULL));

    PEB lpGetProcessEnvironmentBlock;
    win32_checked(ReadProcessMemory(
        lpCreateProcessInformation.hProcess,
        lpGetProcessInformation.PebBaseAddress,
        &lpGetProcessEnvironmentBlock,
        sizeof(lpGetProcessEnvironmentBlock),
        NULL));

    lpGetProcessEnvironmentBlock.SessionId = WTSGetActiveConsoleSessionId();

    win32_checked(WriteProcessMemory(
        lpCreateProcessInformation.hProcess,
        lpGetProcessInformation.PebBaseAddress,
        &lpGetProcessEnvironmentBlock,
        sizeof(lpGetProcessEnvironmentBlock),
        NULL));

    win32_checked(ResumeThread(lpCreateProcessInformation.hThread) == -1);

    return 0;
}
