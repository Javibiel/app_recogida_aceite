@echo off
cd /d "%~dp0"

start "SERRMA web" /min cmd /c flutter run -d web-server --release --web-hostname 127.0.0.1 --web-port 57200

timeout /t 12 /nobreak >nul
start "" "http://127.0.0.1:57200"
