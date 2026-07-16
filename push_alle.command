#!/bin/bash
# ──────────────────────────────────────────────────────────────
# push_alle.command
# Beat's Master-Repo pushen + allgemeine Files an alle Satellites verteilen
# ──────────────────────────────────────────────────────────────

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR" || exit 1

echo "🚀 Master-Push + Satellite-Update"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1) Beat's Repo pushen ─────────────────────────────────────
echo "→ Beat's Master-Repo wird gepusht …"
git add -A
if git diff --cached --quiet; then
    echo "   (keine lokalen Änderungen zum Committen)"
else
    git commit -m "Update $(date '+%Y-%m-%d %H:%M')"
fi
if git push; then
    echo "   ✅ Beat's GitHub aktualisiert"
else
    echo "   ❌ Push fehlgeschlagen"
    echo ""; echo "Drücke Enter zum Schliessen …"; read -r; exit 1
fi
echo ""

# ── 2) Satellites aktualisieren ───────────────────────────────
SATELLITES_FILE="$DIR/config/satellites.txt"
if [ ! -f "$SATELLITES_FILE" ]; then
    echo "⚠️  config/satellites.txt nicht gefunden – keine Satellites"
    echo ""; echo "Drücke Enter zum Schliessen …"; read -r; exit 0
fi

# Allgemeine Files – KEIN wm_auto.py (bleibt satellite-spezifisch)
# Keine Config-Files (teilnehmer.json, gruppen.txt etc.)
TOOL_FILES="wm_chart.py gen_rangliste.py debug_zusatz.py fetch_em_archiv.py fetch_wm_archiv.py wm2026_squads.py find_gruppe.py"

TOTAL=0
FAILED=0

