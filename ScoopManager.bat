@echo off
setlocal enabledelayedexpansion

call :WHERE_SCOOP
if errorlevel 1 exit /b 1

:: Initialize
set "ON=(YES)"
set "OFF=(NO)"

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
set "choice=" & set /p "choice=--> Select option(s) and press [S] to Start: "

if "%choice%"=="" goto SCOOP_MENU
if "%choice%"=="0" exit /b
if /i "%choice%"=="S" goto RUN_PACKAGES
if /i "%choice%"=="A" (call :TOGGLE_ALL OPT %MAX_PKG% ON & goto SCOOP_MENU)
if /i "%choice%"=="D" (call :TOGGLE_ALL OPT %MAX_PKG% OFF & goto SCOOP_MENU)
if /i "%choice%"=="U" goto UPDATE_MENU
if /i "%choice%"=="R" goto REMOVE_MENU
if /i "%choice%"=="B" goto BUCKET_INITIAL
if /i "%choice%"=="M" goto MORE_PKG

call :MULTI_INPUT OPT %MAX_PKG%
goto SCOOP_MENU

:RUN_PACKAGES
:: Collect every selected packages into a single list, then process it in one call
call :COLLECT_SELECTED "ITEM" "OPT" "%MAX_PKG%" "toInstall"

call :BULK_ADD_ACTION "package" "!toInstall!"
if errorlevel 1 (pause & goto SCOOP_MENU)

call :GO & call :TOGGLE_ALL OPT %MAX_PKG% OFF & goto SCOOP_MENU

:UPDATE_MENU
cls
call scoop update
call scoop status

call :PRINT_ACTION_PROMPT "update"

set "choice=" & set /p "choice=--> "
if "%choice%"=="0" goto SCOOP_MENU

call :WHERE_7Z
call :PKG_BULK_ACTION "upgrade"
if errorlevel 1 (pause & goto SCOOP_MENU)

call :GO & goto SCOOP_MENU

:REMOVE_MENU
cls
call scoop list

call :PRINT_ACTION_PROMPT "remove"

set "choice=" & set /p "choice=--> "
if "%choice%"=="0" goto SCOOP_MENU

call :PKG_BULK_ACTION "uninstall"
if errorlevel 1 (pause & goto SCOOP_MENU)

call :GO & goto SCOOP_MENU

:MORE_PKG
cls
call :ENSURE_TOOL "scoop-search" "(required for fast package search)"
if errorlevel 1 goto SCOOP_MENU

call :ENSURE_TOOL "fzf" "(required for interactive package search)"
if errorlevel 1 goto SCOOP_MENU

call :RUN_FZF_SELECTOR
if errorlevel 1 goto SCOOP_MENU

call :BULK_ADD_ACTION "package" "!toInstall!"
if errorlevel 1 (pause & goto SCOOP_MENU)

call :GO & goto SCOOP_MENU

:BUCKET_INITIAL
call :INIT_BUCKET

:BUCKET_MENU
cls & echo.
echo                                                 \\!//
echo                                                 (o o)
echo              -------------------------------oOOo-(_)-oOOo-------------------------------
echo                                            Buckets Manager
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
set "choice=" & set /p "choice=--> Select option(s) and press [S] to Start: "

if "%choice%"=="" goto BUCKET_MENU
if "%choice%"=="0" goto SCOOP_MENU
if /i "%choice%"=="A" (call :TOGGLE_ALL BOPT %MAX_BUCKET% ON & goto BUCKET_MENU)
if /i "%choice%"=="D" (call :TOGGLE_ALL BOPT %MAX_BUCKET% OFF & goto BUCKET_MENU)
if /i "%choice%"=="U" goto UPDATE_BUCKETS
if /i "%choice%"=="S" goto ADD_BUCKETS
if /i "%choice%"=="R" goto REMOVE_BUCKETS

call :MULTI_INPUT BOPT %MAX_BUCKET%
goto BUCKET_MENU

:ADD_BUCKETS
call :COLLECT_SELECTED "BITEM" "BOPT" "%MAX_BUCKET%" "toAddBuckets"

call :BULK_ADD_ACTION "bucket" "!toAddBuckets!"
if errorlevel 1 (pause & goto BUCKET_MENU)
    
call :TOGGLE_ALL BOPT %MAX_BUCKET% OFF & goto BUCKET_MENU

:UPDATE_BUCKETS
cls & echo Updating all installed Buckets
call scoop update
call :GO & goto BUCKET_MENU

:REMOVE_BUCKETS
cls & echo Installed buckets:
call scoop bucket list

call :PRINT_ACTION_PROMPT "remove"

