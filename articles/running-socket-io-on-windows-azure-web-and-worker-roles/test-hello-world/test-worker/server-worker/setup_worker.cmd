@echo off

echo Granting permissions for Network Service to the deployment directory...
icacls . /grant "Network Service":(OI)(CI)W
if %ERRORLEVEL% neq 0 goto error
echo OK

echo SUCCESS
exit /b 0

:error

echo FAILED
exit /b -1