@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "MODE=%~1"
title Grave Danger - PNG-to-GridMap diagnostic
if /i not "%MODE%"=="normal" if /i not "%MODE%"=="compatibility" (
    echo This helper must be started by one of the PNG-to-GridMap diagnostic files.
    pause
    exit /b 2
)

for %%I in ("%~dp0..") do set "PROJECT_DIR=%%~fI"
if not exist "%PROJECT_DIR%\project.godot" (
    echo.
    echo The Grave Danger project could not be found beside this diagnostic file.
    echo Please keep the BAT files inside the project folder and try again.
    echo.
    pause
    exit /b 2
)

call :find_godot
if not defined GODOT_EXE call :choose_godot
if not defined GODOT_EXE (
    echo.
    echo Godot could not be found. No settings need changing: please ask Dave to
    echo check that the Godot editor is installed or still present on this PC.
    echo.
    pause
    exit /b 2
)

for %%I in ("%GODOT_EXE%") do if exist "%%~dpnI_console%%~xI" set "GODOT_EXE=%%~dpnI_console%%~xI"

for /f "delims=" %%I in ('powershell.exe -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"') do set "DESKTOP_DIR=%%I"
if not defined DESKTOP_DIR set "DESKTOP_DIR=%USERPROFILE%\Desktop"
for /f "delims=" %%I in ('powershell.exe -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'"') do set "STAMP=%%I"
for /f "delims=" %%I in ('powershell.exe -NoProfile -Command "(Get-Date).ToUniversalTime().ToString('o')"') do set "START_UTC=%%I"
if not defined STAMP set "STAMP=latest"

set "RESULTS_DIR=%DESKTOP_DIR%\Grave Danger PNG Diagnostics"
set "RUN_DIR=%RESULTS_DIR%\%STAMP%_%MODE%"
set "ENGINE_LOG=%RUN_DIR%\godot_verbose.log"
set "SUMMARY=%RUN_DIR%\computer_and_run_details.txt"
set "EVENT_LOG=%RUN_DIR%\recent_windows_errors.txt"
set "ZIP_PATH=%DESKTOP_DIR%\Grave-Danger-PNG-Diagnostics-%STAMP%-%MODE%.zip"
mkdir "%RUN_DIR%" 2>nul

> "%SUMMARY%" (
    echo Grave Danger PNG-to-GridMap diagnostic
    echo =======================================
    echo Mode: %MODE%
    echo Started: %DATE% %TIME%
    echo Godot: %GODOT_EXE%
    echo Project: %PROJECT_DIR%
    echo.
    echo Windows version:
    ver
)

>> "%SUMMARY%" echo.
>> "%SUMMARY%" echo Godot version:
"%GODOT_EXE%" --version >> "%SUMMARY%" 2>&1
>> "%SUMMARY%" echo.
>> "%SUMMARY%" echo Windows and graphics details:
powershell.exe -NoProfile -Command "$os=Get-CimInstance Win32_OperatingSystem; $gpu=Get-CimInstance Win32_VideoController; 'Windows: '+$os.Caption+' '+$os.Version+' '+$os.OSArchitecture; $gpu | ForEach-Object { 'Graphics: '+$_.Name+' - driver '+$_.DriverVersion }" >> "%SUMMARY%" 2>&1

cls
echo Grave Danger PNG-to-GridMap diagnostic
echo =======================================
echo.
echo Godot will open with detailed logging enabled.
echo Please reproduce the problem, then close Godot if it remains open.
echo This window will package the results automatically afterwards.
echo.
echo Diagnostic mode: %MODE%
echo Results folder: %RUN_DIR%
echo.

if /i "%MODE%"=="compatibility" (
    "%GODOT_EXE%" --editor --path "%PROJECT_DIR%" --verbose --log-file "%ENGINE_LOG%" --rendering-method gl_compatibility
) else (
    "%GODOT_EXE%" --editor --path "%PROJECT_DIR%" --verbose --log-file "%ENGINE_LOG%"
)
set "GODOT_EXIT_CODE=%ERRORLEVEL%"

>> "%SUMMARY%" echo.
>> "%SUMMARY%" echo Godot finished: %DATE% %TIME%
>> "%SUMMARY%" echo Godot exit code: %GODOT_EXIT_CODE%

powershell.exe -NoProfile -Command "$start=[DateTime]::Parse($env:START_UTC); Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=$start} -ErrorAction SilentlyContinue | Where-Object { $_.Message -match 'Godot' } | Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message | Format-List | Out-File -Width 240 -Encoding utf8 $env:EVENT_LOG" >nul 2>&1
powershell.exe -NoProfile -Command "$start=[DateTime]::Parse($env:START_UTC); $source=Join-Path $env:LOCALAPPDATA 'CrashDumps'; if(Test-Path $source){ Get-ChildItem $source -Filter 'Godot*.dmp' -File | Where-Object { $_.LastWriteTimeUtc -ge $start } | Copy-Item -Destination $env:RUN_DIR -Force }" >nul 2>&1
powershell.exe -NoProfile -Command "Compress-Archive -Path (Join-Path $env:RUN_DIR '*') -DestinationPath $env:ZIP_PATH -Force" >nul 2>&1

cls
echo Diagnostic complete
echo ===================
echo.
if exist "%ZIP_PATH%" (
    echo Please send this file to Dave:
    echo.
    echo %ZIP_PATH%
    echo.
    explorer.exe /select,"%ZIP_PATH%"
) else (
    echo The ZIP could not be created. Please send Dave this folder instead:
    echo.
    echo %RUN_DIR%
    echo.
    explorer.exe "%RUN_DIR%"
)
echo.
if /i "%MODE%"=="normal" (
    echo If Godot crashed, please also run:
    echo RUN_PNG_TO_GRIDMAP_COMPATIBILITY_DIAGNOSTIC.bat
    echo That second result will show whether the graphics renderer is involved.
    echo.
)
echo Press any key to close this window.
pause >nul
exit /b %GODOT_EXIT_CODE%

:find_godot
if defined GODOT4 if exist "%GODOT4%" set "GODOT_EXE=%GODOT4%"
if defined GODOT_EXE exit /b 0

for %%N in (godot.exe godot4.exe Godot_v4.7-stable_win64_console.exe Godot_v4.7-stable_win64.exe) do (
    for /f "delims=" %%I in ('where %%N 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%I"
)
if defined GODOT_EXE exit /b 0

for %%I in (
    "%USERPROFILE%\scoop\apps\godot\current\godot.exe"
    "%USERPROFILE%\scoop\shims\godot.exe"
    "%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe"
    "%LOCALAPPDATA%\Programs\Godot\Godot.exe"
    "%ProgramFiles%\Godot\Godot.exe"
) do if not defined GODOT_EXE if exist "%%~I" set "GODOT_EXE=%%~I"
if defined GODOT_EXE exit /b 0

for %%D in ("%USERPROFILE%\Downloads" "%USERPROFILE%\Desktop" "%USERPROFILE%\Documents") do (
    if exist "%%~D" for /f "delims=" %%I in ('dir /b /s /a-d "%%~D\Godot*_console.exe" 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%I"
)
for %%D in ("%USERPROFILE%\Downloads" "%USERPROFILE%\Desktop" "%USERPROFILE%\Documents") do (
    if exist "%%~D" for /f "delims=" %%I in ('dir /b /s /a-d "%%~D\Godot*.exe" 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%I"
)
exit /b 0

:choose_godot
echo.
echo Godot was not in its usual locations. A file window will open now.
echo Please select the Godot application; no settings need changing.
echo.
for /f "delims=" %%I in ('powershell.exe -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $dialog=New-Object System.Windows.Forms.OpenFileDialog; $dialog.Title='Select the Godot editor'; $dialog.Filter='Godot editor (Godot*.exe)|Godot*.exe|Applications (*.exe)|*.exe'; if($dialog.ShowDialog() -eq 'OK'){ $dialog.FileName }"') do set "GODOT_EXE=%%I"
exit /b 0
