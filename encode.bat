@echo off
if "%~1"=="" (
    echo Drag and drop a text file onto this batch file to compress it
    pause
    exit /b 1
)

if not exist "%~1" (
    echo File not found: %~1
    pause
    exit /b 1
)

echo Compressing: %~1
powershell -ExecutionPolicy Bypass -File "%~dp0Compress.ps1" -InputFile "%~1"

if %errorlevel% equ 0 (
    echo.
    echo Compression completed successfully!
    echo Check the same folder for .compressed.*.txt files
) else (
    echo.
    echo Compression failed!
)

pause