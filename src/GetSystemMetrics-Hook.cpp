/* Lockdown Browser in Windows Sandbox
 * https://github.com/gucci-on-fleek/lockdown-browser
 * SPDX-License-Identifier: MPL-2.0+
 * SPDX-FileCopyrightText: 2020-2025 gucci-on-fleek and Voidless7125
 * This C++ code was provided by: Totsukawaii, Linked here. https://github.com/Totsukawaii/UndownUnlock
 */
#define _CRT_SECURE_NO_WARNINGS
#include <windows.h>
#include <detours.h>
#include <psapi.h>
#include <iostream>
#include <tlhelp32.h>
#include <cstdlib>
#include <tchar.h>
#include <thread>
#include <vector>
#include <string>
#include <fstream>
#include <GL/gl.h>
#include <wincodec.h>                     // For WIC
#pragma comment(lib, "windowscodecs.lib") // Link against the WIC library

bool isFocusInstalled = false; // Global flag

// create global hWND variable
HWND focusHWND = NULL;
HWND bringWindowToTopHWND = NULL;
HWND setWindowFocusHWND = NULL;
HWND setWindowFocushWndInsertAfter = NULL;
int setWindowFocusX = 0;
int setWindowFocusY = 0;
int setWindowFocuscx = 0;
int setWindowFocuscy = 0;
UINT setWindowFocusuFlags = 0;

BYTE originalBytesForGetForeground[5] = {0};
BYTE originalBytesForShowWindow[5] = {0};
BYTE originalBytesForSetWindowPos[5] = {0};
BYTE orginalBytesForSetFocus[5] = {0};
BYTE originalBytesForEmptyClipboard[5] = {0};
BYTE originalBytesForSetClipboardData[5] = {0};
BYTE originalBytesForTerminateProcess[5] = {0};
BYTE originalBytesForExitProcess[5] = {0};

// My custom functions
HWND WINAPI MyGetForegroundWindow();
BOOL WINAPI MyShowWindow(HWND hWnd);
BOOL WINAPI MySetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags);
HWND WINAPI MySetFocus(HWND hWnd);
HWND WINAPI MyGetWindow(HWND hWnd, UINT uCmd);
int WINAPI MyGetWindowTextW(HWND hWnd, LPWSTR lpString, int nMaxCount);
BOOL WINAPI MyK32EnumProcesses(DWORD *pProcessIds, DWORD cb, DWORD *pBytesReturned);
HANDLE WINAPI MyOpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId);
BOOL WINAPI MyTerminateProcess(HANDLE hProcess, UINT uExitCode);
VOID WINAPI MyExitProcess(UINT uExitCode);
BOOL WINAPI MyEmptyClipboard();
HANDLE WINAPI MySetClipboardData(UINT uFormat, HANDLE hMem);

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
// Implement MySetClipboardData which does nothing
HANDLE WINAPI MySetClipboardData(UINT uFormat, HANDLE hMem)
{
    // This custom function does nothing
    std::cout << "SetClipboardData hook called, but not setting clipboard data." << std::endl;
    return NULL; // Indicate failure or that the data was not set
}

BOOL WINAPI MyEmptyClipboard()
{
    // This custom function pretends to clear the clipboard but does nothing
    std::cout << "EmptyClipboard hook called, but not clearing the clipboard." << std::endl;
    return TRUE; // Pretend success
}

HANDLE WINAPI MyOpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId)
{
    std::cout << "OpenProcess hook called, but not opening process." << std::endl;
    return NULL;
}

BOOL WINAPI MyTerminateProcess(HANDLE hProcess, UINT uExitCode)
{
    std::cout << "TerminateProcess hook called, but not terminating process." << std::endl;
    return TRUE; // Simulate success
}

VOID WINAPI MyExitProcess(UINT uExitCode)
{
    std::cout << "ExitProcess hook called, but not exiting process." << std::endl;
}

BOOL WINAPI MyK32EnumProcesses(DWORD *pProcessIds, DWORD cb, DWORD *pBytesReturned)
{
    // This custom function behaves as if no processes are running
    std::cout << "K32EnumProcesses hook called, but pretending no processes exist." << std::endl;
    if (pBytesReturned != NULL)
    {
        *pBytesReturned = 0; // Indicate no processes were written to the buffer
    }
    return TRUE; // Indicate the function succeeded
}

