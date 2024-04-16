@echo off

rem Check if /debug switch is used
if "%1" == "/legacy" (
    goto legacy
)

rem Check if /debug switch is used
if "%1" == "/debug" (
    goto debug
)

rem Check if /debug switch is used
if "%1" == "/noadmin" (
    goto noadminset
)

:tempfolder
if not exist "c:\temp" (
    mkdir "cF:\temp" 2>NUL
    if errorlevel 1 (
        echo Failed to create directory. The script will now close.
        pause
        exit /b
    )
)


:setlocl
setlocal enabledelayedexpansion

:admincheck
REM Check if the user is running as admin (administrator)
>nul 2>&1 net session
if %errorlevel% == 0 (
    set admin=Yes
    echo User is running as administrator.
	goto begin
) else (
    set admin=No
    echo WARNING: NOT running as administrator. The script now exit.
	pause
	exit /b
)

:legacy
set DESKTOP_PATH=c:\temp
set llog=%computername%_vbox_leagavymode.txt
cls
set /p DR="Select which drive to scan. ONLY ENTER THE LETTER:
echo Running in legacy mode. Please wait...
dir /s /b %DR%:\VBoxManage.exe >c:\temp\%llog%
pause
echo Legacy mode finished searching %DR%: Please review the c:\temp\%llog% file
set /p rerunleg="Do you want to rerun the script? (yes/no): "
if /i "%rerunleg%"=="yes" goto legacy
exit /b
:noadminset
:begin
mode 130


:ReportWarning
cls
color 0F
echo ******************************************************************************************************
echo VirtualBoxbox and Virtual Box Extension Pack Check
echo ******************************************************************************************************
reg query HKLM\SOFTWARE\Oracle\VirtualBox >nul 2>&1
if %errorlevel% neq 0 (
    echo VirtualBox is not installed.
    goto closeout
) else (
    echo VirtualBox is installed.
)
FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox" /v Version') DO SET vboxv=%%B
FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox" /v InstallDir') DO SET vboxinstall=%%B

reg query HKLM\SOFTWARE\Oracle\VirtualBox Guest Additions >nul 2>&1
if %errorlevel% neq 0 (
    echo VirtualBox Guest addons not installed.
    goto SDKCHK
) else (
    echo VirtualBox Guest addons are installed.
)
 
FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox Guest Additions" /v InstallDir') DO SET guestadd=%%B

:SDKCHK
reg query HKLM\SOFTWARE\Oracle\VirtualBox /v PythonApiInstallDir >nul 2>&1
if %errorlevel% neq 0 (
    echo VirtualBox SDK not installed.
    goto lookupOS
) else (
    echo VirtualBox SDK is installed.
)

FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox" /v PythonApiInstallDir') DO SET vboxSDK=%%B

rem lookup operating system 
:lookupOS

:xp
systeminfo | findstr /B /C:"OS Name" > %temp%\osname.txt
find /I "XP" %temp%\osname.txt > nul
if %ERRORLEVEL% EQU 0 (
    set osv=5.1 Windows XP
) else (
    goto nextver
)

:nextver

for /f "tokens=4-5 delims=. " %%i in ('ver') do (
    if "%%i.%%j"=="10.0" (
        set osv=Windows 10-11\20XX
    ) else if "%%i.%%j"=="6.3" (
        set osv=Windows 8.1\2012R2
    ) else if "%%i.%%j"=="6.2" (
        set osv=Windows 8\2012
    ) else if "%%i.%%j"=="6.1" (
        set osv=Windows 7\win2k8 R2
    ) else if "%%i.%%j"=="6.0" (
        set osv=Windows Vista\win2k8
    ) else if "%%i.%%j"=="5.2" (
        set osv=Windows win2k3
    )
)

if defined osv (
    echo %osv%
) else (
    echo Unknown Operating System
)

:bit
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32BIT || set OS=64BIT
if %OS%==32BIT echo 32bit operating system
if %OS%==64BIT echo 64bit operating system 


rem endlocal
:scrptcondtions
echo ******************************************************************************************************
set /p BMN="Please enter the BMN number as a numerical number only e.g. 1234: "
echo ******************************************************************************************************
echo Set Data classification Valid entries:O, OS, S, SUKEO, OCCAR-R, C1, C2, C3, C4
set /p govclass="Please set the classification of Data? "
echo ******************************************************************************************************

