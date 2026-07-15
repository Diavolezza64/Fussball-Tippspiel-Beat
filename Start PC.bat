@echo off
setlocal enabledelayedexpansion
:: Fussball Tippspiel - Daten aktualisieren (Windows)
:: Doppelklick auf diese Datei startet das Script.

chcp 65001 >nul
cd /d "%~dp0"

echo Fussball Tippspiel - Daten werden aktualisiert ...
echo ================================================
echo.

set PYTHON_CMD=

:: 1) py Launcher (empfohlen auf Windows)
where py >nul 2>&1
if %errorlevel%==0 (
    py -3 --version >nul 2>&1
    if !errorlevel!==0 (
        set PYTHON_CMD=py -3
        goto run_python
    )
)

:: 2) python3
where python3 >nul 2>&1
if %errorlevel%==0 (
    python3 --version >nul 2>&1
    if !errorlevel!==0 (
        set PYTHON_CMD=python3
        goto run_python
    )
)

:: 3) python - Microsoft Store Stub (WindowsApps) wird uebersprungen
for /f "delims=" %%p in ('where python 2^>nul') do (
    echo %%p | findstr /i "WindowsApps" >nul
    if !errorlevel!==1 (
        %%p --version 2>&1 | findstr /B "Python 3" >nul
        if !errorlevel!==0 (
            set PYTHON_CMD=%%p
            goto run_python
        )
    )
)

:: 4) Direkte Installationspfade pruefen (nach frueherer Installation)
for %%p in (
    "%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    "%ProgramFiles%\Python313\python.exe"
    "%ProgramFiles%\Python312\python.exe"
) do (
    if exist %%p ( set PYTHON_CMD=%%p & goto run_python )
)

:: Python nicht gefunden - automatisch installieren
echo Python 3 nicht gefunden. Wird jetzt installiert ...
echo.

set INSTALL_OK=0

:: Versuch 1: winget mit verschiedenen Paket-IDs
where winget >nul 2>&1
if %errorlevel%==0 (
    echo Versuche winget ...
    winget install --id Python.Python.3.13 --source winget --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
    if !errorlevel!==0 ( set INSTALL_OK=1 & goto after_install )
    winget install --id Python.Python.3.12 --source winget --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
    if !errorlevel!==0 ( set INSTALL_OK=1 & goto after_install )
)

:: Versuch 2: PowerShell-Download
echo Lade Python-Installer herunter (ca. 25 MB) ...
powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.13.3/python-3.13.3-amd64.exe' -OutFile '%TEMP%\python_setup.exe'" >nul 2>&1
if exist "%TEMP%\python_setup.exe" (
    echo Installiere Python ...
    "%TEMP%\python_setup.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
    if !errorlevel!==0 ( set INSTALL_OK=1 )
    del "%TEMP%\python_setup.exe" >nul 2>&1
)

:after_install
for %%p in (
    "%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    "%ProgramFiles%\Python313\python.exe"
    "%ProgramFiles%\Python312\python.exe"
) do (
    if exist %%p ( set PYTHON_CMD=%%p & goto run_python )
)

echo.
echo Python konnte nicht installiert werden.
echo Bitte manuell installieren: https://python.org
echo Beim Installieren "Add Python to PATH" anklicken.
echo Danach dieses Fenster neu starten.
goto done

:run_python
echo Python: %PYTHON_CMD%

:: Auto-Update: neueste Code-Version laden (nur wenn config\update_source.txt vorhanden)
if exist "config\update_source.txt" (
    set /p UPDATE_BASE=<"config\update_source.txt"
    echo Aktualisiere Code von GitHub ...
    for %%f in (wm_auto.py wm_chart.py gen_rangliste.py debug_zusatz.py fetch_em_archiv.py fetch_wm_archiv.py wm2026_squads.py) do (
        curl -sf --max-time 15 "!UPDATE_BASE!/tools/%%f" -o "tools\%%f" >nul 2>&1
        if !errorlevel!==0 echo   OK: %%f
    )
    curl -sf --max-time 30 "!UPDATE_BASE!/web/WM_Rangverlauf.html" -o "web\WM_Rangverlauf.html" >nul 2>&1
    if !errorlevel!==0 echo   OK: WM_Rangverlauf.html
    echo.
)

%PYTHON_CMD% tools\wm_auto.py

:: GitHub: Aenderungen automatisch pushen (nur wenn Git eingerichtet ist)
if exist ".git" (
    where git >nul 2>&1
    if !errorlevel!==0 (
        git add . >nul 2>&1
        git diff --cached --quiet >nul 2>&1
        if !errorlevel!==1 (
            git commit -m "Auto-Update %date% %time:~0,5%" >nul 2>&1
            git push >nul 2>&1
            if !errorlevel!==0 (
                echo GitHub aktualisiert
            ) else (
                echo GitHub-Push fehlgeschlagen ^(kein Internet?^)
            )
        )
    )
)

:open_browser
if exist "web\index.html" (
    start "" "web\index.html"
)

:done
echo.
echo ================================================
echo Fertig. Druecke eine Taste zum Schliessen ...
pause >nul