while IFS= read -r REPO || [ -n "$REPO" ]; do
    # Leere Zeilen und Kommentare überspringen
    [[ -z "$REPO" || "$REPO" == \#* ]] && continue

    TOTAL=$((TOTAL + 1))
    REPO_NAME=$(basename "$REPO")
    echo "→ Satellite: $REPO"

    TMP=$(mktemp -d)

    if ! git clone "https://github.com/$REPO.git" "$TMP/$REPO_NAME" 2>/dev/null; then
        echo "   ❌ Klonen fehlgeschlagen"
        rm -rf "$TMP"
        FAILED=$((FAILED + 1))
        echo ""
        continue
    fi

    cd "$TMP/$REPO_NAME" || { rm -rf "$TMP"; continue; }

    # Tools kopieren
    UPDATED=0
    for f in $TOOL_FILES; do
        if [ -f "$DIR/tools/$f" ]; then
            cp "$DIR/tools/$f" "tools/$f" 2>/dev/null && UPDATED=$((UPDATED + 1))
        fi
    done

    # config/find_gruppe.py (Zusatzfragen-Automatismus)
    if [ -f "$DIR/config/find_gruppe.py" ]; then
        cp "$DIR/config/find_gruppe.py" "config/find_gruppe.py" 2>/dev/null && UPDATED=$((UPDATED + 1))
    fi

    # WM_Rangverlauf.html (Template mit aktuellem Layout)
    if [ -f "$DIR/web/WM_Rangverlauf.html" ]; then
        cp "$DIR/web/WM_Rangverlauf.html" "web/WM_Rangverlauf.html" 2>/dev/null && UPDATED=$((UPDATED + 1))
    fi

    # Start Mac.command aktualisieren (inkl. config/find_gruppe.py Download)
    python3 - <<'PYEOF'
import os, stat
base = os.environ.get('MASTER_BASE', 'https://raw.githubusercontent.com/Diavolezza64/Fussball-Tippspiel-Beat/main')
new_cmd = f"""\
#!/bin/bash
# ──────────────────────────────────────────────────────────────
# Fussball Tippspiel – Daten aktualisieren (Mac)
# ──────────────────────────────────────────────────────────────

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "🏆 Fussball Tippspiel – Daten werden aktualisiert …"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Auto-Update: neueste Code-Version vom Master-Repo laden
FALLBACK_BASE="{base}"
UPDATE_SRC="$DIR/config/update_source.txt"
if [ -f "$UPDATE_SRC" ]; then
    BASE=$(tr -d '[:space:]' < "$UPDATE_SRC")
    if [[ "$BASE" != https://* ]]; then
        BASE="$FALLBACK_BASE"
    fi
else
    BASE="$FALLBACK_BASE"
fi

echo "→ Code-Update vom Master …"
TOOLS="wm_chart.py gen_rangliste.py debug_zusatz.py fetch_em_archiv.py fetch_wm_archiv.py wm2026_squads.py"
UPDATED=0
for f in $TOOLS; do
    if curl -sf --max-time 15 "$BASE/tools/$f" -o "$DIR/tools/$f.tmp" 2>/dev/null; then
        mv "$DIR/tools/$f.tmp" "$DIR/tools/$f"
        UPDATED=$((UPDATED + 1))
    else
        rm -f "$DIR/tools/$f.tmp"
    fi
done
# config/find_gruppe.py (Zusatzfragen-Automatismus)
if curl -sf --max-time 15 "$BASE/config/find_gruppe.py" -o "$DIR/config/find_gruppe.py.tmp" 2>/dev/null; then
    mv "$DIR/config/find_gruppe.py.tmp" "$DIR/config/find_gruppe.py"
    UPDATED=$((UPDATED + 1))
else
    rm -f "$DIR/config/find_gruppe.py.tmp"
fi
if curl -sf --max-time 30 "$BASE/web/WM_Rangverlauf.html" -o "$DIR/web/WM_Rangverlauf.html.tmp" 2>/dev/null; then
    mv "$DIR/web/WM_Rangverlauf.html.tmp" "$DIR/web/WM_Rangverlauf.html"
    UPDATED=$((UPDATED + 1))
else
    rm -f "$DIR/web/WM_Rangverlauf.html.tmp"
fi
if curl -sf --max-time 15 "$BASE/web/index.html" -o "$DIR/web/index.html.tmp" 2>/dev/null; then
    mv "$DIR/web/index.html.tmp" "$DIR/web/index.html"
    UPDATED=$((UPDATED + 1))
else
    rm -f "$DIR/web/index.html.tmp"
fi
if [ $UPDATED -gt 0 ]; then
    echo "   ✓ $UPDATED Dateien aktualisiert"
else
    echo "   (offline oder keine Änderungen)"
fi
echo ""

# Python 3 suchen und wm_auto.py starten
if command -v python3 &>/dev/null; then
    python3 tools/wm_auto.py
elif command -v python &>/dev/null; then
    python tools/wm_auto.py
else
    echo "❌  Python 3 nicht gefunden."
    echo "    Bitte von https://python.org installieren."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Dashboard öffnen
if [ -f "web/index.html" ]; then
    open "web/index.html"
fi

echo "Drücke Enter zum Schliessen …"
read -r
"""
with open('Start Mac.command', 'w', encoding='utf-8') as f:
    f.write(new_cmd)
st = os.stat('Start Mac.command')
os.chmod('Start Mac.command', st.st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
print("   ✅ Start Mac.command aktualisiert")
PYEOF
    UPDATED=$((UPDATED + 1))

    git config user.email "b.nauer@bluewin.ch"
    git config user.name "Beat Nauer"
    git add -A

    if git diff --cached --quiet; then
        echo "   (keine Änderungen – alles aktuell)"
    else
        git commit -m "Master-Update $(date '+%Y-%m-%d %H:%M')" 2>/dev/null
        if git push 2>/dev/null; then
            echo "   ✅ $UPDATED Dateien aktualisiert und gepusht"
        else
            echo "   ❌ Push fehlgeschlagen"
            FAILED=$((FAILED + 1))
        fi
    fi

    rm -rf "$TMP"
    cd "$DIR" || exit 1
    echo ""
done < "$SATELLITES_FILE"

# ── Zusammenfassung ───────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $FAILED -eq 0 ]; then
    echo "✅ Fertig – $TOTAL Satellite(s) aktualisiert"
else
    echo "⚠️  $FAILED von $TOTAL Satellite(s) fehlgeschlagen"
fi
echo ""
echo "Drücke Enter zum Schliessen …"
read -r