set scriptver=vboxchk1.0.1
if /i "%govclass%"=="o" (
    set clss="OFFICIAL"
) else if /i "%govclass%"=="os" (
    set clss="OFFICIAL SENSITIVE"
) else if /i "%govclass%"=="s" (
    set clss="SECRET"
) else if /i "%govclass%"=="sukeo" (
    set clss="SUKEO"
) else if /i "%govclass%"=="occar-r" (
    set clss="OCCAR-RESCRICTED"
) else if /i "%govclass%"=="c1" (
    set clss="C1:OPEN DESIGNED TO BE SHARED PUBLICLY"
) else if /i "%govclass%"=="c2" (
    set clss="C2:GROUP LIMITED DISTRIBUTION"
) else if /i "%govclass%"=="c3" (
    set clss="C3:GROUP CONFIDENTIAL- SENSITIVE INFORMATION"
) else if /i "%govclass%"=="c4" (
    set clss="C4:GROUP SECRET- EXTREMELY SENSITIVE INFORMATION"
) else (
    echo Not a valid answer. Please try again.
    timeout /t 2 >nul
    cls
    goto begin
)
if /i "%govclass%"=="s" (
    set clss="SECRET"
    color 4F
)
 
if /i "%govclass%"=="sukeo" (
    set clss="SUKEO"
    color 4F
)
:fileset

set "datestamp=%date:~-4%%date:~-7,2%%date:~-10,2%-%time:~0,2%%time:~3,2%"
set "results_file="c:\temp\BMN%BMN%-%computername%-%datestamp%-%govclass%.txt"
echo %results_file%
echo ***** Data classification set to %clss% ***** >> %results_file%

:tail
rem tail entries for ref.
(
echo ******************************************************************************************************
echo BMN Number: BMN%BMN%
echo Hostname: %computername% 
wmic computersystem get numberofprocessors
wmic cpu get SocketDesignation, NumberOfCores, NumberOfLogicalProcessors 
echo VM Host OS:%osversion% %osv%
echo VitualBox version: %vboxv%
echo VitualBox Installation Directory: %vboxinstall%
echo VitualBox Guest addons "(if installed)": %guestadd%
echo VitualBox SDK "if installed)":  %vboxSDK%
echo Script version: %scriptver%
echo ******************************************************************************************************
echo Deatailed Virtuakboxtualbox Extension Pack Check
"%vboxinstall%vboxmanage.exe" list extpacks
echo ******************************************************************************************************
echo Registered VM Check
"%vboxinstall%vboxmanage.exe" list vms
echo ******************************************************************************************************
echo User gas classified the data as: %clss% 
echo ******************************************************************************************************
) >> %results_file%

echo BMN Number: BMN%BMN%
wmic computersystem get numberofprocessors
wmic cpu get SocketDesignation, NumberOfCores, NumberOfLogicalProcessors
echo Hostname: %computername% 
echo VM Host OS:%osversion% %osv%
echo VitualBox version: %vboxv%
echo VitualBox Installation Directory: %vboxinstall%
echo VitualBox Guest adds "(if installed)": %guestadd%
echo VitualBox SDK "if installed)":  %vboxSDK%
echo Script version: %scriptver%
echo ******************************************************************************************************
echo Detailed Virtuakboxtualbox Extension Pack Check
"%vboxinstall%vboxmanage.exe" list extpacks
echo ******************************************************************************************************
echo Registered VM Check
"%vboxinstall%vboxmanage.exe" list vms
echo ******************************************************************************************************
echo User gas classified the data as: %clss% 
echo ******************************************************************************************************

:closeout
REM Prompt user for rerun choice
set /p rerun="Do you want to rerun the script? (yes/no): "

REM Check if input is not empty
if "%rerun%"=="" (
    echo Error: You must provide a choice.
    goto closeout
)

REM Check if input is "yes" or "no"
if /i "%rerun%"=="yes" (
    goto begin
) else if /i "%rerun%"=="no" (
    goto end
) else (
    echo Error: Invalid choice. Please enter "yes" or "no".
	pause
    goto closeout
)


:debug

:admincheck
REM Check if the user is running as admin (administrator)
>nul 2>&1 net session
if %errorlevel% == 0 (
    set admin=Yes
    echo User is running as administrator.
    goto begindebug
) else (
    set admin=No
    echo WARNING: NOT running as administrator. The script will now exit.
    pause
    exit /b
)
:begindebug
@echo off
cls
color 1F
setlocal enabledelayedexpansion

:: Set file paths and timestamps
set "datestamp=%date:~-4%%date:~-7,2%%date:~-10,2%-%time:~0,2%%time:~3,2%"
set "Dresults_file=c:\temp\\Desktop\VirtualBox_chk_Debug-%computername%-%datestamp%.txt"
set Dscriptver=vboxchk1.0.0-debug-mode

