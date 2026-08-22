@echo off
setlocal enabledelayedexpansion

call :WHERE_SCOOP
if %errorlevel% equ 1 exit /b 1

:: Initialize
set "ON=(YES)"
set "OFF=(NO)"

call :INIT_PACKAGES
call :DESELECT_ALL_PKG

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

cls & echo Selected packages:
for %%P in (!toInstall!) do echo     - %%P

echo. & call :CHOICE "Do you want to continue?"
if errorlevel 2 (
    echo. & echo The operation was cancelled
	pause & goto SCOOP_MENU
)

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

:: Search & install packages interactively via a live fzf + scoop-search session
:MORE_PKG
cls
call :WHERE_SCOOP_SEARCH
if errorlevel 1 goto SCOOP_MENU

call :WHERE_FZF
if errorlevel 1 goto SCOOP_MENU

set "fzftmp=%TEMP%\scoop_pkg_select_%RANDOM%.txt"
del "%fzftmp%" >nul 2>&1

set "fzflist=%TEMP%\scoop_pkg_list_%RANDOM%.txt"
set "rawlist=%TEMP%\scoop_pkg_raw_%RANDOM%.txt"
scoop-search . > "%rawlist%"

set "curbucket="
> "%fzflist%" (
    for /f "usebackq delims=" %%L in ("%rawlist%") do (
        set "ln=%%L"
        set "first=!ln:~0,1!"
        if "!first!"=="'" (
            for /f "tokens=1,2 delims='" %%A in ("!ln!") do set "curbucket=%%A"
        ) else if not "!ln!"=="" (
            for /f "tokens=* delims= " %%A in ("!ln!") do echo !curbucket!/%%A
        )
    )
)
del "%rawlist%" >nul 2>&1

fzf --multi --ansi --prompt="Search> " --header="Press [TAB] for multi-select | Press [ENTER] to confirm | Press [ESC] to cancel" --bind "tab:toggle+down,shift-tab:toggle+up" < "%fzflist%" > "%fzftmp%"

del "%fzflist%" >nul 2>&1

if not exist "%fzftmp%" (
    echo. & echo No selection made
    call :GO & goto SCOOP_MENU
)

for %%Z in ("%fzftmp%") do if %%~zZ==0 (
    del "%fzftmp%" >nul 2>&1
    echo. & echo No selection made
    call :GO & goto SCOOP_MENU
)

:: Extract the package name from each selected "bucket/name (version)" line
set "toInstall="
for /f "usebackq delims=" %%L in ("%fzftmp%") do (
    set "line=%%L"
    set "afterslash="
    for /f "tokens=1,2 delims=/" %%A in ("!line!") do set "afterslash=%%B"
    if defined afterslash (
        for /f "tokens=1" %%A in ("!afterslash!") do set "toInstall=!toInstall! %%A"
    ) else (
        for /f "tokens=1" %%A in ("!line!") do set "toInstall=!toInstall! %%A"
    )
)
del "%fzftmp%" >nul 2>&1

if not defined toInstall (
    echo. & echo No packages selected
    call :GO & goto SCOOP_MENU
)

cls & echo Selected packages:
for %%P in (!toInstall!) do echo     - %%P

echo. & call :CHOICE "Do you want to continue?"
if errorlevel 2 (
    echo. & echo The operation was cancelled
	pause & goto SCOOP_MENU
)

echo. & call :WHERE_7Z
call scoop install -k !toInstall!

call :GO & goto SCOOP_MENU

:WHERE_FZF
where fzf >nul 2>&1 && exit /b 0

echo fzf is required for interactive package search but is not installed
call :CHOICE "Do you want to install fzf?"
if errorlevel 2 exit /b 1

echo. & call scoop install fzf
where fzf >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to install fzf
    pause & exit /b 1
)
exit /b 0

:WHERE_SCOOP_SEARCH
where scoop-search >nul 2>&1 && exit /b 0

echo scoop-search is required for fast package search but is not installed
call :CHOICE "Do you want to install scoop-search?"
if errorlevel 2 exit /b 1

echo. & call scoop install scoop-search
where scoop-search >nul 2>&1
if %errorlevel% neq 0 (
    echo Failed to install scoop-search
    pause & exit /b 1
)
exit /b 0

:BUCKET_INITIAL
call :INIT_BUCKET
call :DESELECT_ALL_BUCKETS

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

cls & echo Selected buckets:
for %%B in (!toAddBuckets!) do echo     - %%B

echo. & call :CHOICE "Do you want to continue?"
if errorlevel 2 (
    echo. & echo The operation was cancelled
	pause & goto BUCKET_MENU
)

echo. & for %%B in (!toAddBuckets!) do call scoop bucket add %%B
call :GO & call :DESELECT_ALL_BUCKETS & goto BUCKET_MENU

:UPDATE_BUCKETS
cls & echo Updating all Buckets
call scoop update
call :GO & goto BUCKET_MENU

:REMOVE_BUCKETS
cls & echo Installed buckets
call scoop bucket list

set "installedBuckets="
for /f "skip=2 tokens=1" %%B in ('scoop bucket list 2^>nul') do (
    set "bkt=%%B"
    if defined bkt if "!bkt:~0,1!" neq "-" set "installedBuckets=!installedBuckets! %%B"
)
if not defined installedBuckets (
    echo. & echo No buckets are currently installed
    pause & goto BUCKET_MENU
)

call :PRINT_ACTION_PROMPT "remove"

