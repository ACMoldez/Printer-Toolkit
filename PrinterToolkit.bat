
@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Micah's Printer Toolkit
mode con: cols=58 lines=32

:: ==========================================
:: MICAH'S PRINTER TOOLKIT - COLOR THEME
:: Pink | Purple | Midnight Blue
:: ==========================================

for /F %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"

set "RESET=!ESC![0m"
set "PINK=!ESC![38;2;255;166;201m"
set "PURPLE=!ESC![38;2;199;164;255m"
set "WHITE=!ESC![38;2;245;240;255m"
set "MUTED=!ESC![38;2;169;157;196m"
set "RED=!ESC![38;2;255;120;145m"
set "GREEN=!ESC![38;2;155;235;196m"

:: Enable midnight-blue background where supported
cls

:MENU
cls
echo.
echo  !PINK!========================================================!RESET!
echo.
echo        !PINK!M I C A H ' S !RESET! !PURPLE!P R I N T E R   T O O L K I T!RESET!
echo.
echo  !PINK!========================================================!RESET!
echo.
echo   !PURPLE![01]!RESET! !WHITE!View Installed Printers!RESET!
echo   !PURPLE![02]!RESET! !WHITE!Open Printer Settings!RESET!
echo   !PURPLE![03]!RESET! !WHITE!Restart Printer Spooler!RESET!
echo   !PURPLE![04]!RESET! !WHITE!Clear Print Queue!RESET!
echo   !PURPLE![05]!RESET! !WHITE!Devices and Printers!RESET!
echo   !PURPLE![06]!RESET! !WHITE!Print Test Page!RESET!
echo   !PURPLE![07]!RESET! !WHITE!Show Printer Status!RESET!
echo   !PURPLE![08]!RESET! !WHITE!Print Management!RESET!
echo   !PURPLE![09]!RESET! !WHITE!Scanner Settings!RESET!
echo   !PURPLE![10]!RESET! !WHITE!Full Printer Settings!RESET!
echo.
echo   !PINK![11]!RESET! !RED!Exit Toolkit!RESET!
echo.
echo  !PINK!--------------------------------------------------------!RESET!
set "choice="
set /p "choice=  !PINK!Choose an option !PURPLE!^> !RESET!"

if "!choice!"=="1" goto VIEW
if "!choice!"=="01" goto VIEW
if "!choice!"=="2" goto SETTINGS
if "!choice!"=="02" goto SETTINGS
if "!choice!"=="3" goto SPOOLER
if "!choice!"=="03" goto SPOOLER
if "!choice!"=="4" goto CLEAR
if "!choice!"=="04" goto CLEAR
if "!choice!"=="5" goto DEVICES
if "!choice!"=="05" goto DEVICES
if "!choice!"=="6" goto TEST
if "!choice!"=="06" goto TEST
if "!choice!"=="7" goto STATUS
if "!choice!"=="07" goto STATUS
if "!choice!"=="8" goto MANAGEMENT
if "!choice!"=="08" goto MANAGEMENT
if "!choice!"=="9" goto SCANNER
if "!choice!"=="09" goto SCANNER
if "!choice!"=="10" goto REPAIR
if "!choice!"=="11" goto EXIT

echo.
echo  !RED!Invalid option. Please try again.!RESET!
timeout /t 2 >nul
goto MENU

:VIEW
call :HEADER "INSTALLED PRINTERS"
echo.
powershell -NoProfile -Command "Get-Printer | Select-Object Name, PortName, PrinterStatus | Format-Table -AutoSize"
echo.
call :WAIT
goto MENU

:SETTINGS
start "" "ms-settings:printers"
goto MENU

:SPOOLER
call :HEADER "RESTART PRINT SPOOLER"
echo.
call :CHECKADMIN
if errorlevel 1 goto MENU

echo  !MUTED!Stopping Print Spooler...!RESET!
net stop spooler
if errorlevel 1 (
    echo  !RED!Unable to stop the Print Spooler.!RESET!
    call :WAIT
    goto MENU
)

echo.
echo  !MUTED!Starting Print Spooler...!RESET!
net start spooler
if errorlevel 1 (
    echo  !RED!Unable to start the Print Spooler.!RESET!
    call :WAIT
    goto MENU
)

echo.
echo  !GREEN!Print Spooler restarted successfully.!RESET!
call :WAIT
goto MENU

:CLEAR
call :HEADER "CLEAR PRINT QUEUE"
echo.
echo  !RED!WARNING: This clears pending jobs for ALL printers.!RESET!
echo.
set "confirm="
set /p "confirm=  !PINK!Continue? (Y/N) ^> !RESET!"
if /i not "!confirm!"=="Y" goto MENU

call :CHECKADMIN
if errorlevel 1 goto MENU

echo.
echo  !MUTED!Stopping Print Spooler...!RESET!
net stop spooler
if errorlevel 1 (
    echo  !RED!Could not stop the Print Spooler.!RESET!
    call :WAIT
    goto MENU
)

