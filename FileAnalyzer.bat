@echo off
chcp 65001 >nul
title File Analyzer Tool
color 0A

echo ========================================
echo      File Analyzer Tool v1.0
echo ========================================
echo.

:: Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Cannot run PowerShell. Please ensure PowerShell is available.
    pause
    exit /b 1
)

:: Get script directory
set "ScriptDir=%~dp0"
set "PsScript=%ScriptDir%FileAnalyzer.ps1"

:: Check if PowerShell script exists
if not exist "%PsScript%" (
    echo Error: Cannot find PowerShell script: %PsScript%
    pause
    exit /b 1
)

:: Show menu
:menu
echo Please select an option:
echo.
echo  [1] Analyze current folder
echo  [2] Analyze specified folder
echo  [3] Show help
echo  [4] Exit
echo.
set /p choice="Enter option (1-4): "

if "%choice%"=="1" goto analyze_current
if "%choice%"=="2" goto analyze_custom
if "%choice%"=="3" goto show_help
if "%choice%"=="4" goto exit

echo Invalid option, please try again.
echo.
goto menu

:analyze_current
echo.
echo Analyzing current folder...
powershell -ExecutionPolicy Bypass -File "%PsScript%" -Path "%cd%"
if %errorlevel% neq 0 (
    echo.
    echo An error occurred during analysis.
)
goto end

:analyze_custom
echo.
set /p custom_path="Enter folder path to analyze: "
if not exist "%custom_path%" (
    echo Error: Specified path does not exist!
    goto menu
)
echo.
echo Analyzing folder: %custom_path%
powershell -ExecutionPolicy Bypass -File "%PsScript%" -Path "%custom_path%"
if %errorlevel% neq 0 (
    echo.
    echo An error occurred during analysis.
)
goto end

:show_help
echo.
powershell -ExecutionPolicy Bypass -File "%PsScript%" -Help
goto end

:end
echo.
echo Press any key to exit...
pause >nul

:exit
exit /b 0
