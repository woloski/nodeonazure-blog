cd /d "%~dp0"

REM SET GITPATH=C:\Resources\directory\git
REM SET GITREPOBLOGPATH=C:\Resources\directory\blog
REM SET GITREPOURL=git://github.com/woloski/nodeonazure-blog.git

if "%EMULATED%"=="true" exit /b 0

powershell -c "set-executionpolicy unrestricted"
powershell .\download.ps1 "http://msysgit.googlecode.com/files/PortableGit-1.7.8-preview20111206.7z"
powershell .\appendPath.ps1 "%GITPATH%"

7za x PortableGit-1.7.8-preview20111206.7z -y -o"%GITPATH%"
echo y| cacls "%GITPATH%" /grant everyone:f /t
"%GITPATH%\git" clone --mirror %GITREPOURL% "%GITREPOBLOGPATH%"
echo y| cacls "%GITREPOBLOGPATH%" /grant everyone:f /t

echo SUCCESS
exit /b 0

:error

echo FAILED
exit /b -1