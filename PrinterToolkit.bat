
@echo off
setlocal EnableExtensions
title Micah's Printer Toolkit
color 0B

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

if "%choice%"=="1" goto VIEW
if "%choice%"=="2" goto SETTINGS
if "%choice%"=="3" goto SPOOLER
if "%choice%"=="4" goto CLEAR
if "%choice%"=="5" goto DEVICES
if "%choice%"=="6" goto TEST
if "%choice%"=="7" goto STATUS
if "%choice%"=="8" goto MANAGEMENT
if "%choice%"=="9" goto SCANNER
if "%choice%"=="10" goto REPAIR
if "%choice%"=="11" exit /b

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
if errorlevel 1 echo Unable to retrieve printers.
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
    echo Try running this toolkit as Administrator.
    pause
    goto MENU
)

echo.
echo Starting Print Spooler...
net start spooler
if errorlevel 1 (
    echo.
    echo Failed to start the Print Spooler.
    echo Try running: net start spooler
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
if /i not "%confirm%"=="Y" goto MENU

echo.
echo Stopping Print Spooler...
net stop spooler
if errorlevel 1 (
    echo.
    echo Could not stop the Print Spooler.
    echo No queue files were intentionally deleted.
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
    echo.
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
echo Installed printers:
powershell -NoProfile -Command "Get-Printer | Select-Object -ExpandProperty Name"
echo.
set "printer="
set /p "printer=Enter the exact printer name: "

if not defined printer (
    echo No printer name entered.
    pause
    goto MENU
)

echo.
echo Sending test page to: %printer%
rundll32.exe printui.dll,PrintUIEntry /k /n "%printer%"

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
if errorlevel 1 (
    echo.
    echo Print Management may not be installed
    echo in your edition of Windows.
    pause
)
goto MENU


:SCANNER
cls
echo Opening Printers and Scanners settings...
start "" "ms-settings:printers"
goto MENU


:REPAIR
cls
echo ================================
echo       FULL PRINTER SETTINGS
echo ================================
echo.
echo Installed printers:
powershell -NoProfile -Command "Get-Printer | Select-Object -ExpandProperty Name"
echo.
set "printer="
set /p "printer=Enter the exact printer name: "

if not defined printer (
    echo No printer name entered.
    pause
    goto MENU
)

echo.
echo Opening printer properties...
rundll32.exe printui.dll,PrintUIEntry /p /n "%printer%"
pause
goto MENU


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