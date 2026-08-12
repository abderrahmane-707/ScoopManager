@echo off
setlocal enabledelayedexpansion
mode con: cols=100 lines=30

:: Initialize Constants
set "PROGS_COUNT=24"
set "BUCKET_COUNT=9"
set "ON=(YES)"
set "OFF=(NO)"

:: Initialize programs/bucket
call :INIT_NAMES

:: Main interface
:SCOOP_MENU
cls
echo.
echo                                                 \\!//
echo                                                 (o o)
echo              -------------------------------oOOo-(_)-oOOo-------------------------------
echo                                       Scoop Software Installer
echo              ---------------------------------------------------------------------------
echo.
echo                   [1] GCC                  [9]  Git                 [17] yt-dlp
echo                   [2] GDB Debugger         [10] SourceGit           [18] cURL
echo                   [3] cppcheck             [11] VS Code             [19] aria2
echo                   [4] CMake                [12] Neovim              [20] ripgrep
echo                   [5] Make                 [13] micro               [21] fd
echo                   [6] Ninja                [14] yazi                [22] btop
echo                   [7] hyperfine            [15] lazygit             [23] tre-command
echo                   [8] tokei                [16] delta               [24] fzf
echo.
echo    [U] Update Programs
echo    [R] Remove Programs
echo    [B] Manage Buckets
echo    [M] More
echo.
echo              ---------------------------------------------------------------------------
echo.
echo                    [A] Select All            [D] Deselect All            [X] Exit

echo. & echo Selected programs:
call :SHOW_SELECTED OPT NAME %PROGS_COUNT%

echo. & echo Tip: You can select multiple items, e.g. 1,3,5 or 1-5 or 1-3,7,10-12

echo. & set "choice=" & set /p "choice=--> Select option(s) and press [S] to Start: "

if "%choice%"=="" goto SCOOP_MENU
if /i "%choice%"=="X" exit
if /i "%choice%"=="S" goto RUN_PROGRAMS
if /i "%choice%"=="A" (call :SELECT_ALL OPT %PROGS_COUNT% & goto SCOOP_MENU)
if /i "%choice%"=="D" (call :DESELECT_ALL OPT %PROGS_COUNT% & goto SCOOP_MENU)
if /i "%choice%"=="U" goto UPDATE_MENU
if /i "%choice%"=="R" goto REMOVE_MENU
if /i "%choice%"=="B" goto BUCKET_MENU
if /i "%choice%"=="M" goto MORE_PROG

call :MULTI_INPUT OPT %PROGS_COUNT%
goto SCOOP_MENU

:RUN_PROGRAMS
cls
call :WHERE_7Z

for /L %%i in (1,1,%PROGS_COUNT%) do (
    if "!OPT%%i!"=="%ON%" (
        call scoop install -k "!NAME%%i!"
        if !errorlevel! neq 0 (
            echo. & echo Failed to install: !NAME%%i!
        )
    )
)
call :GO & call :DESELECT_ALL OPT %PROGS_COUNT% & goto SCOOP_MENU

:UPDATE_MENU
cls & echo Checking available updates
call :WHERE_7Z
call scoop update && call scoop status

echo.
echo --------------------------------------------------------------------------------
echo Type ALL to update everything
echo Or type the exact program name(s) as shown above, separated by commas
echo Type 0 to go back
echo --------------------------------------------------------------------------------

set "choice=" & set /p "choice=--> "
if "%choice%"=="" goto UPDATE_MENU
if "%choice%"=="0" goto SCOOP_MENU

call :PKG_BULK_ACTION "upgrade"
call :GO & goto SCOOP_MENU

:REMOVE_MENU
cls & echo list installed programs
call scoop list

echo.
echo --------------------------------------------------------------------------------
echo Type ALL to remove everything.
echo Or type the exact program name(s) as shown above, separated by commas
echo Type 0 to go back.
echo --------------------------------------------------------------------------------

set "choice=" & set /p "choice=--> "
if "%choice%"=="0" goto SCOOP_MENU
if "%choice%"=="" goto REMOVE_MENU

call :PKG_BULK_ACTION "uninstall"
call :GO & goto SCOOP_MENU

:MORE_PROG
cls & set "apps=" & set /p apps="Enter app name(s) separated by spaces: "
if "%apps%"=="" goto MORE_PROG

call :WHERE_7Z
for %%A in (%apps%) do call scoop install -k "%%A"
call :GO & goto SCOOP_MENU

:BUCKET_MENU
cls & echo.
echo                                                  \\!//
echo                                                  (o o)
echo              -------------------------------oOOo-(_)-oOOo-------------------------------
echo                                       Scoop Buckets Installer
echo              ---------------------------------------------------------------------------
echo.
echo                    [1] extras               [4]  php                 [7] nonportable
echo                    [2] versions             [5] games                [8] sysinternals
echo                    [3] java                 [6] nerd-fonts           [9] nirsoft
echo.
echo    [U] Update Buckets
echo    [R] Remove Buckets
echo.
echo              ---------------------------------------------------------------------------
echo.
echo                    [A] Select All            [D] Deselect All            [0] Back

echo. & echo Selected buckets:
call :SHOW_SELECTED BOPT BUCKET %BUCKET_COUNT%

echo. & echo Tip: You can select multiple items, e.g. 1,3,5 or 1-5 or 1-3,7,10-12
echo. & set "choice=" & set /p "choice=--> Select option(s) and press [S] to Start: "

if "%choice%"=="" goto BUCKET_MENU
if "%choice%"=="0" goto SCOOP_MENU
if /i "%choice%"=="A" (call :SELECT_ALL BOPT %BUCKET_COUNT% & goto BUCKET_MENU)
if /i "%choice%"=="D" (call :DESELECT_ALL BOPT %BUCKET_COUNT% & goto BUCKET_MENU)
if /i "%choice%"=="U" goto UPDATE_BUCKETS
if /i "%choice%"=="S" goto INSTALL_BUCKETS
if /i "%choice%"=="R" goto REMOVE_BUCKETS

