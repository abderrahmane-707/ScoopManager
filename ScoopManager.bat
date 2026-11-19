@echo off
setlocal enabledelayedexpansion

:: External list files
set "PKG_FILE=%~dp0packages.txt"
set "BUCKET_FILE=%~dp0buckets.txt"

call :CHECK_ADMIN
if errorlevel 1 exit /b 1

call :WHERE_SCOOP
if errorlevel 1 exit /b 1

:: Initialize
set "ON=(YES)"
set "OFF=(NO)"

call :INIT_PACKAGES
if errorlevel 1 (pause & exit /b 1)

:: Main interface
:SCOOP_MENU
cls
echo.
echo                                                 \\^^!//
echo                                                 (o o)
echo              -------------------------------oOOo-(_)-oOOo-------------------------------
echo                                         Scoop Package Manager
echo              ---------------------------------------------------------------------------
echo.
call :RENDER_COLUMNS PL OPT %MAX_PKG%

echo.
echo    [U] Update Packages
echo    [R] Remove Packages
echo    [B] Manage Buckets
echo    [M] More
echo    [I] Info
echo.
echo              ---------------------------------------------------------------------------
echo.
echo                    [A] Select All            [D] Deselect All            [0] Exit
echo.

echo Tip: You can select multiple items, e.g. 1,3,5 or 1-5 or 1-3,7,10-12
set "choice=" & set /p "choice=--> Select option(s) and press [S] to Start: "

if not defined choice goto SCOOP_MENU
if "!choice!"=="0" exit /b
if /i "!choice!"=="S" goto RUN_PACKAGES
if /i "!choice!"=="A" (call :TOGGLE_ALL OPT %MAX_PKG% ON & goto SCOOP_MENU)
if /i "!choice!"=="D" (call :TOGGLE_ALL OPT %MAX_PKG% OFF & goto SCOOP_MENU)
if /i "!choice!"=="U" goto UPDATE_MENU
if /i "!choice!"=="R" goto REMOVE_MENU
if /i "!choice!"=="B" goto BUCKET_INITIAL
if /i "!choice!"=="M" goto MORE_PKG
if /i "!choice!"=="I" goto PKG_INFO

call :MULTI_INPUT OPT %MAX_PKG%
goto SCOOP_MENU

:PKG_INFO
:: Lists every package from packages.txt with its key and bucket
cls
echo.
echo    Packages in the list and the bucket each one belongs to
echo    ---------------------------------------------------------------------------
echo.
set "used= "
for /L %%i in (1,1,%MAX_PKG%) do (
    set "ikey=!PK%%i!"
    set "ibucket=!PB%%i!"
    if not defined ibucket if not "!ikey:/=!"=="!ikey!" for /f "tokens=1 delims=/" %%A in ("!ikey!") do set "ibucket=%%A"
    if not defined ibucket set "ibucket=?"
    for %%B in (!ibucket!) do if "!used: %%B =!"=="!used!" set "used=!used!%%B "
    set "inum=   %%i"
    set "c1=!PL%%i!                                   "
    set "c2=!ikey!                                   "
    echo    [!inum:~-3!] !c1:~0,26! !c2:~0,22! !ibucket!
)
echo.
echo    ---------------------------------------------------------------------------
echo.
pause
goto SCOOP_MENU

:RUN_PACKAGES
:: Collect every selected package into a single list, then process it
call :COLLECT_SELECTED "PK" "OPT" "%MAX_PKG%" "toInstall"

call :BULK_ADD_ACTION "package" "!toInstall!"
if errorlevel 1 (pause & goto SCOOP_MENU)

call :GO & call :TOGGLE_ALL OPT %MAX_PKG% OFF & goto SCOOP_MENU

:UPDATE_MENU
cls
call scoop update
call scoop status

call :PRINT_ACTION_PROMPT "update"

set "choice=" & set /p "choice=--> "
if not defined choice goto SCOOP_MENU
if "!choice!"=="0" goto SCOOP_MENU

call :PKG_BULK_ACTION "upgrade"
if errorlevel 1 (pause & goto SCOOP_MENU)

call :GO & goto SCOOP_MENU

:REMOVE_MENU
cls
call scoop list