set "choice=" & set /p "choice=--> "
if not defined choice goto BUCKET_MENU
if "%choice%"=="0" goto BUCKET_MENU

if /i "%choice%"=="ALL" (
	call :GET_SCOOP_NAMES tormBuckets "buckets"
    echo. & echo Removing all installed buckets:
) else (
    set "tormBuckets=%choice:,= %"
    echo. & echo Removing the following buckets:
)

for %%G in (!tormBuckets!) do echo     - %%G
echo. & call :CHOICE "Do you want to continue?"
if errorlevel 2 (
    echo. & echo The operation was cancelled
    pause & goto BUCKET_MENU
)

echo. & for %%G in (!tormBuckets!) do call scoop bucket rm %%G
call :GO & goto BUCKET_MENU

:: Functions
:INIT_PACKAGES
set "PKG_COUNT=0"

:: Web Browsers
call :ADD_ITEM PKG_COUNT ITEM "brave"               "Brave"
call :ADD_ITEM PKG_COUNT ITEM "librewolf"           "LibreWolf"
call :ADD_ITEM PKG_COUNT ITEM "tor-browser"         "Tor Browser"

:: File Managers, Search & Navigation
call :ADD_ITEM PKG_COUNT ITEM "ripgrep"             "Ripgrep"
call :ADD_ITEM PKG_COUNT ITEM "fd"                  "fd-find"
call :ADD_ITEM PKG_COUNT ITEM "fzf"                 "fzf"
call :ADD_ITEM PKG_COUNT ITEM "yazi"                "Yazi"
call :ADD_ITEM PKG_COUNT ITEM "tre-command"         "Tre"
call :ADD_ITEM PKG_COUNT ITEM "everything"          "Everything"

:: Archivers & Compression
call :ADD_ITEM PKG_COUNT ITEM "7zip-zstd"           "7-Zip Zstandard"
call :ADD_ITEM PKG_COUNT ITEM "winrar"              "WinRAR"
call :ADD_ITEM PKG_COUNT ITEM "peazip"              "PeaZip"

:: Multi Media
call :ADD_ITEM PKG_COUNT ITEM "mpc-hc-fork"         "MPC-HC (Fork)"
call :ADD_ITEM PKG_COUNT ITEM "xnviewmp"            "XnView MP"
call :ADD_ITEM PKG_COUNT ITEM "sumatrapdf"          "SumatraPDF"

:: Text Editors
call :ADD_ITEM PKG_COUNT ITEM "vscode"              "VS Code"
call :ADD_ITEM PKG_COUNT ITEM "micro"               "Micro"
call :ADD_ITEM PKG_COUNT ITEM "notepadplusplus"     "Notepad++"

:: System Info
call :ADD_ITEM PKG_COUNT ITEM "btop"                "btop"
call :ADD_ITEM PKG_COUNT ITEM "hwinfo"              "HWiNFO"
call :ADD_ITEM PKG_COUNT ITEM "duf"                 "duf"
call :ADD_ITEM PKG_COUNT ITEM "dust"                "dust"

:: System Cleaners
call :ADD_ITEM PKG_COUNT ITEM "bleachbit"           "BleachBit"

:: Network, Remote & Downloads
call :ADD_ITEM PKG_COUNT ITEM "freedownloadmanager" "FDM"
call :ADD_ITEM PKG_COUNT ITEM "aria2"               "aria2"
call :ADD_ITEM PKG_COUNT ITEM "ytdlp-interface"     "yt-dlp Interface"
call :ADD_ITEM PKG_COUNT ITEM "qbittorrent"         "qBittorrent"
call :ADD_ITEM PKG_COUNT ITEM "rustdesk"            "RustDesk"

:: Git Tools
call :ADD_ITEM PKG_COUNT ITEM "git"                 "Git"
call :ADD_ITEM PKG_COUNT ITEM "mingit"              "Mingit"
call :ADD_ITEM PKG_COUNT ITEM "gh"                  "GitHub CLI"
call :ADD_ITEM PKG_COUNT ITEM "sourcegit"           "SourceGit"

:: Dev
call :ADD_ITEM PKG_COUNT ITEM "mingw"               "MinGW"
call :ADD_ITEM PKG_COUNT ITEM "llvm"                "LLVM"
call :ADD_ITEM PKG_COUNT ITEM "cppcheck"            "Cppcheck"
call :ADD_ITEM PKG_COUNT ITEM "hyperfine"           "Hyperfine"

set "MAX_PKG=%PKG_COUNT%"

call :TOGGLE_ALL OPT %MAX_PKG% OFF
exit /b

