/* Lockdown Browser in Windows Sandbox
 * https://github.com/gucci-on-fleek/lockdown-browser
 * SPDX-License-Identifier: MPL-2.0+
 * SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125
 */
#include <windows.h>
#include "detours.h"

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
BOOL WINAPI Hooked_TerminateProcess(HANDLE hProcess, UINT uExitCode)
{
    return TRUE; // Simulate success without terminating
}

VOID WINAPI MyExitProcess(UINT uExitCode)
{
    // Do nothing
}

// Install all detour hooks
static void InstallDetourHooks()
{
    DetourTransactionBegin();
    DetourUpdateThread(GetCurrentThread());

    struct HookPair
    {
        PVOID *ppOriginal;
        PVOID pHook;
    };

    HookPair hooks[] = {
        {reinterpret_cast<PVOID *>(&Original_GetSystemMetrics), reinterpret_cast<PVOID>(Hooked_GetSystemMetrics)},
        {reinterpret_cast<PVOID *>(&Original_TerminateProcess), reinterpret_cast<PVOID>(Hooked_TerminateProcess)},
        {reinterpret_cast<PVOID *>(&Original_ExitProcess), reinterpret_cast<PVOID>(MyExitProcess)}};

    for (const auto &hook : hooks)
    {
        if (DetourAttach(hook.ppOriginal, hook.pHook) != NO_ERROR)
        {
            DetourTransactionAbort();
            return;
        }
    }

    if (DetourTransactionCommit() != NO_ERROR)
    {
        DetourTransactionAbort();
    }
}

static void UninstallDetourHooks()
{
    DetourTransactionBegin();
    DetourUpdateThread(GetCurrentThread());

    struct HookPair
    {
        PVOID *ppOriginal;
        PVOID pHook;
    };

    HookPair hooks[] = {
        {reinterpret_cast<PVOID *>(&Original_GetSystemMetrics), reinterpret_cast<PVOID>(Hooked_GetSystemMetrics)},
        {reinterpret_cast<PVOID *>(&Original_TerminateProcess), reinterpret_cast<PVOID>(Hooked_TerminateProcess)},
        {reinterpret_cast<PVOID *>(&Original_ExitProcess), reinterpret_cast<PVOID>(MyExitProcess)}};

    for (auto &hook : hooks)
    {
        if (DetourDetach(hook.ppOriginal, hook.pHook) != NO_ERROR)
        {
            DetourTransactionAbort();
            return;
        }
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