@echo off
setlocal

set "FLUTTER=flutter"
where flutter >nul 2>&1
if errorlevel 1 set "FLUTTER=F:\Apps\flutter\bin\flutter.bat"

echo Dang build ban web Flutter...
cd /d "%~dp0mobile"
call "%FLUTTER%" build web --release
if errorlevel 1 goto :error

cd /d "%~dp0cloudflare"
if not exist node_modules (
  call npm install
  if errorlevel 1 goto :error
)

start "UniHub Worker" cmd /k npx wrangler dev --port 8787 --ip 127.0.0.1
timeout /t 10 /nobreak >nul
start "UniHub Tunnel" cmd /k cloudflared tunnel --url http://127.0.0.1:8787 --no-autoupdate
echo Link cong khai (https://...trycloudflare.com) hien trong cua so "UniHub Tunnel".
pause
exit /b 0

:error
echo [LOI] Xem thong bao phia tren.
pause
exit /b 1
