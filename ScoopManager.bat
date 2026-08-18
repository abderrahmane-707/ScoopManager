@echo off
setlocal enabledelayedexpansion

:: Initialize
set "PROGS_COUNT=26"
set "BUCKET_COUNT=9"
set "ON=(YES)"
set "OFF=(NO)"

:: Check external 7z once at startup
call :WHERE_7Z

:: Initialize programs/bucket
call :INIT_NAMES

:: Main interface
:SCOOP_MENU
cls
echo.
echo                                                 \\!//
echo                                                 (o o)
echo              -------------------------------oOOo-(_)-oOOo-------------------------------
echo                                        Scoop Software Installer
echo              ---------------------------------------------------------------------------
echo.

set /a "ROWS=(PROGS_COUNT+2)/3"
for /L %%r in (1,1,!ROWS!) do (
    set /a "c1=%%r"
    set /a "c2=%%r+!ROWS!"
    set /a "c3=%%r+!ROWS!*2"
    set "col1=" & set "col2=" & set "col3="
    if !c1! leq %PROGS_COUNT% call :FORMAT_ITEM !c1! OPT NAME col1
    if !c2! leq %PROGS_COUNT% call :FORMAT_ITEM !c2! OPT NAME col2
    if !c3! leq %PROGS_COUNT% call :FORMAT_ITEM !c3! OPT NAME col3
    call :PRINT_ROW "!col1!" "!col2!" "!col3!"
)

echo.
echo    [U] Update Programs
echo    [R] Remove Programs
echo    [B] Manage Buckets
echo    [M] More
echo.
echo              ---------------------------------------------------------------------------
echo.
echo                    [A] Select All            [D] Deselect All            [0] Exit
echo.

echo Tip: You can select multiple items, e.g. 1,3,5 or 1-5 or 1-3,7,10-12
echo. & set "choice=" & set /p "choice=--> Select option(s) and press [S] to Start: "

if "%choice%"=="" goto SCOOP_MENU
if "%choice%"=="0" exit /b
if /i "%choice%"=="S" goto RUN_PROGRAMS
if /i "%choice%"=="A" (call :SELECT_ALL_PROGS & goto SCOOP_MENU)
if /i "%choice%"=="D" (call :DESELECT_ALL_PROGS & goto SCOOP_MENU)
if /i "%choice%"=="U" goto UPDATE_MENU
if /i "%choice%"=="R" goto REMOVE_MENU
if /i "%choice%"=="B" goto BUCKET_MENU
if /i "%choice%"=="M" goto MORE_PROG

call :MULTI_INPUT OPT %PROGS_COUNT%
goto SCOOP_MENU

:RUN_PROGRAMS
cls
:: Collect every selected program into a single list, then process it in one call
set "toInstall="
for /L %%i in (1,1,%PROGS_COUNT%) do (
    if "!OPT%%i!"=="%ON%" set "toInstall=!toInstall! !NAME%%i!"
)

if not defined toInstall (
    echo. & echo No programs selected
    call :GO & goto SCOOP_MENU
)

echo Installing the following packages:
for %%P in (!toInstall!) do echo     - %%P

echo. & call scoop install -k !toInstall!
call :GO & call :DESELECT_ALL_PROGS & goto SCOOP_MENU

:UPDATE_MENU
cls & echo Checking available updates
call scoop update && call scoop status

call :PRINT_ACTION_PROMPT "update"

set "choice=" & set /p "choice=--> "
if "%choice%"=="" goto UPDATE_MENU
if "%choice%"=="0" goto SCOOP_MENU

call :PKG_BULK_ACTION "upgrade"
call :GO & goto SCOOP_MENU

:REMOVE_MENU
cls
call scoop list

call :PRINT_ACTION_PROMPT "remove"

set "choice=" & set /p "choice=--> "

if "%choice%"=="" goto REMOVE_MENU
if "%choice%"=="0" goto SCOOP_MENU

call :PKG_BULK_ACTION "uninstall"
call :GO & goto SCOOP_MENU

:MORE_PROG
cls & set "apps=" & set /p apps="Enter app name(s) separated by spaces: "
if "%apps%"=="" goto MORE_PROG

call scoop install -k %apps%
call :GO & goto SCOOP_MENU

:BUCKET_MENU
cls & echo.
echo                                                 \\!//
echo                                                 (o o)
echo              -------------------------------oOOo-(_)-oOOo-------------------------------
echo                                             Scoop Buckets
echo              ---------------------------------------------------------------------------
echo.

