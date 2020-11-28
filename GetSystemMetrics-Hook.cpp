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
    (void)hinstDLL; // Discard the unused parmeters
    (void)lpvReserved;

    if (DetourIsHelperProcess())
    {
        return TRUE;
    }

    if (fdwReason == DLL_PROCESS_ATTACH)
    {
        DetourRestoreAfterWith();

        DetourTransactionBegin();
        DetourUpdateThread(GetCurrentThread());
        DetourAttach(&(PVOID &)Original_GetSystemMetrics, Hooked_GetSystemMetrics);
        DetourTransactionCommit();
    }
    else if (fdwReason == DLL_PROCESS_DETACH)
    {
        DetourTransactionBegin();
        DetourUpdateThread(GetCurrentThread());
        DetourDetach(&(PVOID &)Original_GetSystemMetrics, Hooked_GetSystemMetrics);
        DetourTransactionCommit();
    }
    return TRUE;
}
