@echo off
title Smartiva Flutter Runner
cd /d "%~dp0"
echo Starting Smartiva with pure Flutter...
call G:\flutter\bin\flutter.bat run -d chrome
pause