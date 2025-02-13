/* Lockdown Browser in Windows Sandbox
 * https://github.com/gucci-on-fleek/lockdown-browser
 * SPDX-License-Identifier: MPL-2.0+
 * SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125
 */
#include <windows.h>
#include <detours.h>
#include <iostream>

// Save original function for GetSystemMetrics hook
static int(WINAPI *Original_GetSystemMetrics)(int nIndex) = GetSystemMetrics;

// Save original function pointers for TerminateProcess and ExitProcess
static BOOL(WINAPI *Original_TerminateProcess)(HANDLE hProcess, UINT uExitCode) = TerminateProcess;
static VOID(WINAPI *Original_ExitProcess)(UINT uExitCode) = ExitProcess;

// Hooked GetSystemMetrics function using Detours
int WINAPI Hooked_GetSystemMetrics(int nIndex)
{
    if (nIndex == SM_REMOTESESSION)
    {
        return 0; // Simulate a local session
    }
    else
    {
        return Original_GetSystemMetrics(nIndex); // Don't override other system metrics
    }
}

// Custom hook functions for TerminateProcess and ExitProcess
BOOL WINAPI MyTerminateProcess(HANDLE hProcess, UINT uExitCode)
{
    return TRUE; // Simulate success without terminating
}

VOID WINAPI MyExitProcess(UINT uExitCode)
{
    // Do nothing
}

// Install all detour hooks
void InstallDetourHooks()
{
    DetourTransactionBegin();
    DetourUpdateThread(GetCurrentThread());

    // Hook GetSystemMetrics
    if (DetourAttach(reinterpret_cast<PVOID *>(&Original_GetSystemMetrics), Hooked_GetSystemMetrics) != NO_ERROR)
    {
        DetourTransactionAbort();
        return;
    }
    // Hook TerminateProcess
    if (DetourAttach(reinterpret_cast<PVOID *>(&Original_TerminateProcess), MyTerminateProcess) != NO_ERROR)
    {
        DetourTransactionAbort();
        return;
    }
    // Hook ExitProcess
    if (DetourAttach(reinterpret_cast<PVOID *>(&Original_ExitProcess), MyExitProcess) != NO_ERROR)
    {
        DetourTransactionAbort();
        return;
    }

    if (DetourTransactionCommit() != NO_ERROR)
    {
        DetourTransactionAbort();
    }
}

// Uninstall all detour hooks
void UninstallDetourHooks()
{
    DetourTransactionBegin();
    DetourUpdateThread(GetCurrentThread());

    // Unhook GetSystemMetrics
    if (DetourDetach(reinterpret_cast<PVOID *>(&Original_GetSystemMetrics), Hooked_GetSystemMetrics) != NO_ERROR)
    {
        DetourTransactionAbort();
        return;
    }
    // Unhook TerminateProcess
    if (DetourDetach(reinterpret_cast<PVOID *>(&Original_TerminateProcess), MyTerminateProcess) != NO_ERROR)
    {
        DetourTransactionAbort();
        return;
    }
    // Unhook ExitProcess
    if (DetourDetach(reinterpret_cast<PVOID *>(&Original_ExitProcess), MyExitProcess) != NO_ERROR)
    {
        DetourTransactionAbort();
        return;
    }

    if (DetourTransactionCommit() != NO_ERROR)
    {
        DetourTransactionAbort();
    }
}

// DllMain using Detours for all hooks
BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
    if (DetourIsHelperProcess())
    {
        return TRUE;
    }

    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
        DisableThreadLibraryCalls(hModule);
        // Install detour hooks for GetSystemMetrics, TerminateProcess and ExitProcess
        InstallDetourHooks();
        break;
    case DLL_PROCESS_DETACH:
        // Uninstall detour hooks
        UninstallDetourHooks();
        break;
    }
    return TRUE;
}