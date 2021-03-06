@echo off
cls
setlocal ENABLEDELAYEDEXPANSION

:: Get general properties
SET RUNSCRIPT=ForceUpdate
:: Setting defaults
SET WORKDIR=%cd%
:: Asume folder name == Project name
SET "CDIR=%WORKDIR:~0%"
FOR %%i IN ("%CDIR%") DO SET "REQPROJ=%%~nxi"
IF NOT [%1]==[] (
	SET REQENV=%1
)
IF NOT [%REQENV%]==[] (
	call getSettings.bat %REQPROJ% %REQENV%
) ELSE (
	call getSettings.bat
)

if "%errorlevel%"=="1" goto missingsettings
call callinfo.bat

:: Checks
IF NOT EXIST %SFPACKAGE% goto missingpackagefile

ECHO Description:	This will fetch %SFCONTEXT% metadata and overwrite %WORKDIR%\%SRCFOLDER% (Active Branch: %GITBRANCH%)
IF NOT "%GITSTATUS%"=="clean" (
	ECHO:
	call callnotify "ATTENTION: Git status is not clean. You will lose unsaved/uncommitted local changes"
	ECHO:
)
ECHO %HR%
ECHO:
SET /P ANSWER=%ATT%	Overwrite branch ^>^> %GITBRANCH% ^<^< with %SFCONTEXT% ? (Y/N)
ECHO:
if /i {%ANSWER%}=={y} goto run
set ERRORMSG=Update aborted
goto aborted

:run
SET TMPSRC=%TMPDIR%\tmpsrc
IF EXIST %TMPSRC% rmdir %TMPSRC% /s/q
call wait.bat
mkdir %TMPSRC%
call getMetadata %SFUSER% %SFPASSWORD% %SFSERVER% %TMPSRC% %SFPACKAGE% %BUILDXML% %TMPLOGFILE%
set antcallresult=%errorlevel%
IF NOT "%antcallresult%"=="0" goto anterror
:: succes - move old src to TMP and tmpsrc to %SRCFOLDER% folder
IF EXIST %WORKDIR%\%SRCFOLDER% (
	xcopy %WORKDIR%\%SRCFOLDER% %TMPBACKUP% /s/e/h/i/q
	rmdir /s/q %WORKDIR%\%SRCFOLDER%
	call wait.bat
)
xcopy %TMPSRC% %WORKDIR%\%SRCFOLDER% /s/e/h/i/q

call hook_update %HOOK%
call wait.bat

goto done

:missingpackagefile
set ERRORMSG=No sfpackage.xml present in project folder...
goto aborted

:missingsettings
set ERRORMSG=Problem loading settings...
goto aborted

:wrongbranch
set ERRORMSG=Wrong branch...
goto aborted

:anterror
ECHO.
ECHO %HR%
ECHO * Ant Error Log: %TMPLOGFILE%
ECHO %HR%
type %TMPLOGFILE%
ECHO %HR%
call callnotify "ABORTED, DID NOT UPDATE. (%SFCONTEXT%)"
goto end

:aborted
ECHO:
call callnotify "ABORTED, DID NOT UPDATE. ERROR: %ERRORMSG% (%SFCONTEXT%)"
goto end

:done
ECHO:
call callnotify "SUCCESS. FINISHED UPDATE"
goto end

:end
endlocal
call unsetAll.bat
