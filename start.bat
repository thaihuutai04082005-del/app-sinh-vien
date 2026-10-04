@echo off
setlocal

cd /d "%~dp0mobile"

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
  echo [LOI] Khong the cai dat thu vien Flutter.
  pause
  exit /b 1
)

echo Dang khoi dong ung dung UniHub Flutter tren Chrome...
call "%FLUTTER%" run -d chrome

if errorlevel 1 (
  echo [LOI] Ung dung Flutter khoi dong khong thanh cong.
  pause
  exit /b 1
)

endlocal
