@echo off
setlocal enabledelayedexpansion

call :WHERE_SCOOP
if %errorlevel% equ 1 exit /b 1

:: Initialize
set "ON=(YES)"
set "OFF=(NO)"

:: Initialize packages
call :INIT_PACKAGES

:: Main interface
:SCOOP_MENU
cls
echo.
echo                                                 \\!//
echo                                                 (o o)
echo              -------------------------------oOOo-(_)-oOOo-------------------------------
echo                                         Scoop Package Manager
echo              ---------------------------------------------------------------------------
echo.
call :RENDER_COLUMNS ITEM OPT %MAX_PKG%

echo.
echo    [U] Update Packages
echo    [R] Remove Packages
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
if /i "%choice%"=="S" goto RUN_PACKAGES
if /i "%choice%"=="A" (call :SELECT_ALL_PKG & goto SCOOP_MENU)
if /i "%choice%"=="D" (call :DESELECT_ALL_PKG & goto SCOOP_MENU)
if /i "%choice%"=="U" goto UPDATE_MENU
if /i "%choice%"=="R" goto REMOVE_MENU
if /i "%choice%"=="B" goto BUCKET_INITIAL
if /i "%choice%"=="M" goto MORE_PKG

call :MULTI_INPUT OPT %MAX_PKG%
goto SCOOP_MENU

:RUN_PACKAGES
cls
:: Collect every selected program into a single list, then process it in one call
set "toInstall="
for /L %%i in (1,1,%MAX_PKG%) do (
    if "!OPT%%i!"=="%ON%" (
        for %%V in (ITEM%%i) do for /f "tokens=1 delims=|" %%A in ("!%%V!") do set "toInstall=!toInstall! %%A"
    )
)

if not defined toInstall (
    echo. & echo No packages selected
    call :GO & goto SCOOP_MENU
)

echo Installing the following packages:
for %%P in (!toInstall!) do echo     - %%P

echo. & call :WHERE_7Z
call scoop install -k !toInstall!

call :GO & call :DESELECT_ALL_PKG & goto SCOOP_MENU

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
cls & set "prog=" & set /p prog="Enter program name(s) separated by spaces: "
if "%prog%"=="" goto MORE_PROG

echo. & call :WHERE_7Z
call scoop install -k %prog%

call :GO & goto SCOOP_MENU

:BUCKET_INITIAL
set "MAX_BUCKET=9"
call :INIT_BUCKET

:BUCKET_MENU
cls & echo.
echo                                                 \\!//
echo                                                 (o o)
echo              -------------------------------oOOo-(_)-oOOo-------------------------------
echo                                          Scoop Buckets Manager
echo              ---------------------------------------------------------------------------
echo.

call :RENDER_COLUMNS BITEM BOPT %MAX_BUCKET%

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
if "%choice%"=="0" (call :DESELECT_ALL_PKG & goto SCOOP_MENU)
if /i "%choice%"=="A" (call :SELECT_ALL_BUCKETS & goto BUCKET_MENU)
if /i "%choice%"=="D" (call :DESELECT_ALL_BUCKETS & goto BUCKET_MENU)
if /i "%choice%"=="U" goto UPDATE_BUCKETS
if /i "%choice%"=="S" goto ADD_BUCKETS
if /i "%choice%"=="R" goto REMOVE_BUCKETS

call :MULTI_INPUT BOPT %MAX_BUCKET%
goto BUCKET_MENU

