@echo off
rem Starts the IRONBLOOD browser version: a small local web server, then your browser.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
