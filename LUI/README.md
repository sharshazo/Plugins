# LUI

LUI is a custom user interface plugin for The Lord of the Rings Online. It focuses on cleaner combat frames, sharper text and borders, and precise control over layout, colors, fonts, thresholds, and scaling.

## Table of Contents

- [Features](#features)
- [What LUI Replaces](#what-lui-replaces)
- [Installation](#installation)
- [Commands](#commands)
- [FAQ](#faq)
- [Status Bar API](#status-bar-api)
- [Configuration Notes](#configuration-notes)
- [Scaling Notes](#scaling-notes)
- [Limitations](#limitations)
- [Known Issues](#known-issues)
- [Recent fixes to verify](#recent-fixes-to-verify)
- [Acknowledgements](#acknowledgements)
- [Support](#support)

## Features

- Self, target, boss, fellowship, and raid vitals
- Target's target vitals
- Buff and debuff tracking on combat frames
- Expiring effect countdown bars for self and target
- Cooldown tracker with thresholds, whitelist and blacklist support
- Inventory window with optional default backpack replacement
- Assets window for server-wide item holdings across characters
- Crafting browser with recipe search, source filters, favorites, recursive ingredient breakdowns, per-character tracked plans, and bestiary search links for supported client languages
- Status bar widgets for local time, inventory space, money, crafting shortcuts, tracked crafting resources, and more planned
- Encyclopedia (bestiary, equipment, resources, consumables, housing, and traceries browsing), bestiary cards, and optional bestiary capture on English clients
- First-run quick setup to get you up and running quickly
- Profile management so multiple characters can reuse or switch configurations
- Localized UI strings for English, German, and French
- Fine-grained control over colors, sizes, fonts, text formats, thresholds, number abbreviations, refresh rate, and window positions. Explore `/lui config`.
- Precise move mode tools, including a grid, numeric positioning, and keyboard nudging

## What LUI Replaces

- Default player vitals
- Default target vitals
- Default fellowship and raid vitals
- Default backpack windows when inventory replacement is enabled

## Installation

### Method 1: from the ZIP file

1. Download the latest release from the [GitHub releases page](https://github.com/Geldahr/LUI/releases).
2. Extract it into `C:\Users\<your user>\Documents\The Lord of the Rings Online\Plugins`.
3. Keep the archive's folder structure intact. Do not flatten or rename the shipped folders.
4. In-game, load the plugin from the Plugin Manager.

### Method 2: from the batch installer

1. Download the latest batch installer release from the [GitHub releases page](https://github.com/Geldahr/LUI/releases).
2. Execute it to replace any existing `LUI` folder and install the files automatically to `C:\Users\<your user>\Documents\The Lord of the Rings Online\Plugins`.
3. In-game, load the plugin from the Plugin Manager.

### Method 3: from Git

If you install from source instead of a release ZIP or batch installer:

```bash
# WSL
mkdir "/mnt/c/Users/<your user>/Documents/The Lord of the Rings Online/Plugins"
cd "/mnt/c/Users/<your user>/Documents/The Lord of the Rings Online/Plugins"
git clone https://github.com/Geldahr/LUI.git
```

## Commands

- `/lui help` - Show the available commands
- `/lui config` - Toggle the configuration window
- `/lui move` - Toggle move mode
- `/lui move cancel` - Leave move mode without saving the current positions
- `/lui inventory` or `/lui inv` - Toggle the inventory window
- `/lui assets` or `/lui a` - Toggle the assets window
- `/lui craft` - Toggle the crafting window
- `/lui bestiary`, `/lui beast`, or `/lui b` - Toggle the bestiary window
- `/lui card [monster name]` - Open the bestiary card for a monster
- `/lui api.sb --add -k "key" -t "Title" [-d "Description"] -i "0x11223344|path/to/icon.tga" -c "/command args"` - Register a status bar API button

## FAQ

### How do I configure LUI after the first setup?

Use `/lui config` for detailed settings and `/lui move` to position windows and combat frames. Use `/lui help` in game to see the available commands.

### Can I install LUI with LOTRO Plugin Compendium?

Yes. Current releases include Plugin Compendium metadata, so Plugin Compendium can download and load LUI. Manual installation still works; keep the shipped folder structure intact.

### Why do I still see a built-in vitals frame after LUI loads?

LUI hides the built-in player, target, fellowship, and raid vitals when those replacements are enabled. If a native frame comes back after login but disappears after saving LUI settings, another UI or vitals plugin may be re-enabling the native LotRO vitals after LUI loads. Try disabling other UI/vitals plugins to confirm the conflict.

### How do I hide the built-in target-of-target frame?

LUI cannot disable that frame directly through the plugin API. Disable it in LotRO under `Options > Combat Options > Show the vitals of your selection's target`.

### Can LUI hide the native pet vitals?

No. Native pet vitals cannot be hidden properly through the plugin like the other built-in vitals. As a workaround, reduce their size in the LotRO settings and move them under the minimap so they are effectively not visible.

### Why is Bestiary capture only available on English clients?

Bestiary capture needs game text to match LUI's structured Bestiary data, which is keyed by English names. On French and German clients, target-vitals double-click cards work through a localized name bridge, and Bestiary content is displayed translated where the game data provides a label (untranslated details stay English); Crafting-to-Bestiary links are disabled.

### Why does the Bestiary show deed information but not my deed completion?

LUI can show deed information that exists in its Bestiary data, but LotRO does not expose reliable character deed completion state to plugins.

### Why do some monster or item details not appear?

Some details, such as monster rank, difficulty, aggressive/passive state, item sources, and gathering locations, are not directly exposed by the LotRO plugin API. LUI can only show that information when it has its own structured data for it.

## Status Bar API

Other plugins can register status bar buttons through `import "LUI.api"` and `LUI.api.StatusBar.add({...})`.

```lua
import "LUI.api"

local request, err = LUI.api.StatusBar.add({
    key = "something:config",
    title = "My plugin Config",
    description = "Open My plugin configuration window",
    image = 0x411BBF59, -- icon id
    command = "/my_plugin configuration",
})
```

- `key` is required and becomes the layout token name, for example `%something:config%`.
- `title` is required, used in the status bar edit palette, and is limited to 20 characters.
- `description` is optional, used in layout help, and is limited to 40 characters.
- `image` is required and accepts an integer image id, a hex id such as `0x411BBF59`, or a `.tga` path.
- `command` is required and must be a full slash command, including any arguments.
- Duplicate registrations using the same `key` are ignored.

When an item is registered, it becomes available in two places:

- The status bar layout help as `%key% - description` or `%key% - title` when no description is provided.
- The status bar edit window palette using the short `title`.

## Configuration Notes

- On first launch, LUI opens a quick setup flow for UI scale and a default top or bottom layout.
- The global LUI scale is separate from the built-in LotRO UI scale.
- Profile management is available from the configuration window and lets multiple characters share or switch settings.
- Shared UI styling is available under `Global > UI`; see [Global UI Style Settings Reference](GLOBAL_STYLE_SETTINGS_REFERENCE.md).
- Bestiary capture is only available on English clients.

## Scaling Notes

LUI uses pixel-based scaling instead of LotRO UI scaling. That keeps borders and fonts sharper, but fractional values still snap to the nearest renderable size.

- `1 px` at `1.35` scale is still `1 px`
- Font sizes snap to the nearest available LotRO font size
- Border widths are rounded to the nearest rendered pixel

## Limitations

- Automatic item locking based on a whitelist or blacklist is not currently possible through the LotRO API.
- Bestiary capture is restricted to English clients.
- Bestiary data is keyed by English names; on French and German clients, names and details are displayed translated where the game data provides a label, and the rest stays English. Bestiary search and Crafting-to-Bestiary links remain English-only.
- Translations are not up to date.

## Known Issues

- Target effect tracking can behave incorrectly when the target is the local player. This has not been seen since February 26, 2026.
- If you use labels that include level, they may not refresh when the target or a group member levels up unless morale or power also changes.

## Recent fixes to verify

- A recent fix addressed an edge case where targeting another player in your fellowship did not immediately populate the target effect list. In the broken state, buffs and debuffs could remain empty, fail to appear, disappear, or update only after that player gained or lost an effect. If you still see delayed or inconsistent effect initialization when switching to a fellowship target, please report it.

## Acknowledgements

- See [Attributions](ATTRIBUTIONS.md) for third-party data credits, Lotro-Wiki data licensing, and the unofficial fan project disclaimer.

## Support

Performance issues are considered critical, and I will address them as quickly as possible.

For bug reports, feature requests, or latest release downloads, use the [GitHub repository](https://github.com/Geldahr/LUI).
