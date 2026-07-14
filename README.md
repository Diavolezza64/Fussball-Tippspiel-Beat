# Fussball Tippspiel Beat

Automatisches Auswertungs-Tool für Tippgruppen auf [wmtippspiel.srf.ch](https://wmtippspiel.srf.ch).

Liest die Tipps aller Gruppenmitglieder aus, erstellt eine Rangliste, einen Rangverlauf-Chart und ein interaktives Dashboard.

---

## Schnellstart

### 1. Herunterladen

Grüner **Code**-Button oben rechts → **Download ZIP** → Entpacken in einen Ordner deiner Wahl.

### 2. Gruppe eintragen

Die Datei `config/gruppen.txt` öffnen und die URL-Nummer deiner Tippgruppe eintragen.

Die Nummer findest du, indem du auf wmtippspiel.srf.ch deine Tippgruppe öffnest – die Zahl in der URL ist die ID:
```
https://wmtippspiel.srf.ch/communities/26455
                                         ↑
                                    Diese Nummer
```

Eintragen in `config/gruppen.txt`:
```
/communities/26455
```

### 3. Im Browser einloggen

**Windows:** Auf [wmtippspiel.srf.ch](https://wmtippspiel.srf.ch) in **Microsoft Edge** einloggen (empfohlen, da vorinstalliert).  
**Mac:** In **Safari** oder **Chrome** einloggen.

Den Login einmalig durchführen – das Script liest die gespeicherte Session automatisch aus.

### 4. Starten

**Mac:** `Start Mac.command` doppelklicken  
**Windows:** `Start PC.bat` doppelklicken

Python wird automatisch installiert falls noch nicht vorhanden.

---

## Was wird generiert?

| Datei | Inhalt |
|-------|--------|
| `web/WM_Rangverlauf.html` | Interaktives Dashboard (Rangliste, Tipps, Verlauf) |
| `data/WM_Tipps_DATUM.csv` | Alle Tipps aller Mitglieder |
| `data/WM_Rangverlauf_DATUM.csv` | Punkteverlauf pro Spieltag |
| `output/WM_Rangliste_DATUM.pdf` | Druckbare Rangliste |
| `output/WM_Chart_DATUM.pdf` | Rangverlauf als Chart |

Das Dashboard öffnet sich nach dem Start automatisch im Browser.

---

## Mehrere Gruppen

In `config/gruppen.txt` einfach mehrere Zeilen eintragen – alle Mitglieder landen in einer gemeinsamen Rangliste:

```
/communities/26455
/communities/12345
```

---

## Voraussetzungen

- Mac oder Windows PC
- Safari oder Chrome mit aktivem Login auf wmtippspiel.srf.ch
- Internetverbindung

Python und alle weiteren Abhängigkeiten werden beim ersten Start automatisch installiert.