int WINAPI MyGetWindowTextW(HWND hWnd, LPWSTR lpString, int nMaxCount)
{
    // This custom function behaves as if no window title is retrieved
    std::cout << "GetWindowTextW hook called, but not returning actual window text." << std::endl;
    if (nMaxCount > 0)
    {
        lpString[0] = L'\0'; // Return an empty string
    }
    return 0; // Indicate that no characters were copied to the buffer
}

BOOL WINAPI MySetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags)
{
    setWindowFocusHWND = hWnd;
    setWindowFocushWndInsertAfter = hWndInsertAfter;
    setWindowFocusX = X;
    setWindowFocusY = Y;
    setWindowFocuscx = cx;
    setWindowFocuscy = cy;
    setWindowFocusuFlags = uFlags;
    // This custom function does nothing
    std::cout << "SetWindowPos hook called, but not changing window position." << std::endl;
    return TRUE; // Pretend success
}

BOOL WINAPI MyShowWindow(HWND hWnd)
{
    bringWindowToTopHWND = hWnd;
    // This custom function does nothing
    std::cout << "ShowWindow hook called, but not bringing window to top." << std::endl;
    return TRUE; // Pretend success
}

HWND WINAPI MyGetWindow(HWND hWnd, UINT uCmd)
{
    // This custom function behaves as if there are no windows to return
    std::cout << "GetWindow hook called, but pretending no related window." << std::endl;
    return NULL; // Indicate no window found
}

void InstallHook()
{
    std::cout << "Installing hooks..." << std::endl;
    DWORD oldProtect;

    // Hook EmptyClipboard
    HMODULE hUser32 = GetModuleHandleA("user32.dll");
    if (hUser32)
    {
        void *targetEmptyClipboard = GetProcAddress(hUser32, "EmptyClipboard");
        if (targetEmptyClipboard)
        {
            DWORD jumpEmptyClipboard = (DWORD)MyEmptyClipboard - (DWORD)targetEmptyClipboard - 5;
            memcpy(originalBytesForEmptyClipboard, targetEmptyClipboard, sizeof(originalBytesForEmptyClipboard));
            if (VirtualProtect(targetEmptyClipboard, sizeof(originalBytesForEmptyClipboard), PAGE_EXECUTE_READWRITE, &oldProtect))
            {
                *((BYTE *)targetEmptyClipboard) = 0xE9;
                *((DWORD *)((BYTE *)targetEmptyClipboard + 1)) = jumpEmptyClipboard;
                VirtualProtect(targetEmptyClipboard, sizeof(originalBytesForEmptyClipboard), oldProtect, &oldProtect);
            }
        }
    }

    // Hook GetForegroundWindow
    if (hUser32)
    {
        void *targetGetForegroundWindow = GetProcAddress(hUser32, "GetForegroundWindow");
        if (targetGetForegroundWindow)
        {
            DWORD jumpGetForeground = (DWORD)MyGetForegroundWindow - (DWORD)targetGetForegroundWindow - 5;
            memcpy(originalBytesForGetForeground, targetGetForegroundWindow, sizeof(originalBytesForGetForeground));
            if (VirtualProtect(targetGetForegroundWindow, sizeof(originalBytesForGetForeground), PAGE_EXECUTE_READWRITE, &oldProtect))
            {
                *((BYTE *)targetGetForegroundWindow) = 0xE9;
                *((DWORD *)((BYTE *)targetGetForegroundWindow + 1)) = jumpGetForeground;
                VirtualProtect(targetGetForegroundWindow, sizeof(originalBytesForGetForeground), oldProtect, &oldProtect);
            }
        }
    }

    // Hook TerminateProcess
    HMODULE hKernel32 = GetModuleHandleA("kernel32.dll");
    if (hKernel32)
    {
        void *targetTerminateProcess = GetProcAddress(hKernel32, "TerminateProcess");
        if (targetTerminateProcess)
        {
            DWORD jumpTerminateProcess = ((DWORD)MyTerminateProcess - (DWORD)targetTerminateProcess - 5);
            memcpy(originalBytesForTerminateProcess, targetTerminateProcess, sizeof(originalBytesForTerminateProcess));
            if (VirtualProtect(targetTerminateProcess, sizeof(originalBytesForTerminateProcess), PAGE_EXECUTE_READWRITE, &oldProtect))
            {
                *((BYTE *)targetTerminateProcess) = 0xE9;
                *((DWORD *)((BYTE *)targetTerminateProcess + 1)) = jumpTerminateProcess;
                VirtualProtect(targetTerminateProcess, sizeof(originalBytesForTerminateProcess), oldProtect, &oldProtect);
            }
        }
    }

    // Hook ExitProcess
    if (hKernel32)
    {
        void *targetExitProcess = GetProcAddress(hKernel32, "ExitProcess");
        if (targetExitProcess)
        {
            DWORD jumpExitProcess = ((DWORD)MyExitProcess - (DWORD)targetExitProcess - 5);
            memcpy(originalBytesForExitProcess, targetExitProcess, sizeof(originalBytesForExitProcess));
            if (VirtualProtect(targetExitProcess, sizeof(originalBytesForExitProcess), PAGE_EXECUTE_READWRITE, &oldProtect))
            {
                *((BYTE *)targetExitProcess) = 0xE9;
                *((DWORD *)((BYTE *)targetExitProcess + 1)) = jumpExitProcess;
                VirtualProtect(targetExitProcess, sizeof(originalBytesForExitProcess), oldProtect, &oldProtect);
            }
        }
    }

    // create a message box to show the dll is loaded
    MessageBoxA(NULL, "Injected :)", "UndownUnlock", MB_OK);
}

