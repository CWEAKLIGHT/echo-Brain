@echo off
title ECHO - run all tests
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_all.ps1" %*
set "CODE=%ERRORLEVEL%"
echo.
if "%CODE%"=="0" (
  echo   [OK] all suites passed
) else (
  echo   [FAILED] see the output above
)
echo.
pause
exit /b %CODE%
