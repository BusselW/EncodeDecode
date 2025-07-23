@echo off
if "%~1"=="" (
    echo Drag and drop base64 text files or folders onto this batch file
    pause
    exit /b 1
)

echo Decoding: %~1
powershell -ExecutionPolicy Bypass -File "%~dp0DecodeBase64.ps1" -InputPath "%~1"

if %errorlevel% equ 0 (
    echo.
    echo Decoding completed! Check output\text\ for .restored.txt files
) else (
    echo.
    echo Decoding failed!
)

pause