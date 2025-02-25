/* Lockdown Browser in Windows Sandbox
 * https://github.com/gucci-on-fleek/lockdown-browser
 * SPDX-License-Identifier: MPL-2.0+
 * SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125
 */
#include <windows.h>
#include <winternl.h>
#include <stdio.h>

#define win32_checked(result)                                  \
    do                                                         \
    {                                                          \
        if (!(result))                                         \
        {                                                      \
            const DWORD error = GetLastError();                \
            printf("Error: %ld (line %d)\n", error, __LINE__); \
            print_error_message(error);                        \
            return result;                                     \
        }                                                      \
    } while (0)

#define nt_checked(result)                                     \
    do                                                         \
    {                                                          \
        if (result)                                            \
        {                                                      \
            printf("Error: %d (line %d)\n", result, __LINE__); \
            return result;                                     \
        }                                                      \
    } while (0)

// Based off of https://learn.microsoft.com/en-us/windows/win32/Debug/retrieving-the-last-error-code
static void print_error_message(DWORD error)
{
    LPVOID lpMsgBuf;

    FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER |
            FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        error,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPWSTR)&lpMsgBuf,
        0, NULL);

    printf("Message: %ls\n", lpMsgBuf);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR _lpCmdLine, int nCmdShow)
{
    (void)hPrevInstance;
    (void)_lpCmdLine;
    (void)nCmdShow;

    const LPWSTR lpCmdLine = GetCommandLineW();

    int pNumArgs;
    const LPWSTR *argv = CommandLineToArgvW(lpCmdLine, &pNumArgs);
    const LPWSTR lpThisApplicationName = argv[0];
    const LPWSTR lpTargetApplicationName = argv[1];
    const BOOL quoted = lpCmdLine[0] == L'"';

    const LPWSTR lpNewCmdLine = lpCmdLine + lstrlenW(lpThisApplicationName) + (quoted ? 2 : 0) + 1;

    STARTUPINFOW lpStartupInfo = {0};
    PROCESS_INFORMATION lpCreateProcessInformation;
    win32_checked(CreateProcessW(
        lpTargetApplicationName,
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

    win32_checked(ResumeThread(lpCreateProcessInformation.hThread) != -1);

    return 0;
}