echo.
echo  !MUTED!Removing pending print jobs...!RESET!
del /f /q "%windir%\System32\spool\PRINTERS\*.*" 2>nul

echo.
echo  !MUTED!Starting Print Spooler...!RESET!
net start spooler
if errorlevel 1 (
    echo  !RED!Spooler failed to restart. Run net start spooler as admin.!RESET!
    call :WAIT
    goto MENU
)

echo.
echo  !GREEN!Print queue cleared successfully.!RESET!
call :WAIT
goto MENU

:DEVICES
start "" control.exe printers
goto MENU

:TEST
call :HEADER "PRINT TEST PAGE"
echo.
call :LOADPRINTERS
if errorlevel 1 goto MENU

call :SELECTPRINTER
if errorlevel 1 goto TEST

echo.
echo  !MUTED!Sending test page to:!RESET!
echo  !PINK!!selectedPrinter!!RESET!
rundll32.exe printui.dll,PrintUIEntry /k /n "!selectedPrinter!"
echo.
echo  !GREEN!Test page request submitted.!RESET!
call :WAIT
goto MENU

:STATUS
call :HEADER "PRINTER STATUS"
echo.
powershell -NoProfile -Command "Get-Printer | ForEach-Object { $p = $_; Write-Output ('Printer: ' + $p.Name); Write-Output ('Status: ' + $p.PrinterStatus); Write-Output ('Port: ' + $p.PortName); try { $jobs = @(Get-PrintJob -PrinterName $p.Name -ErrorAction Stop); Write-Output ('Pending jobs: ' + $jobs.Count); if ($jobs.Count -gt 0) { $jobs | Select-Object ID, DocumentName, JobStatus | Format-Table -AutoSize } } catch { Write-Output 'Unable to retrieve print jobs.' }; Write-Output '' }"
echo.
call :WAIT
goto MENU

:MANAGEMENT
start "" printmanagement.msc
goto MENU

:SCANNER
start "" "ms-settings:printers"
goto MENU

:REPAIR
call :HEADER "FULL PRINTER SETTINGS"
echo.
call :LOADPRINTERS
if errorlevel 1 goto MENU

call :SELECTPRINTER
if errorlevel 1 goto REPAIR

echo.
echo  !MUTED!Opening properties for:!RESET!
echo  !PINK!!selectedPrinter!!RESET!
rundll32.exe printui.dll,PrintUIEntry /p /n "!selectedPrinter!"
call :WAIT
goto MENU

:HEADER
cls
echo.
echo  !PINK!========================================================!RESET!
echo.
echo                  !PURPLE!%~1!RESET!
echo.
echo  !PINK!========================================================!RESET!
echo.
exit /b 0

:LOADPRINTERS
set "printerFile=%temp%\micah_printers_%random%.txt"
set "printerCount=0"

powershell -NoProfile -Command "Get-Printer | Select-Object -ExpandProperty Name" > "!printerFile!" 2>nul

if not exist "!printerFile!" (
    echo  !RED!Unable to retrieve printers.!RESET!
    call :WAIT
    exit /b 1
)

for %%F in ("!printerFile!") do if %%~zF EQU 0 (
    echo  !RED!No printers found.!RESET!
    del "!printerFile!" 2>nul
    call :WAIT
    exit /b 1
)

echo  !MUTED!Select a printer:!RESET!
echo.

for /f "usebackq delims=" %%P in ("!printerFile!") do (
    set /a printerCount+=1
    echo   !PINK![!printerCount!]!RESET! !WHITE!%%P!RESET!
)

if !printerCount! EQU 0 (
    del "!printerFile!" 2>nul
    call :WAIT
    exit /b 1
)

exit /b 0

:SELECTPRINTER
echo.
set "printerChoice="
set /p "printerChoice=  !PURPLE!Printer number (0 to cancel) ^> !RESET!"

if "!printerChoice!"=="0" (
    del "!printerFile!" 2>nul
    exit /b 1
)

set "selectedPrinter="
set "printerIndex=0"

for /f "usebackq delims=" %%P in ("!printerFile!") do (
    set /a printerIndex+=1
    if "!printerChoice!"=="!printerIndex!" set "selectedPrinter=%%P"
)

del "!printerFile!" 2>nul

if not defined selectedPrinter (
    echo.
    echo  !RED!Invalid selection. Try again.!RESET!
    timeout /t 2 >nul
    exit /b 1
)

exit /b 0

:CHECKADMIN
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo  !RED!Administrator privileges are required.!RESET!
    echo  !MUTED!Run this file as Administrator.!RESET!
    call :WAIT
    exit /b 1
)
exit /b 0

:WAIT
echo.
echo  !PINK!--------------------------------------------------------!RESET!
pause
exit /b 0

:EXIT
echo.
echo  !PURPLE!Thank you for using the Printer Toolkit.!RESET!
echo.
echo !RESET!
exit /b 0