call :PRINT_ACTION_PROMPT "remove"

set "choice=" & set /p "choice=--> "
if not defined choice goto SCOOP_MENU
if "!choice!"=="0" goto SCOOP_MENU

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
if errorlevel 1 (pause & goto SCOOP_MENU)

:BUCKET_MENU
cls & echo.
echo                                                 \\^^!//
echo                                                 (o o)
echo              -------------------------------oOOo-(_)-oOOo-------------------------------
echo                                            Buckets Manager
echo              ---------------------------------------------------------------------------
echo.

call :RENDER_COLUMNS BK BOPT %MAX_BUCKET%

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

if not defined choice goto BUCKET_MENU
if "!choice!"=="0" goto SCOOP_MENU
if /i "!choice!"=="A" (call :TOGGLE_ALL BOPT %MAX_BUCKET% ON & goto BUCKET_MENU)
if /i "!choice!"=="D" (call :TOGGLE_ALL BOPT %MAX_BUCKET% OFF & goto BUCKET_MENU)
if /i "!choice!"=="U" goto UPDATE_BUCKETS
if /i "!choice!"=="S" goto ADD_BUCKETS
if /i "!choice!"=="R" goto REMOVE_BUCKETS

call :MULTI_INPUT BOPT %MAX_BUCKET%
goto BUCKET_MENU

:ADD_BUCKETS
call :COLLECT_SELECTED "BK" "BOPT" "%MAX_BUCKET%" "toAddBuckets"

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
if "!choice!"=="0" goto BUCKET_MENU

