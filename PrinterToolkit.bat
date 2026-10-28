
@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Micah's Printer Toolkit
color 0D

:MENU
cls
echo.
echo ================================
echo     Micah's Printer Toolkit
echo ================================
echo.
echo  1. View Installed Printers
echo  2. Open Printer Settings
echo  3. Restart Printer Spooler
echo  4. Clear Print Queue
echo  5. Open Devices and Printers
echo  6. Print Test Page
echo  7. Show Printer Status
echo  8. Open Print Management
echo  9. Open Scanner Settings
echo 10. Full Printer Settings
echo 11. Exit
echo.
echo ================================
set "choice="
set /p "choice=Choose an option: "

if "!choice!"=="1" goto VIEW
if "!choice!"=="2" goto SETTINGS
if "!choice!"=="3" goto SPOOLER
if "!choice!"=="4" goto CLEAR
if "!choice!"=="5" goto DEVICES
if "!choice!"=="6" goto TEST
if "!choice!"=="7" goto STATUS
if "!choice!"=="8" goto MANAGEMENT
if "!choice!"=="9" goto SCANNER
if "!choice!"=="10" goto REPAIR
if "!choice!"=="11" exit /b

echo.
echo Invalid option. Pick again.
pause
goto MENU

:VIEW
cls
echo ================================
echo       INSTALLED PRINTERS
echo ================================
echo.
powershell -NoProfile -Command "Get-Printer | Select-Object Name, PortName, PrinterStatus | Format-Table -AutoSize"
echo.
pause
goto MENU

:SETTINGS
cls
echo Opening Printer Settings...
start "" "ms-settings:printers"
goto MENU

:SPOOLER
cls
echo ================================
echo       RESTART PRINT SPOOLER
echo ================================
echo.
call :CHECKADMIN
if errorlevel 1 goto MENU

echo Stopping Print Spooler...
net stop spooler
if errorlevel 1 (
    echo.
    echo Failed to stop the Print Spooler.
    pause
    goto MENU
)

echo.
echo Starting Print Spooler...
net start spooler
if errorlevel 1 (
    echo Failed to start the Print Spooler.
    pause
    goto MENU
)

echo.
echo Print Spooler restarted successfully.
pause
goto MENU

:CLEAR
cls
echo ================================
echo         CLEAR PRINT QUEUE
echo ================================
echo.
call :CHECKADMIN
if errorlevel 1 goto MENU

echo WARNING: This removes pending print jobs
echo from ALL printers on this computer.
echo.
set "confirm="
set /p "confirm=Continue? (Y/N): "
if /i not "!confirm!"=="Y" goto MENU

echo.
echo Stopping Print Spooler...
net stop spooler
if errorlevel 1 (
    echo Could not stop the Print Spooler.
    pause
    goto MENU
)

echo.
echo Deleting pending print jobs...
del /f /q "%windir%\System32\spool\PRINTERS\*.*" 2>nul

echo.
echo Starting Print Spooler...
net start spooler
if errorlevel 1 (
    echo WARNING: The Print Spooler did not restart.
    echo Run "net start spooler" as Administrator.
    pause
    goto MENU
)

echo.
echo Print queue clearing completed.
pause
goto MENU

:DEVICES
cls
echo Opening Devices and Printers...
start "" control.exe printers
goto MENU

:TEST
cls
echo ================================
echo          PRINT TEST PAGE
echo ================================
echo.

call :LOADPRINTERS
if errorlevel 1 goto MENU

call :SELECTPRINTER
if errorlevel 1 goto TEST

echo.
echo Sending test page to:
echo !selectedPrinter!
echo.
rundll32.exe printui.dll,PrintUIEntry /k /n "!selectedPrinter!"

echo.
echo Test page command submitted.
echo Check the printer and its queue for the result.
pause
goto MENU

:STATUS
cls
echo ================================
echo         PRINTER STATUS
echo ================================
echo.
powershell -NoProfile -Command "Get-Printer | ForEach-Object { $p = $_; Write-Output ('Printer: ' + $p.Name); Write-Output ('Status: ' + $p.PrinterStatus); Write-Output ('Port: ' + $p.PortName); try { $jobs = @(Get-PrintJob -PrinterName $p.Name -ErrorAction Stop); Write-Output ('Pending jobs: ' + $jobs.Count); if ($jobs.Count -gt 0) { $jobs | Select-Object ID, DocumentName, JobStatus | Format-Table -AutoSize } } catch { Write-Output 'Unable to retrieve print jobs.' }; Write-Output '' }"
echo.
pause
goto MENU

:MANAGEMENT
cls
echo Opening Print Management...
start "" printmanagement.msc
goto MENU

:SCANNER
cls
echo Opening Scanner Settings...
start "" "ms-settings:printers"
goto MENU


:REPAIR
cls
echo ================================
echo       FULL PRINTER SETTINGS
echo ================================
echo.

call :LOADPRINTERS
if errorlevel 1 goto MENU

call :SELECTPRINTER
if errorlevel 1 goto REPAIR

echo.
echo Opening properties for:
echo !selectedPrinter!
rundll32.exe printui.dll,PrintUIEntry /p /n "!selectedPrinter!"

pause
goto MENU

:LOADPRINTERS
set "printerFile=%temp%\micah_printers_%random%.txt"
set "printerCount=0"

powershell -NoProfile -Command "Get-Printer | Select-Object -ExpandProperty Name" > "!printerFile!" 2>nul

if not exist "!printerFile!" (
    echo Unable to retrieve installed printers.
    pause
    exit /b 1
)

for %%F in ("!printerFile!") do if %%~zF EQU 0 (
    echo No printers found.
    del "!printerFile!" 2>nul
    pause
    exit /b 1
)

echo Select a printer:
echo.

for /f "usebackq delims=" %%P in ("!printerFile!") do (
    set /a printerCount+=1
    echo !printerCount!. %%P
)

if !printerCount! EQU 0 (
    echo No printers found.
    del "!printerFile!" 2>nul
    pause
    exit /b 1
)

exit /b 0

:SELECTPRINTER
echo.
set "printerChoice="
set /p "printerChoice=Enter printer number (0 to cancel): "

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
    echo Invalid selection. Please try again.
    exit /b 1
)

exit /b 0


:CHECKADMIN
net session >nul 2>&1
if errorlevel 1 (
    echo Administrator privileges are required.
    echo Right-click the batch file and select
    echo "Run as administrator".
    echo.
    pause
    exit /b 1
)
exit /b 0
