@echo off
rem =============================================================================
rem =										=
rem =	Generation of pre-partition creation script				=
rem =										=
rem =	2018/04/22	Version 1.0						=
rem =										=
rem =	Copyright (c) 2018 Solomon Review [redemarrage] All Right Reserved	=
rem =										=
rem =	https://solomon-review.net/						=
rem =										=
rem =============================================================================

rem =============================================
rem =	Parameter settings			=
rem =============================================
set EFI_KEY=EFI-KEY
set RECOVERY_KEY=RECOVERY-KEY
set DATA_KEY=DATA-KEY
set SYSTEM_SCRIPT_FILE=Create-Partitions-System-v2.txt
set DATA_SCRIPT_FILE=Create-Partitions-with-Data-v2.txt
set DATA_MS_SCRIPT_FILE=Create-Partitions-with-Data-MS-v2.txt
set OUT_SCRIPT_FILE=Create-Partitions-EFI.txt
set TEMP_FILE=tmp.txt
set EXECUTE_BAT_FILE=Divide-Partitions-v2.bat

rem =============================================
rem =	Specifying the size of the EFI partition=
rem =============================================
:ASK_EFI_SIZE
echo.
echo Please select the size of the EFI partition
set EFI_SIZE=
set /P EFI_SIZE="1: Standard (100MB) 2: 4KB sector (260MB) (Default is 1):"
IF "%EFI_SIZE%" == "1" (
	set EFI_SIZE=100
	GOTO :ASK_RECOVERY_SIZE
)
IF "%EFI_SIZE%" == "2" (
	set EFI_SIZE=260
	GOTO :ASK_RECOVERY_SIZE
)
IF "%EFI_SIZE%" == "" (
	set EFI_SIZE=100
	GOTO :ASK_RECOVERY_SIZE
)
echo.
echo [ERROR] Please correctly select the size of the EFI partition.
GOTO :ASK_EFI_SIZE

rem =============================================
rem =	Specifying the size of the recovery partition=
rem =============================================
:ASK_RECOVERY_SIZE
echo.
set RECOVERY_SIZE_MB=
set /P RECOVERY_SIZE_MB="Please specify the recovery partition size in MB. (Default is 1024):"
IF "%RECOVERY_SIZE_MB%" == "" set RECOVERY_SIZE_MB=1024
set /A RECOVERY_SIZE=%RECOVERY_SIZE_MB% * 1
IF %RECOVERY_SIZE% LEQ 0 (
	echo.
	echo [ERROR] Please correctly specify the size of the recovery partition.
	GOTO :ASK_RECOVERY_SIZE
)
echo A recovery partition will be created with [%RECOVERY_SIZE%MB].

rem =============================================
rem =	Confirm whether to divide the data partition=
rem =============================================
:ASK_DATA
echo.
set MAKE_DATA=
set /P MAKE_DATA="Do you want to separate the data partition? Y/N:"
IF "%MAKE_DATA%" == "Y" (
	set MAKE_DATA=Y
	GOTO :ASK_DATA_TYPE
)
IF "%MAKE_DATA%" == "y" (
	set MAKE_DATA=Y
	GOTO :ASK_DATA_TYPE
)
IF "%MAKE_DATA%" == "N" (
	set MAKE_DATA=N
	GOTO :MAKE_SCRIPT
)
IF "%MAKE_DATA%" == "n" (
	set MAKE_DATA=N
	GOTO :MAKE_SCRIPT
)
echo.
echo [ERROR] Please specify whether to separate or not.
GOTO :ASK_DATA

rem =============================================
rem =	Type of data partition configuration	=
rem =============================================
:ASK_DATA_TYPE
echo.
echo There are two types of data partition configurations
echo 1: Site recommended version: [Windows][Data][Recovery]
echo 2: Microsoft recommended version: [Windows][Recovery][Data]
set DATA_TYPE=
set /P DATA_TYPE="Which type do you want? 1: Site recommended version 2: Microsoft recommended version (Default is 1):"
IF "%DATA_TYPE%" == "1" (
	set DATA_TYPE=ORIGINAL
	echo Configuring the data partition in [Site recommended version].
	GOTO :ASK_SYSTEM_SIZE
)
IF "%DATA_TYPE%" == "2" (
	set DATA_TYPE=MICROSOFT
	echo Configuring the data partition in [Microsoft recommended version].
	GOTO :ASK_SYSTEM_SIZE
)
IF "%DATA_TYPE%" == "" (
	set DATA_TYPE=ORIGINAL
	echo Configuring the data partition in [Site recommended version].
	GOTO :ASK_SYSTEM_SIZE
)
echo.
echo [ERROR] Please correctly specify the data partition configuration.
GOTO :ASK_DATA_TYPE

