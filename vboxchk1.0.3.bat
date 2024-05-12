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
    mkdir "c:\temp" 2>NUL
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
FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox" /v VersionExt') DO SET vboxv=%%B
FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox" /v InstallDir') DO SET vboxinstall=%%B

reg query HKLM\SOFTWARE\Oracle\VirtualBox Guest Additions >nul 2>&1
if %errorlevel% neq 0 (
    echo VirtualBox Guest addons not installed.
    goto SDKCHK
) else (
    echo VirtualBox Guest addons are installed.
)
if %vboxv%==%VER% then FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox" /v Versionext') DO SET vboxv=%%B

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

for /f "tokens=2*" %%i in ('systeminfo ^| findstr /B /C:"OS Name"') do set osname=%%j
echo %osname%

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

set scriptver=vboxchk1.0.3
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
set results_file="c:\temp\BMN%BMN%-%computername%-%datestamp%-%govclass%.txt"
echo %results_file%
echo please wait for the audit to finish should only tke less then 1  minutes .............
echo ***** Data classification set to %clss% ***** >> %results_file%

:tail
rem tail entries for ref.
(
echo ****************************************************************************************************** 
echo CPU information of host 
wmic cpu get name |more 
wmic computersystem get numberofprocessors |more 
wmic cpu get SocketDesignation, NumberOfCores, NumberOfLogicalProcessors |more 
echo ****************************************************************************************************** 
echo BMN Number: BMN%BMN%
echo ******************************************************************************************************
echo Host information
echo ******************************************************************************************************
echo Hostname: %computername% 
echo VM Host OS:%osname%
echo VirtualBox version: %vboxv%
echo VirtualBox Installation Directory: %vboxinstall%
echo ******************************************************************************************************
echo Virtualbox Installation date: 
for %%A in ("%vboxinstall%virtualbox.exe") do (
    dir /T:C "%%~fA" | findstr /R /C:"[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]"
)
echo ******************************************************************************************************
echo VirtualBox SDK "if installed)":  %vboxSDK%
echo Script version: %scriptver%
echo ******************************************************************************************************
echo Detailed Virtuakboxtualbox Extension Pack Check
"%vboxinstall%vboxmanage.exe" list extpacks
echo ******************************************************************************************************
echo Exstension Installation date: 
for %%A in ("%vboxinstall%ExtensionPacks\Oracle_VM_VirtualBox_Extension_Pack\ExtPack-license.txt") do (
    dir /T:C "%%~fA" 2>nul | findstr /R /C:"[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]"
)
echo ******************************************************************************************************
echo ******************************************************************************************************
echo Guest information
echo ******************************************************************************************************
echo Registered VM Check
"%vboxinstall%vboxmanage.exe" list vms
echo ******************************************************************************************************
for /f "tokens=2 delims={}" %%a in ('"%vboxinstall%vboxmanage.exe" list vms') do (
    echo VM UUID: %%a
    "%vboxinstall%vboxmanage.exe" showvminfo %%a --details | findstr /B /C:"Guest OS:" 
	"%vboxinstall%vboxmanage.exe" showvminfo %%a --details | findstr /B /C:"State:" 
	)
echo ******************************************************************************************************
echo User has classified the data as: %clss% 
echo ******************************************************************************************************
) 2>&1 >null >> %results_file%

rem reen view