call :MULTI_INPUT BOPT %BUCKET_COUNT%
goto BUCKET_MENU

:INSTALL_BUCKETS
cls & echo Installing Buckets
echo.
for /L %%i in (1,1,%BUCKET_COUNT%) do (
    if "!BOPT%%i!"=="%ON%" (
        echo Installing: !BUCKET%%i!
        call scoop bucket add !BUCKET%%i!
    )
)
call :GO & call :DESELECT_ALL BOPT %BUCKET_COUNT% & goto BUCKET_MENU

:UPDATE_BUCKETS
cls & echo Updating all Buckets
call scoop update
call :GO & goto BUCKET_MENU

:REMOVE_BUCKETS
cls & echo Currently Installed Buckets
call scoop bucket list

echo.
echo --------------------------------------------------------------------------------
echo Type ALL to remove all buckets
echo Or type the exact bucket name(s) as shown above, separated by commas
echo Type 0 to go back
echo --------------------------------------------------------------------------------

set "choice=" & set /p "choice=--> "
if "%choice%"=="" goto REMOVE_BUCKETS
if "%choice%"=="0" goto BUCKET_MENU

if /i "%choice%"=="ALL" (
    echo. & echo Removing all installed buckets
    for /f "skip=2 tokens=1" %%B in ('call scoop bucket list 2^>nul') do (
        if not "%%B"=="" (
            echo Removing bucket: %%B
            call scoop bucket rm %%B
        )
    )
) else (
    for %%G in (%choice:,= %) do (
        echo. & echo Removing bucket: %%G
        call scoop bucket rm %%G
    )
)

call :GO & goto BUCKET_MENU

:MULTI_INPUT
:: %1 = Option Prefix (e.g., OPT or BOPT)
:: %2 = Max Limit (e.g., %PROGS_COUNT% or %BUCKET_COUNT%)

set "prefix=%~1"
set "maxLimit=%~2"
set "invalid="
set "tokens=%choice:,= %"

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
            if !rangeStart! geq 1 if !rangeEnd! leq !maxLimit! if !rangeStart! leq !rangeEnd! (
                for /L %%N in (!rangeStart!,1,!rangeEnd!) do call :TOGGLE_SINGLE !prefix!%%N
                set "matched=1"
            )
        )
    ) else (
        set "isNum=1" & for /f "delims=0123456789" %%C in ("!tok!") do set "isNum=0"
        if "!isNum!"=="1" if defined tok (
            if !tok! geq 1 if !tok! leq !maxLimit! (
                call :TOGGLE_SINGLE !prefix!!tok!
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

:TOGGLE_SINGLE
:: %1 = full variable name, e.g. OPT3 or BOPT5
if "!%~1!"=="%ON%" (set "%~1=%OFF%") else (set "%~1=%ON%")
goto :eof

:SHOW_SELECTED
set "optPrefix=%~1"
set "namePrefix=%~2"
set "cnt=%~3"
set "ANY=0"
for /L %%i in (1,1,%cnt%) do (
    if "!%optPrefix%%%i!"=="%ON%" (
        echo     - !%namePrefix%%%i!
        set "ANY=1"
    )
)
if "!ANY!"=="0" echo     - No item selected
goto :eof

:SELECT_ALL
set "optPrefix=%~1"
set "cnt=%~2"
for /L %%i in (1,1,%cnt%) do set "%optPrefix%%%i=%ON%"
goto :eof

:DESELECT_ALL
set "optPrefix=%~1"
set "cnt=%~2"
for /L %%i in (1,1,%cnt%) do set "%optPrefix%%%i=%OFF%"
goto :eof

:PKG_BULK_ACTION
set "bulkAction=%~1"

if /i "%choice%"=="ALL" (
    if /i "%bulkAction%"=="upgrade" (
        echo Updating all programs
        call scoop update -k * && call scoop cleanup *
    ) else (
        echo Removing all programs
        for /f "skip=2 tokens=1" %%P in ('call scoop list 2^>nul') do (
            if not "%%P"=="" call scoop uninstall %%P --purge
        )
    )
) else (
    for %%G in (%choice:,= %) do (
        echo. & echo Processing: %%G
        if /i "%bulkAction%"=="upgrade" (call scoop update -k %%G && call scoop cleanup %%G) else (call scoop uninstall %%G --purge)
    )
)
goto :eof

:WHERE_7Z
where 7z.exe >nul 2>&1 && (
    call scoop config use_external_7zip true >nul 2>&1
) || (
    call scoop config use_external_7zip false >nul 2>&1
)
goto :eof

:INIT_NAMES
set "NAME1=gcc"
set "NAME2=gdb"
set "NAME3=cppcheck"
set "NAME4=cmake"
set "NAME5=make"
set "NAME6=ninja"
set "NAME7=hyperfine"
set "NAME8=tokei"
set "NAME9=git"
set "NAME10=sourcegit"
set "NAME11=vscode"
set "NAME12=neovim"
set "NAME13=micro"
set "NAME14=yazi"
set "NAME15=lazygit"
set "NAME16=delta"
set "NAME17=yt-dlp"
set "NAME18=curl"
set "NAME19=aria2"
set "NAME20=ripgrep"
set "NAME21=fd"
set "NAME22=btop"
set "NAME23=tre-command"
set "NAME24=fzf"

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
call :DESELECT_ALL OPT %PROGS_COUNT%
call :DESELECT_ALL BOPT %BUCKET_COUNT%
goto :eof

:GO
echo. & echo The operation is done.
pause & goto :eof
