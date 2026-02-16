# muteCat QOL

`muteCat QOL` is a Blizzard UI quality-of-life addon for WoW `12.0.1`.

The addon is intentionally "always on" (no options panel) and bundles multiple small UI tweaks in one package.

## Features

### Actionbars / Cooldown Look

- Cooldown desaturation for Blizzard action buttons
- Border/overlay cleanup for Blizzard buttons
- Stack text styling (including exceptions for specific bars)
- Hides range/not-targetable overlays without losing stack display

### Actionbar Visibility

- Bar 1/2/3/5:
  - Mouseover: show instantly
  - Mouseout: `1s` delay, then hide instantly (no fade)
- Bar 4:
  - out of combat: `30%` alpha
  - in combat: `100%` alpha
- Bar 6/7/8:
  - mounted: hide instantly
  - unmounted: show instantly

### Stance Bar

- Stance bar hides automatically while the configured stance is active (currently `spellID = 465`)
- Combat-safe behavior

### Tracker

- Hides the "All Objectives" header in the Objective Tracker
- Hides/disables the tracker header minimize button

### Micro Menu / Bags / Buff Bar

- Micro menu: `30%` alpha, `100%` on mouseover
- Bags bar: permanently hidden
- Buff bar: hidden by default, shown on mouseover, then hidden again after `1s` delay

### World Map Mover + Persistence

- World map is movable
- Position persists across reload/restart (`SavedVariables`)
- Lock/unlock support for map movement
- TomTom overlay (`TomTomWorldFrame`) is supported as a drag source

## Commands

### World Map Lock/Unlock

- `/mcqol unlock`
  - World map is movable
- `/mcqol lock`
  - World map is locked (not movable), saved position is preserved

Aliases:

- `/mutecatqol lock`
- `/mutecatqol unlock`

Typing only `/mcqol` shows a short help message.

## Installation

1. Copy the `muteCatQOL` folder to `World of Warcraft/_retail_/Interface/AddOns/`.
2. Restart the game or run `/reload`.
3. Enable `muteCat QOL` in the AddOns menu.

## SavedVariables

- `muteCatQOLDB`

## Files (Modular)

- `muteCatQOL_Core.lua`
- `muteCatQOL_Action.lua`
- `muteCatQOL_Bars.lua`
- `muteCatQOL_Stance.lua`
- `muteCatQOL_Tracker.lua`
- `muteCatQOL_UI.lua`
- `muteCatQOL_Map.lua`