void InstallFocus()
{
    if (isFocusInstalled)
    {
        return;
    }
    isFocusInstalled = true;
    std::cout << "Installing focus..." << std::endl;
    DWORD oldProtect;

    // Hook BringWindowToTop
    HMODULE hUser32 = GetModuleHandleA("user32.dll");
    if (hUser32)
    {
        void *targetShowWindow = GetProcAddress(hUser32, "BringWindowToTop");
        if (targetShowWindow)
        {
            DWORD jumpBringWindowToTop = (DWORD)MyShowWindow - (DWORD)targetShowWindow - 5;
            memcpy(originalBytesForShowWindow, targetShowWindow, sizeof(originalBytesForShowWindow));
            if (VirtualProtect(targetShowWindow, sizeof(originalBytesForShowWindow), PAGE_EXECUTE_READWRITE, &oldProtect))
            {
                *((BYTE *)targetShowWindow) = 0xE9;
                *((DWORD *)((BYTE *)targetShowWindow + 1)) = jumpBringWindowToTop;
                VirtualProtect(targetShowWindow, sizeof(originalBytesForShowWindow), oldProtect, &oldProtect);
            }
        }
    }

    // Hook SetWindowPos
    if (hUser32)
    {
        void *targetSetWindowPos = GetProcAddress(hUser32, "SetWindowPos");
        if (targetSetWindowPos)
        {
            DWORD jumpSetWindowPos = (DWORD)MySetWindowPos - (DWORD)targetSetWindowPos - 5;
            memcpy(originalBytesForSetWindowPos, targetSetWindowPos, sizeof(originalBytesForSetWindowPos));
            if (VirtualProtect(targetSetWindowPos, sizeof(originalBytesForSetWindowPos), PAGE_EXECUTE_READWRITE, &oldProtect))
            {
                *((BYTE *)targetSetWindowPos) = 0xE9;
                *((DWORD *)((BYTE *)targetSetWindowPos + 1)) = jumpSetWindowPos;
                VirtualProtect(targetSetWindowPos, sizeof(originalBytesForSetWindowPos), oldProtect, &oldProtect);
            }
        }
    }

    // Hook SetFocus
    if (hUser32)
    {
        void *targetSetFocus = GetProcAddress(hUser32, "SetFocus");
        if (targetSetFocus)
        {
            DWORD jumpSetFocus = (DWORD)MySetFocus - (DWORD)targetSetFocus - 5;
            memcpy(orginalBytesForSetFocus, targetSetFocus, sizeof(orginalBytesForSetFocus));
            if (VirtualProtect(targetSetFocus, sizeof(orginalBytesForSetFocus), PAGE_EXECUTE_READWRITE, &oldProtect))
            {
                *((BYTE *)targetSetFocus) = 0xE9;
                *((DWORD *)((BYTE *)targetSetFocus + 1)) = jumpSetFocus;
                VirtualProtect(targetSetFocus, sizeof(orginalBytesForSetFocus), oldProtect, &oldProtect);
            }
        }
    }
}

