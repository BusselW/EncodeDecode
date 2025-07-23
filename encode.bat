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
    echo Generating QR codes...
    powershell -ExecutionPolicy Bypass -File "%~dp0GenerateQR.ps1" -InputPath "%~dp0output\text"
    
    if %errorlevel% equ 0 (
        echo.
        echo QR codes generated successfully!
        echo Check output\text\ for compressed files and output\QR\ for QR codes
    ) else (
        echo.
        echo QR code generation failed!
    )
) else (
    echo.
    echo Compression failed!
)

pause