echo ****************************************************************************************************** 
echo CPU information of host 
wmic cpu get name |more 
wmic computersystem get numberofprocessors |more 
wmic cpu get SocketDesignation, NumberOfCores, NumberOfLogicalProcessors |more 
echo ****************************************************************************************************** 
echo BMN Number: BMN%BMN%
echo ******************************************************************************************************
echo Host information
echo ******************************************************************************************************
echo Hostname: %computername% 
echo VM Host OS:%osname%
echo VirtualBox version: %vboxv%
echo VirtualBox Installation Directory: %vboxinstall%
echo ******************************************************************************************************
echo Virtualbox Installation date: 
for %%A in ("%vboxinstall%virtualbox.exe") do (
    dir /T:C "%%~fA" | findstr /R /C:"[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]"
)
echo ******************************************************************************************************
echo VirtualBox SDK "if installed)":  %vboxSDK%
echo Script version: %scriptver%
echo ******************************************************************************************************
echo Detailed Virtuakboxtualbox Extension Pack Check
"%vboxinstall%vboxmanage.exe" list extpacks
echo ******************************************************************************************************
echo Exstension Installation date: 
for %%A in ("%vboxinstall%ExtensionPacks\Oracle_VM_VirtualBox_Extension_Pack\ExtPack-license.txt") do (
    dir /T:C "%%~fA" 2>nul | findstr /R /C:"[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]"
)
echo ******************************************************************************************************
echo ******************************************************************************************************
echo Guest information
echo ******************************************************************************************************
echo Registered VM Check
"%vboxinstall%vboxmanage.exe" list vms
echo ******************************************************************************************************
for /f "tokens=2 delims={}" %%a in ('"%vboxinstall%vboxmanage.exe" list vms') do (
    echo VM UUID: %%a
    "%vboxinstall%vboxmanage.exe" showvminfo %%a --details | findstr /B /C:"Guest OS:"
	"%vboxinstall%vboxmanage.exe" showvminfo %%a --details | findstr /B /C:"State:"
	)
echo ******************************************************************************************************
echo User has classified the data as: %clss% 
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
:end
exit /b

:debug
color 1F

:Dtempfolder
if not exist "c:\temp" (
    mkdir "c:\temp" 2>NUL
    if errorlevel 1 (
        echo Failed to create directory. The script will now close.
        pause
        exit /b
    )
)

:Dsetlocl
setlocal enabledelayedexpansion

:Dadmincheck
rem Check if the user is running as admin (administrator)

>nul 2>&1 net session
if %errorlevel% == 0 (
set admin=Yes
echo User is running as administrator.
goto Dbegin
	) else (
    set admin=No
    echo WARNING: NOT running as administrator. The script now exit.
 	pause
	exit /b
 )

:Dbegin
mode 130


:DReportWarning
cls
color 1F

echo ******************************************************************************************************
echo VirtualBoxbox and Virtual Box Extension Pack Check Debug
echo ******************************************************************************************************
set "VBOX_REG_KEY=HKLM\SOFTWARE\Oracle\VirtualBox"
reg query HKLM\SOFTWARE\Oracle\VirtualBox >nul 2>&1
if %errorlevel% neq 0 (
    echo VirtualBox is not installed.
    goto Dcloseout
) else (
    echo VirtualBox is installed.
)

FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox" /v VersionExt') DO SET Dvboxv=%%B
FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox" /v InstallDir') DO SET Dvboxinstall=%%B

reg query HKLM\SOFTWARE\Oracle\VirtualBox Guest Additions >nul 2>&1
if %errorlevel% neq 0 (
    echo VirtualBox Guest addons not installed.
    goto DSDKCHK
) else (
    echo VirtualBox Guest addons are installed.
)
 

:DSDKCHK
reg query HKLM\SOFTWARE\Oracle\VirtualBox /v PythonApiInstallDir >nul 2>&1
if %errorlevel% neq 0 (
    echo VirtualBox SDK not installed.
    goto lookupOS
) else (
    echo VirtualBox SDK is installed.
)

FOR /F "tokens=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Oracle\VirtualBox" /v PythonApiInstallDir') DO SET DvboxSDK=%%B
rem lookup operating system 
:DlookupOS

for /f "tokens=2*" %%i in ('systeminfo ^| findstr /B /C:"OS Name"') do set osname=%%j
echo %osname%

:Dbit
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32BIT || set OS=64BIT
if %OS%==32BIT echo 32bit operating system
if %OS%==64BIT echo 64bit operating system 


rem endlocal
:Dscrptcondtions
set Dscriptver=vboxchk1.0.3-bebug
echo ******************************************************************************************************
set /p BMN="Please enter the BMN number as a numerical number only e.g. 1234: "
echo ******************************************************************************************************
echo Set Data classification Valid entries:O, OS, S, SUKEO, OCCAR-R, C1, C2, C3, C4
set /p govclass="Please set the classification of Data? "
echo ******************************************************************************************************