if /i "!choice!"=="ALL" (
    call :GET_SCOOP_NAMES tormBuckets "buckets"
    if not defined tormBuckets (
        echo. & echo Could not read the installed buckets list
        pause & goto BUCKET_MENU
    )
    echo. & echo Removing all installed buckets:
) else (
    set "tormBuckets=!choice:,= !"
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

:CHECK_ADMIN
:: Warn when running elevated
set "IS_ADMIN="
fltmc >nul 2>&1 && set "IS_ADMIN=1"
if not defined IS_ADMIN exit /b 0

echo.
echo [WARNING] This script is running as Administrator.
echo           Scoop is designed for per-user installs: its installer refuses to
echo           run elevated and packages may end up with wrong permissions.
echo           Close this window and run it from a normal terminal.
echo.
pause & exit /b 1

:WHERE_SCOOP
where scoop >nul 2>&1 && exit /b 0
call :CHOICE "Scoop is not installed. Do you want to install it?"
if errorlevel 2 (
    echo. & echo Scoop is required for this script to work
    pause & exit /b 2
)

echo. & echo Installing Scoop via PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm get.scoop.sh | iex"

:: Update current session PATH so 'where scoop' works immediately without restarting CMD
call :SET_SCOOP_PATH
where scoop >nul 2>&1
if errorlevel 1 (
    echo. & echo Installation failed or PATH not updated in this session
    pause & exit /b 1
)

call :ENSURE_TOOL "git" "mingit" "(necessary for updating Scoop and bucket)"
if defined JUST_INSTALLED (
    echo. & echo Tweaking Git settings
    for %%C in (
        "init.defaultBranch=main"
        "core.autocrlf=true"
        "pull.rebase=false"
        "core.longpaths=true"
        "push.autoSetupRemote=true"
        "fetch.prune=true"
        "merge.conflictStyle=zdiff3"
    ) do (
        for /f "tokens=1,2 delims==" %%K in (%%C) do (
            call git config --global %%K %%L
        )
    )
)

call :ENSURE_TOOL "aria2c" "aria2" "((Optional) for multi-connection downloads)"
echo. & echo Tweaking aria2 settings
    for %%C in (
        "aria2-enabled=true"
        "aria2-warning-enabled=false"
        "aria2-split=8"
        "aria2-max-connection-per-server=8"
        "aria2-min-split-size=10M"
        "aria2-retry-wait=3"
    ) do (
        for /f "tokens=1,2 delims==" %%K in (%%C) do (
            call scoop config %%K %%L
        )
    )

exit /b 0

:SET_SCOOP_PATH
:: Order: %SCOOP% (if defined) -> user-level SCOOP value stored by the installer -> default location
set "SCOOP_DIR=%SCOOP%"
if not defined SCOOP_DIR for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v SCOOP 2^>nul ^| findstr /i "REG_"') do call set "SCOOP_DIR=%%B"
if not defined SCOOP_DIR set "SCOOP_DIR=%USERPROFILE%\scoop"
set "PATH=!SCOOP_DIR!\shims;!PATH!"
exit /b 0

:INIT_PACKAGES
call :LOAD_LIST "%PKG_FILE%" PKG_COUNT PK PL PB
if errorlevel 1 exit /b 1
set "MAX_PKG=%PKG_COUNT%"
call :TOGGLE_ALL OPT %MAX_PKG% OFF
exit /b 0

:INIT_BUCKET
call :LOAD_LIST "%BUCKET_FILE%" BUCKET_COUNT BK BL "" nodefault
if errorlevel 1 exit /b 1
set "MAX_BUCKET=%BUCKET_COUNT%"
call :TOGGLE_ALL BOPT %MAX_BUCKET% OFF
exit /b 0

:LOAD_LIST
:: %1 = list file, %2 = counter var, %3 = key-array prefix, %4 = label/url-array prefix
:: %5 = third-field array prefix (optional, use "" to skip): bucket name for packages
:: %6 = "nodefault" (optional): leave the second field empty when it is missing
:: File format: key|second|third   (second and third are optional)
:: Empty lines and lines starting with # are ignored
:: Result: <key-prefix>N = key, <label-prefix>N = second field, <third-prefix>N = third field
set "%~2=0"
if not exist "%~1" (
    echo. & echo List file not found: %~1
    exit /b 1
)

for /f "usebackq eol=# delims=" %%R in ("%~1") do (
    set "lkey="
    set "llabel="
    set "lbucket="
    set "lline=%%R|-|-"
    for /f "tokens=1,2,3 delims=|" %%A in ("!lline!") do (
        for %%K in (%%A) do set "lkey=%%K"
        for /f "tokens=* delims= " %%Z in ("%%B") do set "llabel=%%Z"
        for %%K in (%%C) do set "lbucket=%%K"
    )
    if defined lkey (
        if "!llabel!"=="-" set "llabel="
        if "!lbucket!"=="-" set "lbucket="
        if not defined llabel if /i not "%~6"=="nodefault" set "llabel=!lkey!"
        set /a "%~2+=1"
        set "%~3!%~2!=!lkey!"
        set "%~4!%~2!=!llabel!"
        if not "%~5"=="" set "%~5!%~2!=!lbucket!"
    )
)

exit /b 0

:WHERE_7Z
:: Checked on every call so it stays correct after 7zip gets installed in this session
where 7z.exe >nul 2>&1
if errorlevel 1 (
    call scoop config use_external_7zip false >nul 2>&1
) else (
    call scoop config use_external_7zip true >nul 2>&1
)
exit /b 0

:BUCKET_URL
:: %1 = bucket key -> sets 'burl' (empty for official buckets)
set "burl="
for /L %%i in (1,1,!MAX_BUCKET!) do if /i "!BK%%i!"=="%~1" set "burl=!BL%%i!"
exit /b 0

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
set "failed="
if /i "!type!"=="package" (
    call :WHERE_7Z
    for %%I in (!items!) do (
        call scoop install -k %%I
        if errorlevel 1 set "failed=!failed! %%I"
    )
) else (
    for %%B in (!items!) do (
        call :BUCKET_URL %%B
        call scoop bucket add %%B !burl!
        if errorlevel 1 set "failed=!failed! %%B"
    )
)

if defined failed (
    echo. & echo The following !type!s failed:
    for %%F in (!failed!) do echo     - %%F
)

if /i "!type!"=="bucket" call :GO
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
        if not defined cmd_targets (
            echo Could not read the installed packages list
            exit /b 1
        )
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
    call :WHERE_7Z
    call scoop update -k !cmd_targets!
    call scoop cleanup -k !cmd_targets!
) else (
    call scoop uninstall !cmd_targets! --purge
)
exit /b 0

