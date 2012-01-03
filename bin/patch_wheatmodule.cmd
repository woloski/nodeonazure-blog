cd /d "%~dp0"

if "%EMULATED%"=="true" exit /b 0

copy ..\wheat.data.patched.js ..\node_modules\wheat\lib\wheat\data.js /Y

echo SUCCESS
exit /b 0

:error

echo FAILED
exit /b -1