set /a "BROWS=(BUCKET_COUNT+2)/3"
for /L %%r in (1,1,!BROWS!) do (
    set /a "c1=%%r"
    set /a "c2=%%r+!BROWS!"
    set /a "c3=%%r+!BROWS!*2"
    set "col1=" & set "col2=" & set "col3="
    if !c1! leq %BUCKET_COUNT% call :FORMAT_ITEM !c1! BOPT BUCKET col1
    if !c2! leq %BUCKET_COUNT% call :FORMAT_ITEM !c2! BOPT BUCKET col2
    if !c3! leq %BUCKET_COUNT% call :FORMAT_ITEM !c3! BOPT BUCKET col3
    call :PRINT_ROW "!col1!" "!col2!" "!col3!"
)

echo.
echo    [U] Update Buckets
echo    [R] Remove Buckets
echo.
echo              ---------------------------------------------------------------------------
echo.
echo                    [A] Select All            [D] Deselect All            [0] Back
echo.

echo Tip: You can select multiple items, e.g. 1,3,5 or 1-5 or 1-3,7,10-12
echo. & set "choice=" & set /p "choice=--> Select option(s) and press [S] to Start: "

if "%choice%"=="" goto BUCKET_MENU
if "%choice%"=="0" goto SCOOP_MENU
if /i "%choice%"=="A" (call :SELECT_ALL_BUCKETS & goto BUCKET_MENU)
if /i "%choice%"=="D" (call :DESELECT_ALL_BUCKETS & goto BUCKET_MENU)
if /i "%choice%"=="U" goto UPDATE_BUCKETS
if /i "%choice%"=="S" goto ADD_BUCKETS
if /i "%choice%"=="R" goto REMOVE_BUCKETS

call :MULTI_INPUT BOPT %BUCKET_COUNT%
goto BUCKET_MENU

:ADD_BUCKETS
cls
set "toAddBuckets="
for /L %%i in (1,1,%BUCKET_COUNT%) do (
    if "!BOPT%%i!"=="%ON%" set "toAddBuckets=!toAddBuckets! !BUCKET%%i!"
)

if not defined toAddBuckets (
    echo No buckets selected
    call :GO & goto BUCKET_MENU
)

echo Adding the following buckets:
for %%B in (!toAddBuckets!) do echo     - %%B

echo. & for %%B in (!toAddBuckets!) do call scoop bucket add %%B
call :GO & call :DESELECT_ALL_BUCKETS & goto BUCKET_MENU

:UPDATE_BUCKETS
cls & echo Updating all Buckets
call scoop update
call :GO & goto BUCKET_MENU

:REMOVE_BUCKETS
cls & echo Added buckets
call scoop bucket list

call :PRINT_ACTION_PROMPT "remove"

set "choice=" 
set /p "choice=--> "
if not defined choice goto REMOVE_BUCKETS
set "choice=!choice:"=!"

if "!choice!"=="0" goto BUCKET_MENU

if /i "!choice!"=="ALL" (
    echo. & echo Removing all Added buckets
    for /f "skip=2 tokens=1" %%B in ('call scoop bucket list 2^>nul') do (
        if not "%%B"=="" (
            echo Removing bucket: %%B
            call scoop bucket rm %%B
        )
    )
) else (
    for %%G in (!choice:,= !) do (
        echo. & echo Removing bucket: %%G
        call scoop bucket rm %%G
    )
)

call :GO & goto BUCKET_MENU

:MULTI_INPUT
set "prefix=%~1"
set "max_count=%~2"
set "invalid="
set "tokens=!choice:,= !"

for %%G in (%tokens%) do (
    set "tok=%%G"
    set "matched=0"
    set "noHyphen=!tok:-=!"

    if not "!tok!"=="!noHyphen!" (
        set "rangeStart=" & set "rangeEnd="
        for /f "tokens=1,2 delims=-" %%X in ("!tok!") do (
            set "rangeStart=%%X"
            set "rangeEnd=%%Y"
        )
        set "isNum1=1" & for /f "delims=0123456789" %%C in ("!rangeStart!") do set "isNum1=0"
        set "isNum2=1" & for /f "delims=0123456789" %%C in ("!rangeEnd!") do set "isNum2=0"

        if defined rangeStart if defined rangeEnd if "!isNum1!!isNum2!"=="11" (
            if !rangeStart! geq 1 if !rangeEnd! leq !max_count! if !rangeStart! leq !rangeEnd! (
                for /L %%N in (!rangeStart!,1,!rangeEnd!) do call :TOGGLE_SINGLE %prefix%%%N
                set "matched=1"
            )
        )
    ) else (
        set "isNum=1" & for /f "delims=0123456789" %%C in ("!tok!") do set "isNum=0"
        if "!isNum!"=="1" if defined tok (
            if !tok! geq 1 if !tok! leq !max_count! (
                call :TOGGLE_SINGLE %prefix%!tok!
                set "matched=1"
            )
        )
    )

    if "!matched!"=="0" set "invalid=!invalid! !tok!"
)

