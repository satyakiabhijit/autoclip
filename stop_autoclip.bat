@echo off
chcp 65001 >nul
title AutoClip Terminator
powershell -ExecutionPolicy Bypass -File "%~dp0stop_autoclip.ps1"
timeout /t 2 >nul
