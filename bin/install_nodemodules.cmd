cd /d "%~dp0"

if "%EMULATED%"=="true" exit /b 0

powershell -c "set-executionpolicy unrestricted"
powershell .\download.ps1 "http://npmjs.org/dist/npm-1.1.0-beta-7.zip"

7za x npm-1.1.0-beta-7.zip -y
npm install ..\

echo SUCCESS
exit /b 0

:error

echo FAILED
exit /b -1