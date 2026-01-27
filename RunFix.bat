@echo off
:: Admin yetkisi kontrolü ve istemi
NET SESSION >nul 2>&1
if %errorLevel% == 0 (
    goto :run
) else (
    echo Yonetici yetkileri aliniyor...
    powershell -Command "Start-Process '%~0' -Verb RunAs"
    exit /b
)

:run
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "FixExcaliburCamera.ps1"
pause