:INIT_BUCKET
set "BUCKET_COUNT=0"
call :ADD_ITEM BUCKET_COUNT BITEM "main"            "Main"
call :ADD_ITEM BUCKET_COUNT BITEM "extras"          "Extras"
call :ADD_ITEM BUCKET_COUNT BITEM "versions"        "Versions"
call :ADD_ITEM BUCKET_COUNT BITEM "java"            "Java"
call :ADD_ITEM BUCKET_COUNT BITEM "php"             "PHP"
call :ADD_ITEM BUCKET_COUNT BITEM "games"           "Games"
call :ADD_ITEM BUCKET_COUNT BITEM "nerd-fonts"      "Nerd Fonts"
call :ADD_ITEM BUCKET_COUNT BITEM "nonportable"     "Non-Portable"
call :ADD_ITEM BUCKET_COUNT BITEM "sysinternals"    "Sysinternals"
call :ADD_ITEM BUCKET_COUNT BITEM "nirsoft"         "NirSoft"

set "MAX_BUCKET=%BUCKET_COUNT%"

call :TOGGLE_ALL BOPT %MAX_BUCKET% OFF
exit /b

:WHERE_SCOOP
where scoop >nul 2>&1 && exit /b 0
call :CHOICE "Scoop is not installed. Do you want to install it?"
if errorlevel 2 (
    echo. & echo Scoop is required for this script to work
	pause & exit /b 2
)

echo. & echo Installing Scoop via PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; irm get.scoop.sh | iex"

:: Update current session PATH so 'where scoop' works immediately without restarting CMD
set "PATH=%USERPROFILE%\scoop\shims;%PATH%"
where scoop >nul 2>&1
if errorlevel 1 (
    echo. & echo Installation failed or PATH not updated in this session
    pause & exit /b 1
)

echo. & call :CHOICE "Adding extras and versions buckets? (necessary to download all the packages on the list)"
if %errorlevel% equ 1 (
    echo. & echo Adding extras and versions buckets
    call scoop bucket add extras
    call scoop bucket add versions
)

call :ENSURE_TOOL "git" "mingit" "(necessary for updating Scoop and bucket)"
if %errorlevel% equ 0 (
    echo. & echo Tweaking Git settings
    for %%C in (
        "init.defaultBranch=main"
        "core.autocrlf=true"
        "pull.rebase=false"
    ) do (
        for /f "tokens=1,2 delims==" %%K in (%%C) do (
            call git config --global %%K %%L
        )
    )
)

call :ENSURE_TOOL "aria2c" "aria2" "(for multi-connection downloads)"
if %errorlevel% equ 0 (
    echo. & echo Tweaking aria2 settings
    for %%C in (
        "aria2-enabled=true"
        "aria2-warning-enabled=false"
        "aria2-split=8"
        "aria2-max-connection-per-server=8"
    ) do (
        for /f "tokens=1,2 delims==" %%K in (%%C) do (
            call scoop config %%K %%L
        )
    )
)
exit /b 0

:WHERE_7Z
if not defined HAS_7Z (
    where 7z.exe >nul 2>&1
    if errorlevel 1 (
        call scoop config use_external_7zip false >nul 2>&1
    ) else (
        call scoop config use_external_7zip true >nul 2>&1
    )
    set "HAS_7Z=1"
)
exit /b

:BULK_ADD_ACTION
set "type=%~1"
set "items=%~2"

echo.
if not defined items (
    echo. & echo No !type!s selected
    exit /b 1
)

cls & echo Selected !type!s:
for %%I in (!items!) do echo     - %%I

echo. & call :CHOICE "Do you want to continue?"
if errorlevel 2 (
    echo. & echo The operation was cancelled
    exit /b 2
)

echo.
if /i "!type!"=="package" (
    call :WHERE_7Z
    call scoop install -k !items!
) else (
    for %%B in (!items!) do call scoop bucket add %%B
    call :GO
)

exit /b 0

:PKG_BULK_ACTION
:: %1 = "upgrade" or "uninstall"
echo.
if not defined choice (
    echo No package selected
    exit /b 1
)

set "action=%~1"
set "cmd_targets=!choice:,= !"

if /i "!action!"=="upgrade" (
    set "verb=Updating"
) else (
    set "verb=Removing"
)
if /i "!choice!"=="ALL" (
    if /i "!action!"=="upgrade" (
        set "cmd_targets=*"
        echo !verb! all packages
    ) else (
		call :GET_SCOOP_NAMES cmd_targets "apps"
        echo !verb! all installed packages:
        for %%P in (!cmd_targets!) do echo     - %%P
    )
) else (
    echo !verb! the following packages:
    for %%P in (!cmd_targets!) do echo     - %%P
)

echo. & call :CHOICE "Do you want to continue?"
if errorlevel 2 (
    echo. & echo The operation was cancelled  
    exit /b 2
)