:: Export registry keys to variables
FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox" /v Version') DO SET Dvboxv=%%B
FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox" /v InstallDir') DO SET Dvboxinstall=%%B
FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox Guest Additions" /v InstallDir') DO SET Dguestadd=%%B
FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox" /v PythonApiInstallDir') DO SET DvboxSDK=%%B

:: Detect OS version
for /f "tokens=5-6 delims=[." %%i in ('ver') do (
    if "%%i.%%j"=="Version 5" (
        set osv=Windows XP
    )
)

for /f "tokens=4-5 delims=. " %%i in ('ver') do (
    if "%%i.%%j"=="10.0" (
        set osv=Windows 10-11\20XX
    ) else if "%%i.%%j"=="6.3" (
        set osv=Windows 8.1\2012R2
    ) else if "%%i.%%j"=="6.2" (
        set osv=Windows 8\2012
    ) else if "%%i.%%j"=="6.1" (
        set osv=Windows 7\win2k8 R2
    ) else if "%%i.%%j"=="6.0" (
        set osv=Windows Vista\win2k8
    ) else if "%%i.%%j"=="5.2" (
        set osv=Windows win2k3
    )
)

:: Detect OS architecture
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set DOS=32BIT || set DOS=64BIT

:: Output to console and log to file
(
echo Hostname: %computername% 
echo VM Host OS:%osv% %DOS%
echo VitualBox version: %Dvboxv%
echo VitualBox Installation Directory: %Dvboxinstall%
echo VitualBox Guest adds "(if installed)": %Dguestadd%
echo VitualBox SDK "if installed)":  %DvboxSDK%
echo Script version: %Dscriptver%
echo ******************************************************************************************************
echo Detailed VirtualBox Extension Pack Check
"%Dvboxinstall%vboxmanage.exe" list extpacks
echo ******************************************************************************************************
echo Registered VMS
"%Dvboxinstall%vboxmanage.exe" list vms
echo ******************************************************************************************************
echo ******************************************************************************************************
echo Detailed Information for Each VM
for /f "tokens=2 delims={}" %%a in ('"%Dvboxinstall%vboxmanage.exe" list vms') do (
    echo VM UUID: %%a
    "%Dvboxinstall%vboxmanage.exe" showvminfo %%a
echo ******************************************************************************************************
)
echo ******************************************************************************************************
echo Virtualbox properties
set filepath=%Dvboxinstall%virtualbox.exe
for /f "tokens=1,* delims==" %%p in ('wmic datafile where "name='!filepath:\=\\!'" get /format:list ^| find "="') do (
    echo Found file property: %%p=%%q
    set file_property_name=%%p
    set file_property_value=%%q
)
echo ******************************************************************************************************
echo VBoxManage properties
set filepath=%Dvboxinstall%vboxmanage.exe
for /f "tokens=1,* delims==" %%p in ('wmic datafile where "name='!filepath:\=\\!'" get /format:list ^| find "="') do (
    echo Found file property: %%p=%%q
    set file_property_name=%%p
    set file_property_value=%%q
)

echo ******************************************************************************************************
echo Virtualbox File property version: %proptyv%
echo ******************************************************************************************************
echo summary data 
echo Hostname: %computername% 
echo VM Host OS:%osv% %DOS%
echo VitualBox version, as seen in the registery: %Dvboxv%
echo VirtuakboxtualBox Installation Directory: %Dvboxinstall%
echo Virtualbox Extension Pack as seen in the registery: %Dvboxextp%
echo VirtualBox Guest adds "(if installed)": %Dguestadd%
echo VirtualBox SDK "(if installed)":  %DvboxSDK%
echo Script version: %Dscriptver%
) > "%Dresults_file%"

:: Output to screen
type "%Dresults_file%"

:Dcloseout
REM Prompt user for rerun choice
set /p rerun="Do you want to rerun the script? (yes/no): "

REM Check if input is not empty
if "%rerun%"=="" (
    echo Error: You must provide a choice.
    goto Dcloseout
)

REM Check if input is "yes" or "no"
if /i "%rerun%"=="yes" (
    goto debug
) else if /i "%rerun%"=="no" (
    goto :end
) else (
    echo Error: Invalid choice. Please enter "yes" or "no".
	pause
    goto Dcloseout
)
:9x
echo results > win9x_vbox_search.txt
dir /s /b c:\virtualbox.exe

pause

:end
exit /b