set "choice=" & set /p "choice=--> "
if "%choice%"=="0" goto BUCKET_MENU

set "tormBuckets="
if /i "%choice%"=="ALL" (
    set "tormBuckets=%installedBuckets%"
) else (
    set "raw=%choice:,= %"
    for %%G in (!raw!) do (
        set "found="
        for %%I in (%installedBuckets%) do if /i "%%G"=="%%I" set "found=1"
        if defined found (
            set "tormBuckets=!tormBuckets! %%G"
        ) else (
            echo     - "%%G": is not an installed bucket - skipping
        )
    )
)
:WHERE_SCOOP
where scoop >nul 2>&1 && goto :eof

echo Scoop is not installed
call :CHOICE "Do you want to download and install Scoop?"
if errorlevel 2 exit /b 1

echo. & echo Installing Scoop via PowerShell...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; irm get.scoop.sh | iex"

:: Update current session PATH so 'where scoop' works immediately without restarting CMD
set "PATH=%USERPROFILE%\scoop\shims;%PATH%"

where scoop >nul 2>&1
if %errorlevel% neq 0 (
    echo Installation failed or PATH not updated in this session
    pause & exit /b 1
)

echo Ading extras buckets
scoop bucket add extras
goto :eof

:INIT_PACKAGES
set "PKG_COUNT=0"

:: Web Browsers
call :ADD_PKG "brave"             "Brave"
call :ADD_PKG "librewolf"         "LibreWolf"
call :ADD_PKG "tor-browser"       "Tor Browser"

:: File Managers, Search & Navigation
call :ADD_PKG "ripgrep"           "Ripgrep"
call :ADD_PKG "fd"                "fd-find"
call :ADD_PKG "fzf"               "fzf"
call :ADD_PKG "yazi"              "Yazi"
call :ADD_PKG "tre-command"       "Tre"
call :ADD_PKG "everything"        "Everything"

:: Archivers & Compression
call :ADD_PKG "7zip-zstd"         "7-Zip Zstandard"
call :ADD_PKG "winrar"            "WinRAR"
call :ADD_PKG "peazip"            "PeaZip"

:: Multi Media
call :ADD_PKG "mpc-hc-fork"       "MPC-HC (Fork)"
call :ADD_PKG "xnviewmp"          "XnView MP"
call :ADD_PKG "sumatrapdf"        "SumatraPDF"

:: Text Editors
call :ADD_PKG "vscode"            "VS Code"
call :ADD_PKG "micro"             "Micro"
call :ADD_PKG "notepadplusplus"   "Notepad++"

:: System Info
call :ADD_PKG "btop"              "btop"
call :ADD_PKG "hwinfo"            "HWiNFO"
call :ADD_PKG "duf"               "duf"
call :ADD_PKG "dust"              "dust"

:: System Cleaners
call :ADD_PKG "bleachbit"         "BleachBit"

:: Network, Remote & Downloads
call :ADD_PKG "freedownloadmanager" "FDM"
call :ADD_PKG "ytdlp-interface"   "yt-dlp Interface"
call :ADD_PKG "qbittorrent"       "qBittorrent"
call :ADD_PKG "rustdesk"          "RustDesk"

:: Git Tools
call :ADD_PKG "git"               "Git"
call :ADD_PKG "gh"                "GitHub CLI"
call :ADD_PKG "sourcegit"         "SourceGit"

:: Dev
call :ADD_PKG "mingw"             "MinGW"
call :ADD_PKG "llvm"              "LLVM"
call :ADD_PKG "cppcheck"          "Cppcheck"
call :ADD_PKG "hyperfine"         "Hyperfine"

set "MAX_PKG=%PKG_COUNT%"
goto :eof

:ADD_PKG
set /a "PKG_COUNT+=1"
set "pname=%~2"
set "ITEM%PKG_COUNT%=%~1|%pname%"
goto :eof

:INIT_BUCKET
set "BUCKET_COUNT=0"

call :ADD_BUCKET "main"        "Main"
call :ADD_BUCKET "extras"      "Extras"
call :ADD_BUCKET "versions"    "Versions"
call :ADD_BUCKET "java"        "Java"
call :ADD_BUCKET "php"         "PHP"
call :ADD_BUCKET "games"       "Games"
call :ADD_BUCKET "nerd-fonts"  "Nerd Fonts"
call :ADD_BUCKET "nonportable" "Non-Portable"
call :ADD_BUCKET "sysinternals" "Sysinternals"
call :ADD_BUCKET "nirsoft"     "NirSoft"

set "MAX_BUCKET=%BUCKET_COUNT%"
goto :eof

:ADD_BUCKET
set /a "BUCKET_COUNT+=1"
set "bname=%~2"
set "BITEM%BUCKET_COUNT%=%~1|%bname%"
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
call :WHERE_7Z
if /i "%choice%"=="ALL" (
    if /i "%~1"=="upgrade" (
        echo Updating all packages
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
	    echo Updating the following packages:
		for %%P in (!targets!) do echo     - %%P
		echo. & call :CHOICE "Do you want to continue?"
		if errorlevel 2 (echo The operation was cancelled & pause & goto SCOOP_MENU)
        call scoop update -k !targets! && call scoop cleanup !targets!
    ) else (
	    echo Removing the following packages:
        for %%P in (!targets!) do echo     - %%P
        echo. & call :CHOICE "Do you want to continue?"
        if errorlevel 2 (echo The operation was cancelled & pause & goto SCOOP_MENU)
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
