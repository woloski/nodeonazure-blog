cd /d "%~dp0"

if "%EMULATED%"=="true" exit /b 0

echo LOG > setup_git_log.txt

REM SET GITPATH=C:\Resources\directory\git\
REM SET GITREPOBLOGPATH=C:\Resources\directory\blog\
REM SET GITREPOURL=git://github.com/woloski/nodeonazure-blog.git

REM remove trailing slash if any
IF %GITPATH:~-1%==\ SET GITPATH=%GITPATH:~0,-1%
IF %GITREPOBLOGPATH:~-1%==\ SET GITREPOBLOGPATH=%GITREPOBLOGPATH:~0,-1%

echo GITPATH= %GITPATH% 1>> setup_git_log.txt
echo GITREPOBLOGPATH= %GITREPOBLOGPATH% 1>> setup_git_log.txt
echo GITREPOURL= %GITREPOURL% 1>> setup_git_log.txt

if "%EMULATED%"=="true" exit /b 0

powershell -c "set-executionpolicy unrestricted" 1>> setup_git_log.txt 2>> setup_git_log_error.txt
powershell .\download.ps1 "http://msysgit.googlecode.com/files/PortableGit-1.7.8-preview20111206.7z" 1>> setup_git_log.txt 2>> setup_git_log_error.txt
powershell .\appendPath.ps1 "%GITPATH%\bin" 1>> setup_git_log.txt 2>> setup_git_log_error.txt

7za x PortableGit-1.7.8-preview20111206.7z -y -o"%GITPATH%" 1>> setup_git_log.txt 2>> setup_git_log_error.txt
echo y| cacls "%GITPATH%" /grant everyone:f /t 1>> setup_git_log.txt 2>> setup_git_log_error.txt
"%GITPATH%\bin\git" clone --mirror %GITREPOURL% "%GITREPOBLOGPATH%" 1>> setup_git_log.txt 2>> setup_git_log_error.txt
echo y| cacls "%GITREPOBLOGPATH%" /grant everyone:f /t 1>> setup_git_log.txt 2>> setup_git_log_error.txt

REM add GITREPOBLOGPATH as a system env variable to be used by node
powershell "[Environment]::SetEnvironmentVariable('GITREPOBLOGPATH', '%GITREPOBLOGPATH%', 'Machine')" 1>> setup_git_log.txt 2>> setup_git_log_error.txt 

IISRESET  1>> setup_git_log.txt 2>> setup_git_log_error.txt 
NET START W3SVC 1>> setup_git_log.txt 2>> setup_git_log_error.txt 

echo SUCCESS
exit /b 0

:error

echo FAILED
exit /b -1