echo.
if /i "!action!"=="upgrade" (
    call scoop update -k !cmd_targets!
    call scoop cleanup !cmd_targets!
) else (
    call scoop uninstall !cmd_targets! --purge
)
exit /b 0

:GET_SCOOP_NAMES
:: Usage: call :GET_SCOOP_NAMES <return_var> <apps|buckets>
set "result="
for /f "usebackq delims=" %%L in (`powershell -NoProfile -Command "(scoop export | ConvertFrom-Json).%~2.Name" 2^>nul`) do (
    if not "%%L"=="" set "result=!result! %%L"
)
call set "%~1=%%result%%"
exit /b

:COLLECT_SELECTED
:: %1 = item-array prefix, %2 = opt-array prefix, %3 = max count, %4 = output var name
set "result="
for /L %%i in (1,1,%~3) do (
    if "!%~2%%i!"=="!ON!" (
        for %%V in (%~1%%i) do for /f "tokens=1 delims=|" %%A in ("!%%V!") do set "result=!result! %%A"
    )
)
call set "%~4=%%result%%"
exit /b

:RUN_FZF_SELECTOR
set "fzftmp=%TEMP%\fzf_selected_%RANDOM%.txt"
set "fzflist=%TEMP%\scoop_pkg_list_%RANDOM%.txt"
set "rawlist=%TEMP%\scoop_pkg_raw_%RANDOM%.txt"

del "%fzftmp%" "%fzflist%" "%rawlist%" >nul 2>&1

:: Data retrieval and list preparation
call scoop-search . > "%rawlist%" 2>nul

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

fzf --multi --ansi ^
    --prompt="Search> " ^
    --header="[TAB] multi-select | [ENTER] confirm | [ESC] cancel | [?] toggle preview" ^
    --bind "tab:toggle+down,shift-tab:toggle+up,?:toggle-preview" ^
    --preview "scoop info {1}" ^
    --preview-window=right:55%%:wrap ^
    < "%fzflist%" > "%fzftmp%"

if errorlevel 1 (
    del "%fzftmp%" "%fzflist%" "%rawlist%" >nul 2>&1
    exit /b 1
)

:: Extracting bucket/package names without leading spaces
set "selected_pkgs="
for /f "usebackq delims=" %%L in ("%fzftmp%") do (
    set "line=%%L"
    for /f "tokens=1" %%A in ("!line!") do (
        if defined selected_pkgs (
            set "selected_pkgs=!selected_pkgs! %%A"
        ) else (
            set "selected_pkgs=%%A"
        )
    )
)

:: Clean temporary files and save the result
del "%fzftmp%" "%fzflist%" "%rawlist%" >nul 2>&1
set "toInstall=%selected_pkgs%"
exit /b 0

:PRINT_ACTION_PROMPT
echo --------------------------------------------------------------------------------
echo Type ALL to %~1 everything
echo Or type the exact name(s) as shown above, separated by spaces
echo Type 0 to go back
echo --------------------------------------------------------------------------------
exit /b

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
exit /b

:ENSURE_TOOL
:: %1 = executable name to check with 'where'
:: If %3 is NOT given: %2 = description (package name = %1, same as exe name)
:: If %3 IS given:     %2 = scoop package name to install, %3 = description
set "exe=%~1"
where !exe! >nul 2>&1 && exit /b 0

if "%~3"=="" (
    set "pkg=%~1"
    set "desc=%~2"
) else (
    set "pkg=%~2"
    set "desc=%~3"
)

echo. & echo !pkg! !desc!
echo. & call :CHOICE "Do you want to install it?"
if errorlevel 2 exit /b 1

call :WHERE_7Z
echo. & call scoop install -k !pkg!
where !exe! >nul 2>&1
if %errorlevel% neq 0 (
    echo. & echo Failed to install !pkg! or PATH not updated in this session
    pause & exit /b 1
)
exit /b 0

:TOGGLE_ALL
:: %1 = opt-array prefix, %2 = max count, %3 = ON or OFF
set "val=!OFF!"
if /i "%~3"=="ON" set "val=!ON!"
for /L %%i in (1,1,%~2) do set "%~1%%i=!val!"
exit /b

:ADD_ITEM
:: %1 = counter variable name, %2 = item-array prefix, %3 = key, %4 = label
call set "cnt=%%%1%%"
set /a "cnt+=1"
call set "%1=%cnt%"
set "%2%cnt%=%~3|%~4"
exit /b

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
exit /b

:CHOICE
choice /C YN /N /M "%~1 [Y/n]: "
exit /b

:GO
echo. & echo The operation is done.
pause & exit /b
