#include <windows.h>
#include <stdio.h>

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    (void)hInstance;
    (void)hPrevInstance;
    (void)lpCmdLine;
    (void)nCmdShow;

    const int metric = GetSystemMetrics(SM_REMOTESESSION);
    printf("SM_REMOTESESSION: %d\n", metric);
    return 0;
}