:GET_SCOOP_NAMES
set "result="
for /f "usebackq delims=" %%L in (`scoop export 2^>nul ^| powershell -NoProfile -ExecutionPolicy Bypass -Command "($input | Out-String | ConvertFrom-Json).%~2.Name" 2^>nul`) do (
    if not "%%L"=="" set "result=!result! %%L"
)
call set "%~1=%%result%%"
exit /b

:COLLECT_SELECTED
:: %1 = key-array prefix, %2 = opt-array prefix, %3 = max count, %4 = output var name
set "result="
for /L %%i in (1,1,%~3) do (
    if "!%~2%%i!"=="!ON!" (
        for %%V in (%~1%%i) do set "result=!result! !%%V!"
    )
)
call set "%~4=%%result%%"
exit /b

:RUN_FZF_SELECTOR
set "fzftmp=%TEMP%\fzf_selected_%RANDOM%.txt"
set "fzflist=%TEMP%\scoop_pkg_list_%RANDOM%.txt"

del "%fzftmp%" "%fzflist%" >nul 2>&1

cls & echo Loading package list...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$b=$null; scoop-search . 2>$null | ForEach-Object { if ($_ -match '^\x27([^\x27]+)\x27') { $b=$Matches[1] } elseif ($b -and $_.Trim()) { $b + '/' + $_.Trim() } }" > "%fzflist%"

for %%F in ("%fzflist%") do if %%~zF equ 0 (
    echo. & echo scoop-search returned no packages
    del "%fzflist%" >nul 2>&1
    pause & exit /b 1
)

fzf --multi --ansi ^
    --prompt="Search> " ^
    --header="[TAB] multi-select | [ENTER] confirm | [ESC] cancel | [?] toggle preview" ^
    --bind "tab:toggle+down,shift-tab:toggle+up,?:toggle-preview" ^
    --preview "scoop info {1}" ^
    --preview-window=right:55%%:wrap ^
    < "%fzflist%" > "%fzftmp%"

if errorlevel 1 (
    del "%fzftmp%" "%fzflist%" >nul 2>&1
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
del "%fzftmp%" "%fzflist%" >nul 2>&1
set "toInstall=%selected_pkgs%"
exit /b 0

:PRINT_ACTION_PROMPT
echo.
echo --------------------------------------------------------------------------------
echo Type ALL to %~1 everything
echo Or type the exact name(s) as shown above, separated by spaces
echo Type 0 to go back
echo --------------------------------------------------------------------------------
exit /b

:RENDER_COLUMNS
:: %1 = display-array prefix, %2 = opt-array prefix, %3 = max count
set "lprefix=%~1"
set "oprefix=%~2"
set "mx=%~3"
set /a "ROWS=(mx+2)/3"
for /L %%r in (1,1,!ROWS!) do (
    set "line="
    for %%x in (1 2 3) do (
        set /a "idx=%%r+ROWS*(%%x-1)"
        set "cell=                         "
        if !idx! leq !mx! (
            for %%V in (!lprefix!!idx!) do for %%W in (!oprefix!!idx!) do (
                set "cell=  [!idx!] !%%V!"
                if "!%%W!"=="!ON!" set "cell=* [!idx!] !%%V!"
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
:: Sets JUST_INSTALLED=1 only when this call actually installed the tool
set "JUST_INSTALLED="
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
if errorlevel 2 exit /b 2

call :WHERE_7Z
echo. & call scoop install -k !pkg!
where !exe! >nul 2>&1
if %errorlevel% neq 0 (
    echo. & echo Failed to install !pkg! or PATH not updated in this session
    pause & exit /b 1
)
set "JUST_INSTALLED=1"
exit /b 0

:TOGGLE_ALL
:: %1 = opt-array prefix, %2 = max count, %3 = ON or OFF
set "val=!OFF!"
if /i "%~3"=="ON" set "val=!ON!"
for /L %%i in (1,1,%~2) do set "%~1%%i=!val!"
exit /b

:MULTI_INPUT
set "prefix=%~1"
set "max_count=%~2"
set "invalid="
set "tokens=!choice:,= !"

for %%G in (!tokens!) do (
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
choice /C YN /N /M "%~1 [Y/N]: "
exit /b

:GO
echo. & echo The operation is done.
pause & exit /b
