/* lockdown-browser sandbox hook — IAT patch edition
 * Replaces the Detours-based GetSystemMetrics hook with an Import Address
 * Table rewrite.  No Detours dependency, no MOV EDI,EDI trampoline, no
 * recognisable inline-hook signature on the target function prologue.
 *
 * SPDX-License-Identifier: MPL-2.0+
 */

#include <windows.h>

/* ── original function pointers ────────────────────────────────────── */

static decltype(&GetSystemMetrics) g_RealGetSystemMetrics = nullptr;
static decltype(&GetProcAddress)   g_RealGetProcAddress   = nullptr;

/* ── hook implementations ──────────────────────────────────────────── */

static int WINAPI HookGetSystemMetrics(int nIndex)
{
    if (nIndex == SM_REMOTESESSION)
        return 0;
    return g_RealGetSystemMetrics(nIndex);
}

static FARPROC WINAPI HookGetProcAddress(HMODULE hModule, LPCSTR lpProcName)
{
    FARPROC real = g_RealGetProcAddress(hModule, lpProcName);
    if (lpProcName && !IS_INTRESOURCE(lpProcName) &&
        strcmp(lpProcName, "GetSystemMetrics") == 0)
        return (FARPROC)HookGetSystemMetrics;
    return real;
}

/* ── IAT patching engine ───────────────────────────────────────────── */

static BOOL PatchIATEntry(HMODULE hModule, const char *dllName,
                          const char *funcName, void *hookFunc,
                          void **ppOrigFunc)
{
    BYTE *base = (BYTE *)hModule;

    PIMAGE_DOS_HEADER dos = (PIMAGE_DOS_HEADER)base;
    if (dos->e_magic != IMAGE_DOS_SIGNATURE)
        return FALSE;

    PIMAGE_NT_HEADERS nt = (PIMAGE_NT_HEADERS)(base + dos->e_lfanew);
    if (nt->Signature != IMAGE_NT_SIGNATURE)
        return FALSE;

    DWORD impRVA =
        nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT]
            .VirtualAddress;
    if (!impRVA)
        return FALSE;

    for (PIMAGE_IMPORT_DESCRIPTOR imp =
             (PIMAGE_IMPORT_DESCRIPTOR)(base + impRVA);
         imp->Name; ++imp) {

        if (_stricmp((const char *)(base + imp->Name), dllName) != 0)
            continue;

        PIMAGE_THUNK_DATA hint =
            (PIMAGE_THUNK_DATA)(base + imp->OriginalFirstThunk);
        PIMAGE_THUNK_DATA iat =
            (PIMAGE_THUNK_DATA)(base + imp->FirstThunk);

        for (; hint->u1.AddressOfData; ++hint, ++iat) {
            if (IMAGE_SNAP_BY_ORDINAL(hint->u1.Ordinal))
                continue;

            PIMAGE_IMPORT_BY_NAME name =
                (PIMAGE_IMPORT_BY_NAME)(base + hint->u1.AddressOfData);

            if (strcmp(name->Name, funcName) != 0)
                continue;

            DWORD oldProt;
            VirtualProtect(&iat->u1.Function, sizeof(ULONG_PTR),
                           PAGE_READWRITE, &oldProt);

            if (ppOrigFunc)
                *ppOrigFunc = (void *)iat->u1.Function;

            iat->u1.Function = (ULONG_PTR)hookFunc;

            VirtualProtect(&iat->u1.Function, sizeof(ULONG_PTR),
                           oldProt, &oldProt);
            return TRUE;
        }
    }
    return FALSE;
}

/* ── enumerate-and-patch helper ────────────────────────────────────── */

static void PatchAllModules(const char *dllName, const char *funcName,
                            void *hookFunc)
{
    HMODULE snap[512];
    DWORD needed = 0;

    /* Kernel32 is always loaded; grab EnumProcessModules dynamically so
       we don't add a psapi.lib link-time dependency. */
    typedef BOOL(WINAPI * EnumProc)(HANDLE, HMODULE *, DWORD, LPDWORD);
    HMODULE hPsapi = LoadLibraryW(L"psapi.dll");
    if (!hPsapi)
        return;

    auto pEnum =
        (EnumProc)g_RealGetProcAddress(hPsapi, "EnumProcessModules");
    if (!pEnum)
        return;

    if (!pEnum(GetCurrentProcess(), snap, sizeof(snap), &needed))
        return;

    DWORD count = needed / sizeof(HMODULE);
    for (DWORD i = 0; i < count; ++i)
        PatchIATEntry(snap[i], dllName, funcName, hookFunc, nullptr);
}

/* ── entry point ───────────────────────────────────────────────────── */

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    (void)hinstDLL;
    (void)lpvReserved;

    if (fdwReason != DLL_PROCESS_ATTACH)
        return TRUE;

    DisableThreadLibraryCalls(hinstDLL);

    /* Resolve originals BEFORE any patching. */
    HMODULE user32   = GetModuleHandleW(L"user32.dll");
    HMODULE kernel32 = GetModuleHandleW(L"kernel32.dll");
    if (!user32 || !kernel32)
        return TRUE;

    g_RealGetSystemMetrics =
        (decltype(&GetSystemMetrics))GetProcAddress(user32, "GetSystemMetrics");
    g_RealGetProcAddress =
        (decltype(&GetProcAddress))GetProcAddress(kernel32, "GetProcAddress");

    if (!g_RealGetSystemMetrics || !g_RealGetProcAddress)
        return TRUE;

    /* Patch every loaded module's IAT so both static and already-resolved
       imports go through the hook. */
    PatchAllModules("user32.dll", "GetSystemMetrics",
                    (void *)HookGetSystemMetrics);

    /* Patch GetProcAddress in the main module to catch dynamic lookups. */
    HMODULE mainMod = GetModuleHandleW(NULL);
    PatchIATEntry(mainMod, "kernel32.dll", "GetProcAddress",
                  (void *)HookGetProcAddress, nullptr);

    return TRUE;
}