void UninstallFocus()
{
    if (!isFocusInstalled)
    {
        return;
    }
    isFocusInstalled = false;
    std::cout << "Uninstalling focus..." << std::endl;
    DWORD oldProtect;

    // Unhook BringWindowToTop
    HMODULE hUser32 = GetModuleHandleA("user32.dll");
    if (hUser32)
    {
        void *targetShowWindow = GetProcAddress(hUser32, "BringWindowToTop");
        if (targetShowWindow)
        {
            if (VirtualProtect(targetShowWindow, sizeof(originalBytesForShowWindow), PAGE_EXECUTE_READWRITE, &oldProtect))
            {
                memcpy(targetShowWindow, originalBytesForShowWindow, sizeof(originalBytesForShowWindow));
                VirtualProtect(targetShowWindow, sizeof(originalBytesForShowWindow), oldProtect, &oldProtect);
            }
        }
    }

    // Unhook SetWindowPos
    if (hUser32)
    {
        void *targetSetWindowPos = GetProcAddress(hUser32, "SetWindowPos");
        if (targetSetWindowPos)
        {
            if (VirtualProtect(targetSetWindowPos, sizeof(originalBytesForSetWindowPos), PAGE_EXECUTE_READWRITE, &oldProtect))
            {
                memcpy(targetSetWindowPos, originalBytesForSetWindowPos, sizeof(originalBytesForSetWindowPos));
                VirtualProtect(targetSetWindowPos, sizeof(originalBytesForSetWindowPos), oldProtect, &oldProtect);
            }
        }
    }

    // Unhook SetFocus
    if (hUser32)
    {
        void *targetSetFocus = GetProcAddress(hUser32, "SetFocus");
        if (targetSetFocus)
        {
            if (VirtualProtect(targetSetFocus, sizeof(orginalBytesForSetFocus), PAGE_EXECUTE_READWRITE, &oldProtect))
            {
                memcpy(targetSetFocus, orginalBytesForSetFocus, sizeof(orginalBytesForSetFocus));
                VirtualProtect(targetSetFocus, sizeof(orginalBytesForSetFocus), oldProtect, &oldProtect);
            }
        }
    }
}

void UninstallHook()
{
    DWORD oldProtect;

    // Unhook SetClipboardData
    HMODULE hUser32 = GetModuleHandleA("user32.dll");
    if (hUser32)
    {
        void *targetSetClipboardData = GetProcAddress(hUser32, "SetClipboardData");
        if (targetSetClipboardData)
        {
            if (VirtualProtect(targetSetClipboardData, sizeof(originalBytesForSetClipboardData), PAGE_EXECUTE_READWRITE, &oldProtect))
            {
                memcpy(targetSetClipboardData, originalBytesForSetClipboardData, sizeof(originalBytesForSetClipboardData));
                VirtualProtect(targetSetClipboardData, sizeof(originalBytesForSetClipboardData), oldProtect, &oldProtect);
            }
        }
    }

    // Unhook EmptyClipboard
    if (hUser32)
    {
        void *targetEmptyClipboard = GetProcAddress(hUser32, "EmptyClipboard");
        if (targetEmptyClipboard)
        {
            if (VirtualProtect(targetEmptyClipboard, sizeof(originalBytesForEmptyClipboard), PAGE_EXECUTE_READWRITE, &oldProtect))
            {
                memcpy(targetEmptyClipboard, originalBytesForEmptyClipboard, sizeof(originalBytesForEmptyClipboard));
                VirtualProtect(targetEmptyClipboard, sizeof(originalBytesForEmptyClipboard), oldProtect, &oldProtect);
            }
        }
    }

    // Unhook GetForegroundWindow
    if (hUser32)
    {
        void *targetGetForegroundWindow = GetProcAddress(hUser32, "GetForegroundWindow");
        if (targetGetForegroundWindow)
        {
            if (VirtualProtect(targetGetForegroundWindow, sizeof(originalBytesForGetForeground), PAGE_EXECUTE_READWRITE, &oldProtect))
            {
                memcpy(targetGetForegroundWindow, originalBytesForGetForeground, sizeof(originalBytesForGetForeground));
                VirtualProtect(targetGetForegroundWindow, sizeof(originalBytesForGetForeground), oldProtect, &oldProtect);
            }
        }
    }
}

