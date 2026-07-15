@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ╔══════════════════════════════════════════════════════════╗
echo ║  GitHub einrichten – einmalige Konfiguration            ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

:: Git prüfen
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo FEHLER: Git ist nicht installiert.
    echo Bitte von https://git-scm.com herunterladen und installieren.
    echo Danach dieses Script nochmals starten.
    pause
    exit /b 1
)

echo Schritt 1: GitHub Benutzername
echo    (z.B. daniel-muster)
set /p GH_USER=Benutzername: 

echo.
echo Schritt 2: Repository-Name
echo    (z.B. Fussball-Tippspiel-Daniel)
set /p GH_REPO=Repository-Name: 

echo.
echo Schritt 3: GitHub Token
echo    Erstellen unter: github.com → Settings → Developer Settings
echo    → Personal access tokens → Tokens (classic) → Generate new token
echo    Berechtigungen: repo (alles ankreuzen)
set /p GH_TOKEN=Token einfügen: 

echo.
echo Konfiguriere Git ...

:: Token und Repo speichern (gitignored)
echo %GH_TOKEN%> config\github_token.txt
echo %GH_USER%/%GH_REPO%> config\github_repo.txt

:: Git initialisieren falls nötig
if not exist ".git" (
    git init -b main >nul 2>&1
    echo   ✓ Git Repository initialisiert
)

:: Remote setzen
git remote remove origin >nul 2>&1
git remote add origin https://%GH_TOKEN%@github.com/%GH_USER%/%GH_REPO%.git
echo   ✓ Remote gesetzt: github.com/%GH_USER%/%GH_REPO%

:: Git Identität setzen
git config user.email "%GH_USER%@github.com" >nul 2>&1
git config user.name "%GH_USER%" >nul 2>&1

:: Erster Push
echo.
echo Lade Dateien auf GitHub ...
git add . >nul 2>&1
git commit -m "Ersteinrichtung" >nul 2>&1
git push -u origin main >nul 2>&1
if %errorlevel%==0 (
    echo   ✓ Erfolgreich auf GitHub geladen!
    echo.
    echo GitHub Pages aktivieren:
    echo   → github.com/%GH_USER%/%GH_REPO%
    echo   → Settings → Pages → Branch: main → /root → Save
    echo.
    echo Dashboard-URL: https://%GH_USER%.github.io/%GH_REPO%/web/WM_Rangverlauf.html
) else (
    echo   FEHLER beim Push. Bitte Token und Repository-Name prüfen.
)

echo.
pause
