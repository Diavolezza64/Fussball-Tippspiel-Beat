#!/bin/bash
# ──────────────────────────────────────────────────────────────
# Fussball Tippspiel – Daten aktualisieren (Mac)
# Doppelklick im Finder startet dieses Script im Terminal.
#
# Einmalig ausführbar machen (einmal im Terminal eingeben):
#   chmod +x "Start Mac.command"
# ──────────────────────────────────────────────────────────────

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "🏆 Fussball Tippspiel – Daten werden aktualisiert …"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Auto-Update: neueste Code-Version laden (nur wenn config/update_source.txt vorhanden)
UPDATE_SRC="$DIR/config/update_source.txt"
if [ -f "$UPDATE_SRC" ]; then
    BASE=$(tr -d '[:space:]' < "$UPDATE_SRC")
    echo "→ Code-Update von $BASE …"
    TOOLS="wm_auto.py wm_chart.py gen_rangliste.py debug_zusatz.py fetch_em_archiv.py fetch_wm_archiv.py wm2026_squads.py"
    UPDATED=0
    for f in $TOOLS; do
        if curl -sf --max-time 15 "$BASE/tools/$f" -o "$DIR/tools/$f.tmp" 2>/dev/null; then
            mv "$DIR/tools/$f.tmp" "$DIR/tools/$f"
            UPDATED=$((UPDATED + 1))
        else
            rm -f "$DIR/tools/$f.tmp"
        fi
    done
    if [ $UPDATED -gt 0 ]; then
        echo "   ✓ $UPDATED Dateien aktualisiert"
    else
        echo "   (offline oder keine Änderungen)"
    fi
    echo ""
fi

# Python 3 suchen
if command -v python3 &>/dev/null; then
    python3 tools/wm_auto.py
elif command -v python &>/dev/null; then
    python tools/wm_auto.py
else
    echo "❌  Python 3 nicht gefunden."
    echo "    Bitte von https://python.org installieren."
fi

echo ""

# GitHub: Änderungen automatisch pushen (nur wenn Git eingerichtet ist)
if [ -d ".git" ] && command -v git &>/dev/null; then
    git add . &>/dev/null
    if ! git diff --cached --quiet; then
        DATUM=$(date '+%Y-%m-%d %H:%M')
        git commit -m "Auto-Update $DATUM" &>/dev/null && \
        git push &>/dev/null && \
        echo "✅ GitHub aktualisiert" || \
        echo "⚠️  GitHub-Push fehlgeschlagen (kein Internet?)"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Dashboard im Browser öffnen
if [ -f "web/index.html" ]; then
    open "web/index.html"
fi

echo "Drücke Enter zum Schliessen …"
read -r
