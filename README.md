# Amenaza

**An atmospheric survival thriller set in a darkened neoclassical city facing an imminent threat.**

*Entry for the **2026 Luanti Game Jam** (built for Luanti 5.18.0).*

---

## Overview & Core Objective

You arrive at dawn in the Grand Central Plaza of a vast, walled neoclassical city. Something is wrong—an uneasy crowd has gathered, the city feels on edge, and a looming threat hangs over everyone.

Your task is to uncover what is happening and stop the threat before time runs out:

1. **Talk to the crowd:** Right-click (or punch) people in the plaza and streets to learn what is going on and gather leads on where to go.
2. **Explore and navigate:** Use your top-right **HUD Compass** and pay attention to visual and environmental clues throughout the city.
3. **Act before it's too late:** Time is limited—find the source of the threat and stop it before the situation spirals out of control.

There is no inventory, crafting, or block-breaking—only exploration, investigation, and survival against the clock.

---

## Controls & Chat Commands

### Controls

| Action | Default Key / Input |
|---|---|
| Move | `W` `A` `S` `D` |
| Jump | `Space` |
| Sneak | `Shift` |
| Talk to NPCs / Interact | `Right-Click` or `Left-Click` (Punch) |
| Fly (Spectator Mode after Game Over) | `K` (toggle fly), `Space` (up), `Shift` (down) |

### Player Chat Commands

| Command | Description |
|---|---|
| `/idioma [auto\|en\|es\|pt\|de]` | Switch game language between automatic client locale, English (`en`), Spanish (`es`), Portuguese (`pt`), and German (`de`). |
| `/lang [auto\|en\|es\|pt\|de]` | Alias for `/idioma`. |
| `/compass [0-8]` | Toggle or reposition the HUD compass (`0` = off, `1–4` = compass only in NE/SE/SW/NW corner, `5–8` = compass + 24h clock). |

### Server / Testing Commands (requires `server` privilege)

| Command | Description |
|---|---|
| `/amenaza_daylight [on\|off]` | Toggle a bright daylight sky and lighting override (for screenshots and visual inspection). |
| `/amenaza_blackout` | Immediately trigger the late-game crisis phase (for testing). |
| `/amenaza_reset` | Reset the session back to the start and respawn the starting plaza crowd. |

---

## Installation & How to Play (Luanti 5.18.0)

1. Install **Luanti 5.18.0** (or any version ≥ 5.8).
2. Clone or copy this repository into your Luanti `games/` directory as `amenaza`:
   - **Linux:** `~/.minetest/games/amenaza`
   - **macOS:** `~/Library/Application Support/minetest/games/amenaza`
   - **Windows:** `<luanti_dir>\games\amenaza`
3. Launch Luanti, select **Amenaza** from the game bar at the bottom of the main menu, create a **New World**, and click **Play Game**.
   - All mapgen (`singlenode`), spawnpoint, damage, and compass defaults are pre-configured automatically via `game.conf` and `minetest.conf`.

### Optional Settings (`settingtypes.txt`)

You can tune gameplay parameters in Luanti's **Settings → All Settings → Games → Amenaza**:
- `amenaza_blackout_seconds` (default `420`): Countdown duration in seconds before the threat escalates.
- `amenaza_crowd_size` (default `84`): Target number of people in the starting plaza.
- `amenaza_city_crowd_size` (default `90`): Target number of roaming and standing NPCs around the player across the city.
- `amenaza_language` (default `auto`): Default language override (`auto`, `en`, `es`, `pt`, `de`).

---

## License, AI Disclosure & Attribution

### Licensing Summary

Amenaza is completely free and open-source software with ContentDB-compatible licenses across all code and media:

- **Amenaza Source Code (`mods/amenaza_*`):** MIT License — Copyright (c) 2026 `ronrob-lu`.
- **Amenaza Original Graphics & Menu Art (`mods/amenaza_nodes/textures/*`, `mods/amenaza_core/textures/*`, `mods/amenaza_npcs/textures/amenaza_sign_*.png`, `menu/*`):** CC BY-SA 4.0 — Copyright (c) 2026 `ronrob-lu`.
- **NPC Skins (`mods/amenaza_npcs/textures/Skin_*.png`, `npc_character_*.png`):** CC0 1.0 Universal — `isaiah658` and `ronrob-lu`.
- **Sound Effects (`mods/amenaza_core/sounds/*.ogg`):** CC0 1.0 Universal.
- **Minetest Default Character Model & Texture (`character.b3d`, `character.png`):** LGPL-2.1-or-later (code) / CC BY-SA 3.0 (media) — Minetest Game contributors.
- **HUD Compass (`mods/amenaza_compass`):** MIT License (code) / CC BY-SA 3.0 (textures) — adapted from David G (`kestral246`)'s `hud_compass`, with compass textures derived from `tacotexmex`'s `ccompass` mod.

See [LICENSE](LICENSE) for full license texts and [CREDITS.md](CREDITS.md) for the complete file-by-file attribution table.

### AI Disclosure

In accordance with transparent development and jam disclosure norms:
- Lua code for the `amenaza_*` mods was created by `ronrob-lu` with assistance from **AI (Gemini 4 Neon)**.
- All sound effects in `mods/amenaza_core/sounds/` were **AI-generated** and are dedicated to the public domain under **CC0 1.0 Universal**.
