@echo off
title Vercel Login
cd /d "%~dp0"
echo Logging in to Vercel...
call npx vercel login
pause