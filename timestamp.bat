@echo off
For /f "tokens=2-4 delims=/- " %%a in ('date /t') do (set mydate=%%c%%b%%a)
For /f "tokens=1-3 delims=/:/ " %%a in ('time /t') do (set mytime=%%a%%b%%c)
set TIMESTAMP=%mydate%-%mytime%