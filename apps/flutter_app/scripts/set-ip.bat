@echo off
chcp 65001 >nul

set "SCRIPT_DIR=%~dp0"

if "%~1"=="" (
    goto :run_script
)

if "%~2"=="" (
    set "PARAMS=-Ip %~1"
    goto :run_script
)

set "PARAMS=-Ip %~1 -Port %~2"
goto :run_script

:end
exit /b

:run_script
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%set-ip.ps1" %PARAMS%
