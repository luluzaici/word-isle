@echo off
setlocal EnableExtensions
cd /d "%~dp0"
set "PORT=8137"
set "IP="

echo.
echo   Word Isle - local server
echo   ================================================
echo   Detecting this computer's LAN address...
echo.

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
  for /f "tokens=1" %%b in ("%%a") do (
    if not defined IP set "IP=%%b"
    echo   iPhone: http://%%b:%PORT%/
  )
)

if not defined IP (
  echo   No IPv4 address found. Connect to Wi-Fi or Ethernet first.
  echo.
  pause
  exit /b 1
)

echo.
echo   This computer: http://127.0.0.1:%PORT%/
echo   iPhone:        http://%IP%:%PORT%/
echo.
echo   1. Keep this window open.
echo   2. Connect the iPhone to the same Wi-Fi.
echo   3. Open the iPhone URL in Safari.
echo   4. Share - Add to Home Screen.
echo.
echo   If the iPhone cannot connect: try another IPv4 listed above,
echo   and allow Python through Windows Firewall when asked.
echo.
echo   Press Ctrl+C to stop the server.
echo   ================================================
echo.

python -m http.server %PORT% --bind 0.0.0.0
pause
