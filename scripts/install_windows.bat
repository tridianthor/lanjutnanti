@echo off
setlocal EnableExtensions

set "PROJECT_ROOT=%~dp0.."
for %%I in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fI"

set "BUILD_DIR=%PROJECT_ROOT%\build\windows\x64\runner\Release"
set "INSTALL_DIR=%USERPROFILE%\local\app\lanjutnanti"

where flutter >nul 2>&1
if errorlevel 1 (
    echo Flutter was not found on PATH.
    exit /b 1
)

pushd "%PROJECT_ROOT%"
echo Building the Windows release...
call flutter build windows --release
if errorlevel 1 (
    echo Windows build failed.
    popd
    exit /b 1
)
popd

if not exist "%BUILD_DIR%" (
    echo Windows build output was not found:
    echo   %BUILD_DIR%
    exit /b 1
)

if exist "%INSTALL_DIR%" (
    echo Replacing existing installation:
    echo   %INSTALL_DIR%
) else (
    echo Creating installation directory:
    echo   %INSTALL_DIR%
    mkdir "%INSTALL_DIR%"
    if errorlevel 1 (
        echo Could not create the installation directory.
        exit /b 1
    )
)

rem /MIR removes stale files so the install exactly matches the build bundle.
robocopy "%BUILD_DIR%" "%INSTALL_DIR%" /MIR /R:2 /W:1
set "ROBOCOPY_EXIT=%ERRORLEVEL%"

if %ROBOCOPY_EXIT% LEQ 7 (
    echo Windows installation completed:
    echo   %INSTALL_DIR%
    exit /b 0
)

echo Windows installation failed. Robocopy exit code: %ROBOCOPY_EXIT%
exit /b %ROBOCOPY_EXIT%