if defined invalid (
    echo. & echo Invalid or out-of-range input:!invalid!
    pause
)
goto :eof

:SELECT_ALL_PROGS
for /L %%i in (1,1,%PROGS_COUNT%) do set "OPT%%i=%ON%"
goto :eof

:DESELECT_ALL_PROGS
for /L %%i in (1,1,%PROGS_COUNT%) do set "OPT%%i=%OFF%"
goto :eof

:SELECT_ALL_BUCKETS
for /L %%i in (1,1,%BUCKET_COUNT%) do set "BOPT%%i=%ON%"
goto :eof

:DESELECT_ALL_BUCKETS
for /L %%i in (1,1,%BUCKET_COUNT%) do set "BOPT%%i=%OFF%"
goto :eof

:PRINT_ACTION_PROMPT
echo.
echo --------------------------------------------------------------------------------
echo Type ALL to %~1 everything
echo Or type the exact name(s) as shown above, separated by commas
echo Type 0 to go back
echo --------------------------------------------------------------------------------
goto :eof

:: %1 = the specific variable name to toggle (e.g. OPT3, BOPT5)
:TOGGLE_SINGLE
if "!%~1!"=="%ON%" (set "%~1=%OFF%") else (set "%~1=%ON%")
goto :eof

:FORMAT_ITEM
set "%~4=  [%~1] !%~3%~1!"
if "!%~2%~1!"=="%ON%" set "%~4=* [%~1] !%~3%~1!"
set "%~4=!%~4!                          "
set "%~4=!%~4:~0,25!"
goto :eof

:: Prints one menu row made of up to 3 pre-formatted column labels
:PRINT_ROW
echo                  %~1%~2%~3
goto :eof

:PKG_BULK_ACTION
set "bulkAction=%~1"
if /i "!choice!"=="ALL" (
    if /i "%bulkAction%"=="upgrade" (
        echo Updating all programs
        call scoop update -k * && call scoop cleanup *
    ) else (
        echo Removing all programs
        set "toRemove="
        for /f "skip=2 tokens=1" %%P in ('call scoop list 2^>nul') do (
            if not "%%P"=="" set "toRemove=!toRemove! %%P"
        )
        if defined toRemove (
            call scoop uninstall !toRemove! --purge
        )
    )
) else (
    :: Collect every requested name into one list, then process it in a single call
    set "targets=!choice:,= !"
    echo. & echo Processing: !targets!
    if /i "%bulkAction%"=="upgrade" (
        call scoop update -k !targets! && call scoop cleanup !targets!
    ) else (
        call scoop uninstall !targets! --purge
    )
)
goto :eof

:WHERE_7Z
where 7z.exe >nul 2>&1
if %errorlevel% equ 0 (
    call scoop config use_external_7zip true >nul 2>&1
) else (
    call scoop config use_external_7zip false >nul 2>&1
)
goto :eof

:INIT_NAMES
:: Compilers & Toolchains
set "NAME1=gcc"
set "NAME2=llvm"

:: Static Analysis & Tools
set "NAME3=gdb"
set "NAME4=cppcheck"

:: Build Systems & Automation
set "NAME5=cmake"
set "NAME6=make"
set "NAME7=ninja"

:: Version Control (Git Tools)
set "NAME8=git"
set "NAME9=gh"
set "NAME10=sourcegit"
set "NAME11=lazygit"
set "NAME12=delta"

:: Code & Text Editors
set "NAME13=vscode"
set "NAME14=neovim"
set "NAME15=micro"

:: CLI File Managers, Search & Navigation
set "NAME16=yazi"
set "NAME17=ripgrep"
set "NAME18=fd"
set "NAME19=fzf"
set "NAME20=tre-command"

:: Downloaders & Network Tools
set "NAME21=curl"
set "NAME22=aria2"
set "NAME23=yt-dlp"

:: System Monitoring, Benchmarking & Code Analytics
set "NAME24=btop"
set "NAME25=hyperfine"
set "NAME26=tokei"

:: Bucket list
set "BUCKET1=extras"
set "BUCKET2=versions"
set "BUCKET3=java"
set "BUCKET4=php"
set "BUCKET5=games"
set "BUCKET6=nerd-fonts"
set "BUCKET7=nonportable"
set "BUCKET8=sysinternals"
set "BUCKET9=nirsoft"

:: Every toggle variable starts in a known (OFF) state
call :DESELECT_ALL_PROGS
call :DESELECT_ALL_BUCKETS
goto :eof

:GO
echo. & echo The operation is done.
pause & goto :eof
