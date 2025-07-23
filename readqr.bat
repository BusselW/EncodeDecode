@echo off
if "%~1"=="" (
    echo Drag and drop QR images, text files, or folders onto this batch file
    pause
    exit /b 1
)

if not exist "%~1" (
    echo File not found: %~1
    pause
    exit /b 1
)

echo Processing: %~1
powershell -ExecutionPolicy Bypass -File "%~dp0ReadQR.ps1" -InputPath "%~1"

if %errorlevel% equ 0 (
    echo.
    echo QR reading completed successfully!
    echo Check output\text\ for decoded .txt file
) else (
    echo.
    echo QR reading failed!
)

pause