@echo off
if "%~1"=="" (
    echo Drag and drop a .compressed.*.txt file or folder containing chunks onto this batch file
    pause
    exit /b 1
)

if not exist "%~1" (
    echo Path not found: %~1
    pause
    exit /b 1
)

echo Decompressing: %~1
powershell -ExecutionPolicy Bypass -File "%~dp0Decompress.ps1" -InputPath "%~1"

if %errorlevel% equ 0 (
    echo.
    echo Decompression completed successfully!
    echo Check output\text\ for .restored.txt file
) else (
    echo.
    echo Decompression failed!
)

pause