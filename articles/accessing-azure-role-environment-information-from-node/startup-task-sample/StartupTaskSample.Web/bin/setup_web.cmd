@echo off

cd /d "%~dp0"

echo Granting permissions for Network Service to the web root directory...
icacls ..\ /grant "Network Service":(OI)(CI)W
if %ERRORLEVEL% neq 0 goto error
echo OK

if "%EMULATED%"=="true" exit /b 0

echo Ensuring the "%programfiles(x86)%\nodejs" directory exists...
md "%programfiles(x86)%\nodejs"

echo Copying node.exe to the "%programfiles(x86)%\nodejs" directory...
copy /y node.exe "%programfiles(x86)%\nodejs" 
if %ERRORLEVEL% neq 0 goto error
echo OK

echo Copying web.cloud.config to web.config...
copy /y ..\Web.cloud.config ..\Web.config
if %ERRORLEVEL% neq 0 goto error
echo OK

echo Installing Visual Studio 2010 C++ Redistributable Package...
vcredist_x64.exe /q 
if %ERRORLEVEL% neq 0 goto error
echo OK

echo Installing iisnode...
msiexec.exe /quiet /i iisnode.msi
if %ERRORLEVEL neq 0 goto error
echo OK

echo SUCCESS
exit /b 0

:error

echo FAILED
exit /b -1