:ADD_BUCKETS
cls
set "toAddBuckets="
for /L %%i in (1,1,%MAX_BUCKET%) do (
    if "!BOPT%%i!"=="%ON%" (
        for %%V in (BITEM%%i) do for /f "tokens=1 delims=|" %%A in ("!%%V!") do set "toAddBuckets=!toAddBuckets! %%A"
    )
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

set "choice=" & set /p "choice=--> "
if "%choice%"=="" goto REMOVE_BUCKETS
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

:WHERE_SCOOP
where scoop >nul 2>&1 && goto :eof

echo Scoop is not installed.
choice /C YN /M "Do you want to download and install Scoop? [Y/n]"
if errorlevel 2 exit /b 1

echo Installing Scoop via PowerShell...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')"

:: Update current session PATH so 'where scoop' works immediately without restarting CMD
set "PATH=%USERPROFILE%\scoop\shims;%PATH%"

where scoop >nul 2>&1
if %errorlevel% neq 0 (
    echo Installation failed or PATH not updated in this session
    pause & exit /b 1
)
goto :eof

:INIT_PACKAGES
set "MAX_PKG=23"

:: Web Browsers
set "ITEM1=brave|Brave"
set "ITEM2=librewolf|LibreWolf"
set "ITEM3=tor-browser|Tor Browser"

:: File Managers, Search & Navigation
set "ITEM4=ripgrep|Ripgrep"
set "ITEM5=fd|fd-find"
set "ITEM6=fzf|fzf"
set "ITEM7=yazi|Yazi"
set "ITEM8=tre-command|Tre"
set "ITEM9=everything|Everything"

:: System Info & Benchmarking
set "ITEM10=btop|btop"
set "ITEM11=hyperfine|Hyperfine"
set "ITEM12=hwinfo|HWiNFO"

:: System Cleaners
set "ITEM13=bleachbit|BleachBit"

:: Network & Remote Tools
set "ITEM14=rustdesk|RustDesk"
set "ITEM15=ytdlp-interface|yt-dlp Interface"

:: Text Editors
set "ITEM16=vscode|VS Code"
set "ITEM17=micro|Micro"

:: Git Tools
set "ITEM18=git|Git"
set "ITEM19=gh|GitHub CLI"
set "ITEM20=sourcegit|SourceGit"

:: Compilers
set "ITEM21=mingw|MinGw"
set "ITEM22=llvm|LLVM"

:: Debuggers
set "ITEM23=cppcheck|Cppcheck"

call :DESELECT_ALL_PKG
goto :eof

:INIT_BUCKET
set "MAX_BUCKET=11"

:: Main general purpose applications
set "BITEM1=main|Main"

:: Extra utilities
set "BITEM2=extras|Extras"

:: Beta, or legacy versions
set "BITEM3=versions|Versions"

:: Java Development Kits (JDKs), JREs
set "BITEM4=java|Java"

:: PHP runtimes, extensions, and web development tooling
set "BITEM5=php|PHP"

:: Open-source and freeware games
set "BITEM6=games|Games"

:: Developer fonts patched with icons for terminals and editors
set "BITEM7=nerd-fonts|Nerd Fonts"

:: Software requiring system installation
set "BITEM8=nonportable|Non-Portable"

:: Sysinternals tools
set "BITEM9=sysinternals|Sysinternals"

:: NirSoft utilities
set "BITEM10=nirsoft|NirSoft"
goto :eof

:RENDER_COLUMNS
set "iprefix=%~1"
set "oprefix=%~2"
set "mx=%~3"
set /a "ROWS=(mx+2)/3"
for /L %%r in (1,1,!ROWS!) do (
    set "line="
    for %%x in (1 2 3) do (
        set /a "idx=%%r+ROWS*(%%x-1)"
        set "cell=                         "
        if !idx! leq !mx! (
            for %%V in (!iprefix!!idx!) do for %%W in (!oprefix!!idx!) do (
                for /f "tokens=1,2 delims=|" %%A in ("!%%V!") do (
                    set "cell=  [!idx!] %%B"
                    if "!%%W!"=="!ON!" set "cell=* [!idx!] %%B"
                )
            )
        )
        set "cell=!cell!                          "
        set "cell=!cell:~0,25!"
        set "line=!line!!cell!"
    )
    echo                  !line!
)
goto :eof

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
                for /L %%N in (!rangeStart!,1,!rangeEnd!) do (
                    for %%V in (%prefix%%%N) do (
                        if "!%%V!"=="%ON%" (set "%%V=%OFF%") else (set "%%V=%ON%")
                    )
                )
                set "matched=1"
            )
        )
    ) else (
        set "isNum=1" & for /f "delims=0123456789" %%C in ("!tok!") do set "isNum=0"
        if "!isNum!"=="1" if defined tok (
            if !tok! geq 1 if !tok! leq !max_count! (
                for %%V in (%prefix%!tok!) do (
                    if "!%%V!"=="%ON%" (set "%%V=%OFF%") else (set "%%V=%ON%")
                )
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

:PKG_BULK_ACTION
if /i "!choice!"=="ALL" (
    if /i "%~1"=="upgrade" (
        echo Updating all packages
        echo. & call :WHERE_7Z
        call scoop update -k * && call scoop cleanup *
    ) else (
        echo Removing all packages
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
    echo.
    if /i "%~1"=="upgrade" (
	    echo Updating: !targets!
        echo. & call :WHERE_7Z
        call scoop update -k !targets! && call scoop cleanup !targets!
    ) else (
	    echo Removing: !targets!
        call scoop uninstall !targets! --purge
    )
)
goto :eof

:SELECT_ALL_PKG
for /L %%i in (1,1,%MAX_PKG%) do set "OPT%%i=%ON%"
goto :eof

:DESELECT_ALL_PKG
for /L %%i in (1,1,%MAX_PKG%) do set "OPT%%i=%OFF%"
goto :eof

:SELECT_ALL_BUCKETS
for /L %%i in (1,1,%MAX_BUCKET%) do set "BOPT%%i=%ON%"
goto :eof

:DESELECT_ALL_BUCKETS
for /L %%i in (1,1,%MAX_BUCKET%) do set "BOPT%%i=%OFF%"
goto :eof

:PRINT_ACTION_PROMPT
echo.
echo --------------------------------------------------------------------------------
echo Type ALL to %~1 everything
echo Or type the exact name(s) as shown above, separated by spaces
echo Type 0 to go back
echo --------------------------------------------------------------------------------
goto :eof

:WHERE_7Z
if "%HAS_7Z%"=="1" goto :eof
where 7z.exe >nul 2>&1
if %errorlevel% equ 0 (
    call scoop config use_external_7zip true >nul 2>&1
) else (
    call scoop config use_external_7zip false >nul 2>&1
)

set "HAS_7Z=1"
goto :eof

:CHOICE
choice /C YN /N /M "%~1 [Y/n]: "
goto :eof

:GO
echo. & echo The operation is done.
pause & goto :eof
