# muteCat QOL

`muteCat QOL` is a lightweight Blizzard UI quality-of-life addon for WoW `12.0.1`.
It is always-on (no options panel) and applies all features automatically.

## Features

- Action button cooldown/desaturation tuning for Blizzard bars
- Cleaner Blizzard button borders/overlays
- Stack count styling and custom anchor rules
- Stance bar visibility logic (hide on configured stance)
- Micro menu alpha: `30%` idle, `100%` on mouseover
- Bags bar permanently hidden
- Buff bar mouseover visibility with hide delay
- World Map movable with persistent saved position
- TomTom world frame supported as map drag source
- Floating combat text disabled via updated CVar handling
- Edit Mode live coordinate overlay integrated (LibEditMode-first)
- Service channel auto-leave logic (trade channel remains)
- Startup QoL camera/interface CVar profile

## Action Bar Behavior

- Bars `1/2/3/5`: show instantly on mouseover, hide after `1s` delay (no fade)
- Bar `4`: `30%` alpha out of combat, `100%` in combat
- Bars `6/7/8`: hidden while mounted, but remain visible while mounted inside dungeon/raid

## Commands

- `/mcqol lock` -> lock World Map position
- `/mcqol unlock` -> unlock World Map position
- Aliases: `/mutecatqol lock`, `/mutecatqol unlock`

## Default CVars (highlights)

- `cameraReduceUnexpectedMovement = 1`
- `cameraIndirectOffset = 0`
- `cameraIndirectVisibility = 1`
- `AutoPushSpellToActionBar = 0`
- `UnitNamePlayerGuild = 0`
- `UnitNamePlayerPVPTitle = 0`
- `UnitNameGuildTitle = 0`
- `ResampleAlwaysSharpen = 1`

## Installation

1. Copy the `muteCatQOL` folder to `World of Warcraft/_retail_/Interface/AddOns/`.
2. Start the game or run `/reload`.
3. Enable `muteCat QOL` in the AddOns menu.

## SavedVariables

- `muteCatQOLDB`
