@echo off
setlocal

cd /d "%~dp0"

set "FLUTTER=flutter"
where flutter >nul 2>&1
if errorlevel 1 (
  if exist "F:\Apps\flutter\bin\flutter.bat" (
    set "FLUTTER=F:\Apps\flutter\bin\flutter.bat"
  ) else (
    echo [LOI] Chua tim thay Flutter SDK.
    pause
    exit /b 1
  )
)

echo Dang cai dat thu vien Flutter...
call "%FLUTTER%" pub get
if errorlevel 1 (
  pause
  exit /b 1
)

echo Dang mo app tren Chrome...
call "%FLUTTER%" run -d chrome
pause
