/* Lockdown Browser in Windows Sandbox
 * https://github.com/gucci-on-fleek/lockdown-browser
 * SPDX-License-Identifier: MPL-2.0+
 * SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125
 */
#include <windows.h>
#include <detours.h>

static int(WINAPI *Original_GetSystemMetrics)(int nIndex) = GetSystemMetrics; // Save the original function

int WINAPI Hooked_GetSystemMetrics(int nIndex)
{
    if (nIndex == SM_REMOTESESSION)
    {
        return 0; // Make it look like this is a local session
    }
    else
    {
        return Original_GetSystemMetrics(nIndex); // Don't override the other SystemMetrics requests
    }
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    /* This is all pretty much copied from the Detours docs. I can't really pretend to understand most of it */
    // I also can't pretend I understand this, but hey error checking would be nice - Voidless
    (void)hinstDLL; // Discard the unused parameters
    (void)lpvReserved;

    if (DetourIsHelperProcess())
    {
        return TRUE;
    }

    if (fdwReason == DLL_PROCESS_ATTACH)
    {
        DetourRestoreAfterWith();

        DetourTransactionBegin();
        if (DetourUpdateThread(GetCurrentThread()) != NO_ERROR)
        {
            DetourTransactionAbort();
            return FALSE;
        }
        if (DetourAttach(&(PVOID &)Original_GetSystemMetrics, Hooked_GetSystemMetrics) != NO_ERROR)
        {
            DetourTransactionAbort();
            return FALSE;
        }
        if (DetourTransactionCommit() != NO_ERROR)
        {
            DetourTransactionAbort();
            return FALSE;
        }
    }
    else if (fdwReason == DLL_PROCESS_DETACH)
    {
        DetourTransactionBegin();
        if (DetourUpdateThread(GetCurrentThread()) != NO_ERROR)
        {
            DetourTransactionAbort();
            return FALSE;
        }
        if (DetourDetach(&(PVOID &)Original_GetSystemMetrics, Hooked_GetSystemMetrics) != NO_ERROR)
        {
            DetourTransactionAbort();
            return FALSE;
        }
        if (DetourTransactionCommit() != NO_ERROR)
        {
            DetourTransactionAbort();
            return FALSE;
        }
    }
    return TRUE;
}