set scriptver=vboxchk1.0.3-debug_mode
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
    goto Dbegin
)
if /i "%govclass%"=="s" (
    set clss="SECRET"
    color 4F
)
 
if /i "%govclass%"=="sukeo" (
    set clss="SUKEO"
    color 4F
)
:Dfileset

set "datestamp=%date:~-4%%date:~-7,2%%date:~-10,2%-%time:~0,2%%time:~3,2%"
set Dresults_file="c:\temp\Debug-BMN%BMN%-%computername%-%datestamp%-%govclass%.txt"
echo %Dresults_file%
echo ***** Data classification set to %clss% ***** >> %Dresults_file%

:Dtail
rem tail entries for ref.
(
echo BMN Number: BMN%BMN%
echo ******************************************************************************************************
echo CPU information 
wmic cpu get name
wmic computersystem get numberofprocessors
wmic cpu get SocketDesignation, NumberOfCores, NumberOfLogicalProcessors
echo ******************************************************************************************************
echo Hostname: %computername% 
echo VM Host OS:%Dosversion% %Dosv%
echo VirtualBox  version: %Dvboxv%
echo VirtualBox Installation Directory: %Dvboxinstall%
echo VirtualBox  Guest adds "(if installed)": %Dguestadd%
echo VirtualBox SDK "if installed)":  %DvboxSDK%
echo VirtualBox Installation date: %Dinstalldate%
echo Script version: %Dscriptver%
echo ******************************************************************************************************
echo Detailed Virtuakboxtualbox Extension Pack Check
"%Dvboxinstall%vboxmanage.exe" list extpacks
echo ******************************************************************************************************
echo ******************************************************************************************************
echo Registered VM Check
"%Dvboxinstall%vboxmanage.exe" list vms
echo Detailed Information for Each VM
for /f "tokens=2 delims={}" %%a in ('"%Dvboxinstall%vboxmanage.exe" list vms') do (
    echo VM UUID: %%a
    "%Dvboxinstall%vboxmanage.exe" showvminfo %%a
	)
echo ******************************************************************************************************
echo ******************************************************************************************************
echo User has classified the data as: %clss% 
echo ******************************************************************************************************
) >> %Dresults_file%

REM Oncreen view

echo BMN Number: BMN%BMN%
echo ******************************************************************************************************
echo CPU information 
wmic cpu get name
wmic computersystem get numberofprocessors
wmic cpu get SocketDesignation, NumberOfCores, NumberOfLogicalProcessors
echo ******************************************************************************************************
echo Hostname: %computername% 
echo VM Host OS:%Dosversion% %Dosv%
echo VirtualBox  version: %Dvboxv%
echo VirtualBox Installation Directory: %Dvboxinstall%
echo VirtualBox  Guest adds "(if installed)": %Dguestadd%
echo VirtualBox SDK "if installed)":  %DvboxSDK%
echo VirtualBox Installation date: %Dinstalldate%
echo Script version: %Dscriptver%
echo ******************************************************************************************************
echo Detailed Virtuakboxtualbox Extension Pack Check
"%Dvboxinstall%vboxmanage.exe" list extpacks
echo ******************************************************************************************************
echo ******************************************************************************************************
echo Registered VM Check
"%Dvboxinstall%vboxmanage.exe" list vms
echo Detailed Information for Each VM
for /f "tokens=2 delims={}" %%a in ('"%Dvboxinstall%vboxmanage.exe" list vms') do (
    echo VM UUID: %%a
    "%Dvboxinstall%vboxmanage.exe" showvminfo %%a
	)
echo ******************************************************************************************************
echo ******************************************************************************************************
echo User has classified the data as: %clss% 
echo ******************************************************************************************************


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
    goto Dbegin
) else if /i "%rerun%"=="no" (
    goto Dend
) else (
    echo Error: Invalid choice. Please enter "yes" or "no".
	pause
    goto Dcloseout
)


:Dend

exit /b