rem =============================================
rem =	Specifying the size of the data partition=
rem =============================================
:ASK_SYSTEM_SIZE
echo.
echo Specify the size of the Windows system partition,
echo and the remainder will be used for the data partition.
set SYSTEM_SIZE_GB=
set /P SYSTEM_SIZE_GB="Please specify the Windows system partition size in GB. (Default is 80):"
IF "%SYSTEM_SIZE_GB%" == "" set SYSTEM_SIZE_GB=80
set /A SYSTEM_SIZE=%SYSTEM_SIZE_GB% * 1024
IF %SYSTEM_SIZE% LEQ 0 (
	echo.
	echo [ERROR] Please correctly specify the size of the Windows system partition.
	GOTO :ASK_SYSTEM_SIZE
)
echo Creating the Windows system partition with [%SYSTEM_SIZE%MB].

rem =============================================
rem =	Creating the DISKPART script		=
rem =============================================
:MAKE_SCRIPT
echo.
echo Creating the DISKPART script.
IF %MAKE_DATA%==N (
	set IN_SCRIPT_FILE=%SYSTEM_SCRIPT_FILE%
	GOTO :MAKE_SCRIPT_1
)
IF %DATA_TYPE%==ORIGINAL set IN_SCRIPT_FILE=%DATA_SCRIPT_FILE%
IF %DATA_TYPE%==MICROSOFT set IN_SCRIPT_FILE=%DATA_MS_SCRIPT_FILE%

:MAKE_SCRIPT_1
setlocal ENABLEDELAYEDEXPANSION
type nul >%TEMP_FILE%
FOR /F "delims=" %%A in (%IN_SCRIPT_FILE%) DO (
    set LINE=%%A
    echo !LINE:%EFI_KEY%=%EFI_SIZE%!>>%TEMP_FILE%
)
type nul >%OUT_SCRIPT_FILE%
FOR /F "delims=" %%A in (%TEMP_FILE%) DO (
    set LINE=%%A
    echo !LINE:%RECOVERY_KEY%=%RECOVERY_SIZE%!>>%OUT_SCRIPT_FILE%
)
ENDLOCAL
del %TEMP_FILE% >nul 2>&1

IF %MAKE_DATA%==N GOTO :ASK_EXECUTE_SCRIPT

setlocal ENABLEDELAYEDEXPANSION
rename %OUT_SCRIPT_FILE% %TEMP_FILE% >nul 2>&1
type nul >%OUT_SCRIPT_FILE%
FOR /F "delims=" %%A in (%TEMP_FILE%) DO (
    set LINE=%%A
    echo !LINE:%DATA_KEY%=%SYSTEM_SIZE%!>>%OUT_SCRIPT_FILE%
)
ENDLOCAL
del %TEMP_FILE% >nul 2>&1

rem =============================================
rem =	Immediate execution of the script	=
rem =============================================
:ASK_EXECUTE_SCRIPT
echo.
echo DISKPART script [%OUT_SCRIPT_FILE%] has been created.
echo.
set EXECUTE_NOW=
set /P EXECUTE_NOW="Do you want to create the partition now? Y: Create N: Do not create:"
IF "%EXECUTE_NOW%" == "Y" GOTO :RECONFIRM
IF "%EXECUTE_NOW%" == "y" GOTO :RECONFIRM
GOTO :SCRIPT_END

:RECONFIRM
set EXECUTE_NOW=
set /P EXECUTE_NOW="Are you sure? Y: Create N: Do not create:"
IF "%EXECUTE_NOW%" == "Y" GOTO :EXECUTE_SCRIPT
IF "%EXECUTE_NOW%" == "y" GOTO :EXECUTE_SCRIPT
GOTO :SCRIPT_END

:EXECUTE_SCRIPT
echo on
diskpart /S %OUT_SCRIPT_FILE%
echo off

rem =============================================
rem =	End of script creation			=
rem =============================================
:SCRIPT_END
echo.
echo Please copy [%OUT_SCRIPT_FILE%] and [%EXECUTE_BAT_FILE%] to the installation USB memory and use them.
echo.
