# muteCat QOL

`muteCat QOL` ist ein Blizzard-UI Quality-of-Life Addon fuer WoW `12.0.1`.

Das Addon ist bewusst "always on" (ohne Optionsfenster) und kombiniert mehrere kleine UI-Anpassungen in einem Paket.

## Features

### Actionbars / Cooldown Look

- Cooldown-Desaturate fuer Blizzard-Actionbuttons
- Border-/Overlay-Aufraeumung fuer Blizzard-Buttons
- Stack-Text Styling (inkl. Ausnahmen fuer bestimmte Bars)
- Range/Not-Targetable Overlay-Hide (ohne Stack-Anzeige zu verlieren)

### Actionbar Visibility

- Bar 1/2/3/5:
  - Mouseover: sofort einblenden
  - Mouseout: `1s` Verzoegerung, dann sofort ausblenden (kein Fade)
- Bar 4:
  - ausserhalb Combat: `30%` Alpha
  - im Combat: `100%` Alpha
- Bar 6/7/8:
  - gemountet: sofort ausblenden
  - nicht gemountet: sofort einblenden

### Stance Bar

- Stance-Bar wird automatisch ausgeblendet, wenn die definierte Stance aktiv ist (aktuell ueber `spellID = 465`)
- Combat-sicheres Verhalten

### Tracker

- "All Objectives" Header im Objective Tracker ausgeblendet
- Minimize-Button des Tracker-Headers ausgeblendet/deaktiviert

### Micro Menu / Bags / Buffbar

- Micro Menu: `30%` Alpha, bei Mouseover `100%`
- BagsBar: dauerhaft ausgeblendet
- Buffbar: standardmaessig ausgeblendet, bei Mouseover sichtbar, danach `1s` Delay bis wieder ausgeblendet

### World Map Mover + Persistenz

- WorldMap ist beweglich
- Position wird ueber Reload/Restart gespeichert (`SavedVariables`)
- Lock/Unlock fuer map movement
- TomTom-Overlay (`TomTomWorldFrame`) wird als Drag-Quelle mitberuecksichtigt

## Commands

### WorldMap Lock/Unlock

- `/mcqol unlock`
  - WorldMap ist verschiebbar
- `/mcqol lock`
  - WorldMap wird gesperrt (nicht mehr verschiebbar), Position bleibt gespeichert

Alias:

- `/mutecatqol lock`
- `/mutecatqol unlock`

Wenn du nur `/mcqol` eingibst, zeigt das Addon die Kurz-Hilfe.

## Installation

1. Ordner `muteCatQOL` nach `World of Warcraft/_retail_/Interface/AddOns/` kopieren.
2. Spiel neu starten oder `/reload`.
3. `muteCat QOL` im AddOn-Menue aktivieren.

## SavedVariables

- `muteCatQOLDB`

## Dateien (Modularisierung)

- `muteCatQOL_Core.lua`
- `muteCatQOL_Action.lua`
- `muteCatQOL_Bars.lua`
- `muteCatQOL_Stance.lua`
- `muteCatQOL_Tracker.lua`
- `muteCatQOL_UI.lua`
- `muteCatQOL_Map.lua`