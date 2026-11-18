@echo off
chcp 65001 >nul
title AutoClip Launcher
powershell -ExecutionPolicy Bypass -File "%~dp0start_autoclip.ps1"
pause