// Helper function to determine if the given window is the main window of the current process
BOOL IsMainWindow(HWND handle)
{
    return GetWindow(handle, GW_OWNER) == (HWND)0 && IsWindowVisible(handle);
}

// Callback function for EnumWindows
BOOL CALLBACK EnumWindowsCallback(HWND handle, LPARAM lParam)
{
    DWORD processID = 0;
    GetWindowThreadProcessId(handle, &processID);
    if (GetCurrentProcessId() == processID && IsMainWindow(handle))
    {
        // Stop enumeration if a main window is found, and return its handle
        *reinterpret_cast<HWND *>(lParam) = handle;
        return FALSE;
    }
    return TRUE;
}

// Function to find the main window of the current process
HWND FindMainWindow()
{
    HWND mainWindow = NULL;
    EnumWindows(EnumWindowsCallback, reinterpret_cast<LPARAM>(&mainWindow));
    return mainWindow;
}

// Your hook function implementation
HWND WINAPI MyGetForegroundWindow()
{
    HWND hWnd = FindMainWindow();
    if (hWnd != NULL)
    {
        std::cout << "Returning the main window of the current application." << std::endl;
        return hWnd;
    }
    std::cout << "Main window not found, returning NULL." << std::endl;
    return NULL;
}

HWND WINAPI MySetFocus(HWND _hWnd)
{
    focusHWND = _hWnd;
    HWND hWnd = FindMainWindow(); // Find the main window of the current process
    if (hWnd != NULL)
    {
        std::cout << "Returning the main window of the current application due to '[' key press." << std::endl;
        return hWnd; // Return the main window handle if found
    }
    else
    {
        std::cout << "Main window not found, returning NULL." << std::endl;
        return NULL; // If main window is not found, return NULL
    }
}

// Keyboard hook handle
HHOOK hKeyboardHook;

// Keyboard hook callback
LRESULT CALLBACK KeyboardProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    if (nCode == HC_ACTION)
    {
        PKBDLLHOOKSTRUCT p = (PKBDLLHOOKSTRUCT)lParam;
        if (wParam == WM_KEYDOWN)
        {
            switch (p->vkCode)
            {
                // VK_UP is the virtual key code for the Up arrow key
            case VK_UP:
                // CaptureOpenGLScreen();
                InstallFocus();
                std::cout << "Up arrow key pressed, installing focus hook." << std::endl;
                break;
                // VK_DOWN is the virtual key code for the Down arrow key
            case VK_DOWN:
                UninstallFocus();
                // call the set focus with the focusHWND
                if (focusHWND != NULL)
                {
                    SetFocus(focusHWND);
                }
                if (bringWindowToTopHWND != NULL)
                {
                    BringWindowToTop(bringWindowToTopHWND);
                }
                if (setWindowFocusHWND != NULL)
                {
                    SetWindowPos(setWindowFocusHWND, setWindowFocushWndInsertAfter, setWindowFocusX, setWindowFocusY, setWindowFocuscx, setWindowFocuscy, setWindowFocusuFlags);
                }
                std::cout << "Down arrow key pressed, uninstalling focus hook." << std::endl;
                break;
            }
        }
    }
    return CallNextHookEx(hKeyboardHook, nCode, wParam, lParam);
}

// Place this in a suitable location in your existing code.
void SetupKeyboardHook()
{
    hKeyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, KeyboardProc, nullptr, 0);
    MSG msg;
    while (GetMessage(&msg, nullptr, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}

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
        // Detours hook initialization
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
        // Install additional hooks
        InstallHook();
        // Start keyboard hook in a new thread
        std::thread([]()
                    { SetupKeyboardHook(); })
            .detach();
        break;
    case DLL_PROCESS_DETACH:
        // Detours unhook
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
        // Uninstall additional hooks
        UninstallHook();
        if (hKeyboardHook != nullptr)
        {
            UnhookWindowsHookEx(hKeyboardHook);
        }
        break;
    }
    return TRUE;
}