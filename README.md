# muteCat QOL

`muteCat QOL` ist ein schlankes Blizzard-UI-Addon für WoW `12.0.1`.
Es läuft ohne Optionsfenster und aktiviert alle Funktionen automatisch.

## Funktionen

- Actionbar-Desaturierung für Cooldowns/Unbenutzbarkeit
- Aufgeräumte Blizzard-Button-Overlays und Border
- Stack-Text-Styling (inkl. Sonderregel für Bar 4)
- Stance-Bar-Logik (Hide bei definierter Stance)
- Objective-Tracker-Header + Minimize-Button ausblenden
- Micro-Menü: `30%` Alpha, bei Mouseover `100%`
- Bags-Bar dauerhaft ausblenden
- Buffbar: bei Mouseover einblenden, sonst nach `1s` ausblenden
- WorldMap verschiebbar + Position persistent (inkl. TomTom-Overlay)
- Combat-Text-Hide über aktuelle CVar-Logik
- Standard-CVars für Kamera/QoL werden beim Start gesetzt

## Actionbar-Verhalten

- Bar 1/2/3/5: Mouseover sofort sichtbar, Mouseout nach `1s` ausblenden (ohne Fade)
- Bar 4: außerhalb Combat `30%`, im Combat `100%`
- Bar 6/7/8: gemountet ausblenden, in Dungeon/Raid auch gemountet sichtbar

## Befehle

- `/mcqol lock` -> WorldMap sperren
- `/mcqol unlock` -> WorldMap entsperren
- Alias: `/mutecatqol lock`, `/mutecatqol unlock`

## Gesetzte CVars (Auszug)

- `cameraReduceUnexpectedMovement = 1`
- `cameraYawSmoothSpeed = 180`
- `cameraPitchSmoothSpeed = 180`
- `cameraIndirectOffset = 0`
- `test_cameraDynamicPitch = 0`
- `cameraIndirectVisibility = 1`
- `AutoPushSpellToActionBar = 0`
- `UnitNamePlayerGuild = 0`
- `UnitNamePlayerPVPTitle = 0`
- `UnitNameGuildTitle = 0`
- `ResampleAlwaysSharpen = 1`

## Installation

1. Ordner `muteCatQOL` nach `World of Warcraft/_retail_/Interface/AddOns/` kopieren.
2. Spiel starten oder `/reload`.
3. Addon `muteCat QOL` aktivieren.

## SavedVariables

- `muteCatQOLDB`