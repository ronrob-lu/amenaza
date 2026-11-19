-- amenaza_core: Game state machine, 7-minute blackout timer, lighting/sky controller,
-- no-inventory / hearts-only HUD enforcement, spectator Game Over, and Victory handler.

amenaza_core = {}

local S = minetest.get_translator("amenaza_core")
local storage = minetest.get_mod_storage()
local BLACKOUT_SECONDS = tonumber(minetest.settings:get("amenaza_blackout_seconds")) or 420

-- ============================================================================
-- Localization Helpers (Auto client locale + optional /idioma or setting override)
-- ============================================================================

local function get_default_language()
    local cfg = minetest.settings:get("amenaza_language") or "auto"
    if cfg == "es" or cfg == "en" then
        return cfg
    end
    return "auto"
end

function amenaza_core.get_player_language(player_or_name)
    local pname = type(player_or_name) == "string" and player_or_name
        or (player_or_name and player_or_name:is_player() and player_or_name:get_player_name())
    if pname and pname ~= "" then
        local saved = storage:get_string("lang_" .. pname)
        if saved == "es" or saved == "en" or saved == "auto" then
            return saved
        end
    end
    return get_default_language()
end

function amenaza_core.set_player_language(player_name, lang)
    if lang == "es" or lang == "en" or lang == "auto" then
        storage:set_string("lang_" .. player_name, lang)
        return true
    end
    return false
end

function amenaza_core.localize(player_or_name, translated_str)
    local lang = amenaza_core.get_player_language(player_or_name)
    if (lang == "es" or lang == "en") and minetest.get_translated_string then
        return minetest.get_translated_string(lang, translated_str)
    end
    return translated_str
end

-- Persistent session state
local game_state = storage:get_string("state")
if game_state == "" then
    game_state = "dawn"
end
local elapsed_time = tonumber(storage:get_string("elapsed")) or 0
local dialogue_used = (storage:get_string("dialogue_used") == "true")

-- Per-player runtime tables
local spectators = {}
local overlay_huds = {}
local server_hum_handles = {}
local player_anim_state = {}
local daylight_override = false

local PLAYER_ANIMS = {
    stand     = { range = { x = 0,   y = 79  }, speed = 30 },
    walk      = { range = { x = 168, y = 187 }, speed = 30 },
    sneak     = { range = { x = 168, y = 187 }, speed = 15 },
    mine      = { range = { x = 189, y = 198 }, speed = 30 },
    walk_mine = { range = { x = 200, y = 219 }, speed = 30 },
}

local function update_player_animation(player)
    local name = player:get_player_name()
    if spectators[name] then return end
    local ctrl = player:get_player_control()
    local walking = ctrl.up or ctrl.down or ctrl.left or ctrl.right
    local acting = ctrl.LMB or ctrl.RMB

    local desired
    if walking and acting then
        desired = "walk_mine"
    elseif walking then
        desired = ctrl.sneak and "sneak" or "walk"
    elseif acting then
        desired = "mine"
    else
        desired = "stand"
    end

    if player_anim_state[name] ~= desired then
        player_anim_state[name] = desired
        local anim = PLAYER_ANIMS[desired]
        player:set_animation(anim.range, anim.speed, 0.1, true)
    end
end

-- Registered hooks for other mods (e.g. amenaza_npcs)
local blackout_callbacks = {}
local victory_callbacks = {}
local reset_callbacks = {}

function amenaza_core.get_state()
    return game_state
end

function amenaza_core.get_elapsed()
    return elapsed_time
end

function amenaza_core.get_blackout_progress()
    if BLACKOUT_SECONDS <= 0 then
        return 1
    end
    return math.min(1, math.max(0, elapsed_time / BLACKOUT_SECONDS))
end

function amenaza_core.is_dialogue_used()
    return dialogue_used
end

function amenaza_core.mark_dialogue_used()
    dialogue_used = true
    storage:set_string("dialogue_used", "true")
end

function amenaza_core.is_spectator(player_name)
    return spectators[player_name] == true
end

function amenaza_core.register_on_blackout(fn)
    table.insert(blackout_callbacks, fn)
end

function amenaza_core.register_on_victory(fn)
    table.insert(victory_callbacks, fn)
end

function amenaza_core.register_on_reset(fn)
    table.insert(reset_callbacks, fn)
end

local function save_state()
    storage:set_string("state", game_state)
    storage:set_string("elapsed", string.format("%.2f", elapsed_time))
    storage:set_string("dialogue_used", dialogue_used and "true" or "false")
end

-- ============================================================================
-- Override Empty Hand (No Inventory, No Digging, Clean World Interaction)
-- ============================================================================

minetest.override_item("", {
    wield_image = "amenaza_blank.png",
    wield_scale = { x = 0.01, y = 0.01, z = 0.01 },
    range = 4.5,
    tool_capabilities = {
        full_punch_interval = 0.8,
        max_drop_level = 0,
        groupcaps = {},
        damage_groups = { fleshy = 1 },
    },
})

-- ============================================================================
-- Skybox & Atmospheric Lighting Controller
-- ============================================================================

local DAWN_BASE_LIGHT_RATIO = 0.22
amenaza_core.DAWN_BASE_LIGHT_RATIO = DAWN_BASE_LIGHT_RATIO

function amenaza_core.set_dawn_ambient_ratio(ratio)
    if daylight_override or game_state ~= "dawn" then return end
    local r = math.max(0.08, math.min(0.45, ratio or DAWN_BASE_LIGHT_RATIO))
    for _, player in ipairs(minetest.get_connected_players()) do
        player:override_day_night_ratio(r)
    end
end

local function apply_atmosphere(player)
    if not player or not player:is_player() then return end

    if daylight_override then
        minetest.set_timeofday(0.42)
        player:override_day_night_ratio(1.0)
        player:set_sky({
            type = "regular",
            clouds = true,
            sky_color = {
                day_sky = "#6ea8e5",
                day_horizon = "#b8d7f5",
                dawn_sky = "#7ab0e8",
                dawn_horizon = "#d2e5f8",
                night_sky = "#6ea8e5",
                night_horizon = "#b8d7f5",
                indoors = "#8899aa",
            },
        })
        player:set_clouds({
            density = 0.35,
            color = "#f2f6fc",
            ambient = "#c8d4e6",
            height = 110,
            thickness = 12,
            speed = { x = 1.5, z = 0.5 },
        })
        player:set_sun({ visible = true, scale = 1.0 })
        player:set_moon({ visible = false })
        player:set_stars({ visible = false })
        return
    end

    if game_state == "dawn" then
        minetest.set_timeofday(0.205)
        player:override_day_night_ratio(DAWN_BASE_LIGHT_RATIO)
        player:set_sky({
            type = "regular",
            clouds = true,
            sky_color = {
                day_sky = "#24304a",
                day_horizon = "#4f4a5c",
                dawn_sky = "#1c2438",
                dawn_horizon = "#5e4a52",
                night_sky = "#0e121e",
                night_horizon = "#1e2230",
                indoors = "#181c24",
            },
        })
        player:set_clouds({
            density = 0.55,
            color = "#3b3e4f",
            ambient = "#1a1d28",
            height = 95,
            thickness = 14,
            speed = { x = 1.2, z = 0.4 },
        })
        player:set_sun({ visible = false })
        player:set_moon({ visible = true, scale = 0.8 })
        player:set_stars({ visible = true, count = 400 })
    elseif game_state == "blackout" then
        minetest.set_timeofday(0.01)
        player:override_day_night_ratio(0.05)
        player:set_sky({
            type = "plain",
            base_color = "#030408",
            clouds = false,
        })
        player:set_sun({ visible = false })
        player:set_moon({ visible = true, scale = 0.6 })
        player:set_stars({ visible = true, count = 200 })
    elseif game_state == "victory" then
        minetest.set_timeofday(0.36)
        player:override_day_night_ratio(1.0)
        player:set_sky({
            type = "regular",
            clouds = true,
            sky_color = {
                day_sky = "#6ea8e5",
                day_horizon = "#b8d7f5",
                dawn_sky = "#7ab0e8",
                dawn_horizon = "#d2e5f8",
                night_sky = "#6ea8e5",
                night_horizon = "#b8d7f5",
                indoors = "#8899aa",
            },
        })
        player:set_clouds({
            density = 0.35,
            color = "#f2f6fc",
            ambient = "#c8d4e6",
            height = 110,
            thickness = 12,
            speed = { x = 1.5, z = 0.5 },
        })
        player:set_sun({ visible = true, scale = 1.0 })
        player:set_moon({ visible = false })
        player:set_stars({ visible = false })
    end
end

local function apply_atmosphere_all()
    for _, player in ipairs(minetest.get_connected_players()) do
        apply_atmosphere(player)
    end
end

-- ============================================================================
-- Fast Area Sweep for Instant Lantern / Window / Data Center Transitions
-- ============================================================================

local function sweep_nodes_around(center, radius, swap_map)
    local minp = vector.subtract(center, { x = radius, y = 24, z = radius })
    local maxp = vector.add(center, { x = radius, y = 32, z = radius })
    local names = {}
    for k, _ in pairs(swap_map) do
        table.insert(names, k)
    end
    local positions = minetest.find_nodes_in_area(minp, maxp, names)
    for _, p in ipairs(positions) do
        local node = minetest.get_node(p)
        local target = swap_map[node.name]
        if target then
            minetest.swap_node(p, { name = target })
        end
    end
end

local function sweep_world_for_state(target_state)
    local swap_map
    if target_state == "blackout" then
        swap_map = {
            ["amenaza_nodes:lantern_on"] = "amenaza_nodes:lantern_off",
            ["amenaza_nodes:lantern_dim"] = "amenaza_nodes:lantern_off",
            ["amenaza_nodes:lantern_steady"] = "amenaza_nodes:lantern_off",
            ["amenaza_nodes:window_lit"] = "amenaza_nodes:window_dark",
            ["amenaza_nodes:window_dim"] = "amenaza_nodes:window_dark",
        }
    elseif target_state == "victory" then
        swap_map = {
            ["amenaza_nodes:lantern_on"] = "amenaza_nodes:lantern_steady",
            ["amenaza_nodes:lantern_dim"] = "amenaza_nodes:lantern_steady",
            ["amenaza_nodes:lantern_off"] = "amenaza_nodes:lantern_steady",
            ["amenaza_nodes:window_dim"] = "amenaza_nodes:window_lit",
            ["amenaza_nodes:server_rack_active"] = "amenaza_nodes:server_rack_shutdown",
            ["amenaza_nodes:datacenter_beacon"] = "amenaza_nodes:datacenter_beacon_off",
            ["amenaza_nodes:mainframe_core"] = "amenaza_nodes:mainframe_core_off",
        }
    elseif target_state == "dawn" then
        swap_map = {
            ["amenaza_nodes:lantern_steady"] = "amenaza_nodes:lantern_on",
            ["amenaza_nodes:lantern_off"] = "amenaza_nodes:lantern_on",
            ["amenaza_nodes:lantern_dim"] = "amenaza_nodes:lantern_on",
        }
    else
        return
    end

    for _, player in ipairs(minetest.get_connected_players()) do
        sweep_nodes_around(player:get_pos(), 72, swap_map)
    end
    if target_state == "victory" and amenaza_mapgen and amenaza_mapgen.CORE_POS then
        sweep_nodes_around(amenaza_mapgen.CORE_POS, 40, swap_map)
    end
end

-- ============================================================================
-- HUD Overlays (Game Over / Victory) & No-Inventory Enforcement
-- ============================================================================

local function clear_overlays(player)
    local name = player:get_player_name()
    local ids = overlay_huds[name]
    if ids then
        for _, id in ipairs(ids) do
            player:hud_remove(id)
        end
        overlay_huds[name] = nil
    end
end

local function show_banner(player, title, subtitle, color_hex)
    clear_overlays(player)
    local name = player:get_player_name()
    local ids = {}
    local hud_type_key = (minetest.has_feature and minetest.has_feature("hud_def_type_field"))
        and "type" or "hud_elem_type"

    local title_def = {
        [hud_type_key] = "text",
        position = { x = 0.5, y = 0.36 },
        alignment = { x = 0, y = 0 },
        text = amenaza_core.localize(player, title),
        number = color_hex,
        scale = { x = 100, y = 100 },
        size = { x = 3, y = 3 },
        style = 1,
    }
    table.insert(ids, player:hud_add(title_def))

    if subtitle and subtitle ~= "" then
        local sub_def = {
            [hud_type_key] = "text",
            position = { x = 0.5, y = 0.46 },
            alignment = { x = 0, y = 0 },
            text = amenaza_core.localize(player, subtitle),
            number = 0xE8ECEF,
            scale = { x = 100, y = 100 },
            size = { x = 1.3, y = 1.3 },
        }
        table.insert(ids, player:hud_add(sub_def))
    end

    overlay_huds[name] = ids
end

local function enforce_no_inventory(player)
    local inv = player:get_inventory()
    if inv then
        -- Keep 1 empty slot in "main" so Luanti's empty hand stays active for right-click interaction,
        -- while hiding the hotbar, wielditem, and inventory formspec completely.
        inv:set_size("main", 1)
        inv:set_list("main", { ItemStack("") })
        inv:set_size("craft", 0)
        inv:set_size("craftpreview", 0)
        inv:set_size("craftresult", 0)
    end
    player:set_inventory_formspec("")
    player:hud_set_flags({
        hotbar = false,
        healthbar = not spectators[player:get_player_name()],
        crosshair = not spectators[player:get_player_name()],
        wielditem = false,
        breathbar = false,
        minimap = false,
        minimap_radar = false,
    })
end

-- ============================================================================
-- Ending 2: Spectator / Ghost Death Mode ("GAME OVER")
-- ============================================================================

local function enter_spectator_mode(player)
    local name = player:get_player_name()
    if spectators[name] then return end
    spectators[name] = true

    -- Grant free-roaming spectator privileges
    local privs = minetest.get_player_privs(name)
    privs.fly = true
    privs.noclip = true
    privs.fast = true
    minetest.set_player_privs(name, privs)

    -- Make player invisible, immortal, non-colliding ghost
    player:set_armor_groups({ immortal = 1 })
    player:set_properties({
        visual_size = { x = 0, y = 0 },
        pointable = false,
        collide_with_objects = false,
        makes_footstep_sound = false,
        nametag = "",
    })
    player:set_physics_override({
        speed = 1.4,
        gravity = 0.2,
    })

    enforce_no_inventory(player)

    minetest.sound_play("amenaza_gameover", {
        to_player = name,
        gain = 0.9,
    }, true)

    show_banner(
        player,
        S("GAME OVER"),
        S("You fell in the darkness. Fly freely in Spectator Mode to observe the city."),
        0xE63946
    )
end

minetest.register_on_player_hpchange(function(player, hp_change, reason)
    if not player or not player:is_player() then
        return hp_change
    end
    local name = player:get_player_name()
    if spectators[name] or game_state == "victory" then
        return 0
    end
    local current_hp = player:get_hp()
    if current_hp + hp_change <= 0 then
        -- Intercept fatal damage to transition seamlessly into Spectator Mode
        minetest.after(0, function()
            local p = minetest.get_player_by_name(name)
            if p then
                enter_spectator_mode(p)
            end
        end)
        return 1 - current_hp
    end
    return hp_change
end, true)

-- Fallback if death still occurs via engine command
minetest.register_on_respawnplayer(function(player)
    enter_spectator_mode(player)
    return true
end)

-- ============================================================================
-- Phase 2: The 7-Minute Blackout Trigger
-- ============================================================================

function amenaza_core.trigger_blackout()
    if game_state ~= "dawn" then return end
    game_state = "blackout"
    save_state()

    minetest.sound_play("amenaza_blackout", { gain = 1.0 }, true)
    apply_atmosphere_all()
    sweep_world_for_state("blackout")

    for _, cb in ipairs(blackout_callbacks) do
        cb()
    end
end

-- ============================================================================
-- Ending 1: Victory (AI Mainframe Shut Down)
-- ============================================================================

function amenaza_core.trigger_victory(player, core_pos)
    if game_state == "victory" then return end
    if player and player:is_player() and spectators[player:get_player_name()] then
        return
    end

    game_state = "victory"
    save_state()

    if core_pos then
        minetest.swap_node(core_pos, { name = "amenaza_nodes:mainframe_core_off" })
    end

    -- Stop ambient server hums
    for pname, handle in pairs(server_hum_handles) do
        minetest.sound_stop(handle)
        server_hum_handles[pname] = nil
    end

    minetest.sound_play("amenaza_victory", { gain = 1.0 }, true)
    apply_atmosphere_all()
    sweep_world_for_state("victory")

    for _, cb in ipairs(victory_callbacks) do
        cb()
    end

    for _, p in ipairs(minetest.get_connected_players()) do
        p:set_armor_groups({ immortal = 1 })
        show_banner(
            p,
            S("VICTORY — SYSTEM SHUT DOWN"),
            S("The rogue mainframe is offline. Power has been restored across the city."),
            0x52D17A
        )
    end
end

-- ============================================================================
-- Player Join & Leave Handlers
-- ============================================================================

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    spectators[name] = false

    -- Ensure player starts cleanly at the plaza facing North (+Z) toward the crowd
    local spawn = (amenaza_mapgen and amenaza_mapgen.SPAWN_POS) or { x = 0, y = 2, z = -28 }
    if not storage:get_string("joined_" .. name):find("1") then
        player:set_pos(spawn)
        player:set_look_horizontal(0) -- Face North (+Z) toward the protest crowd
        player:set_look_vertical(0)
        storage:set_string("joined_" .. name, "1")
    end

    -- Reset non-spectator privileges
    local privs = minetest.get_player_privs(name)
    privs.fly = nil
    privs.noclip = nil
    privs.fast = nil
    minetest.set_player_privs(name, privs)

    player:set_hp(20)
    player:set_armor_groups({ fleshy = 100 })
    player:set_properties({
        visual = "mesh",
        mesh = "character.b3d",
        textures = { "character.png" },
        visual_size = { x = 1, y = 1 },
        pointable = true,
        collide_with_objects = true,
        makes_footstep_sound = true,
    })

    enforce_no_inventory(player)
    apply_atmosphere(player)
    player_anim_state[name] = "stand"
    player:set_animation(PLAYER_ANIMS.stand.range, PLAYER_ANIMS.stand.speed, 0.1, true)

    if game_state == "victory" then
        player:set_armor_groups({ immortal = 1 })
        show_banner(
            player,
            S("VICTORY — SYSTEM SHUT DOWN"),
            S("The rogue mainframe is offline. Power has been restored across the city."),
            0x52D17A
        )
    end
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    if server_hum_handles[name] then
        minetest.sound_stop(server_hum_handles[name])
        server_hum_handles[name] = nil
    end
    overlay_huds[name] = nil
    player_anim_state[name] = nil
end)

-- ============================================================================
-- Global Step: 7-Minute Countdown, Player Animation & Data Center Proximity Hum
-- ============================================================================

local save_accum = 0
local hum_accum = 0

minetest.register_globalstep(function(dtime)
    local players = minetest.get_connected_players()
    if #players == 0 then return end

    for _, player in ipairs(players) do
        update_player_animation(player)
    end

    if game_state == "dawn" then
        elapsed_time = elapsed_time + dtime
        save_accum = save_accum + dtime
        if save_accum >= 5.0 then
            save_accum = 0
            save_state()
        end
        if elapsed_time >= BLACKOUT_SECONDS then
            amenaza_core.trigger_blackout()
        end
    end

    -- Subtle server room hum when inside or near the AI Data Center
    hum_accum = hum_accum + dtime
    if hum_accum >= 1.5 then
        hum_accum = 0
        local core_pos = amenaza_mapgen and amenaza_mapgen.CORE_POS
        if core_pos then
            for _, player in ipairs(players) do
                local name = player:get_player_name()
                local dist = vector.distance(player:get_pos(), core_pos)
                if game_state ~= "victory" and dist < 38 then
                    if not server_hum_handles[name] then
                        server_hum_handles[name] = minetest.sound_play("amenaza_server_hum", {
                            to_player = name,
                            gain = 0.35,
                            loop = true,
                        })
                    end
                else
                    if server_hum_handles[name] then
                        minetest.sound_stop(server_hum_handles[name])
                        server_hum_handles[name] = nil
                    end
                end
            end
        end
    end
end)

-- ============================================================================
-- Language & Admin / Testing Commands
-- ============================================================================

local function handle_language_command(caller_name, param)
    local arg = (param or ""):lower():match("^%s*(.-)%s*$")
    if arg == "" then
        local cur = amenaza_core.get_player_language(caller_name)
        return true, amenaza_core.localize(
            caller_name,
            S("Current language: @1. Usage: /idioma [auto|es|en] or /lang [auto|es|en]", cur)
        )
    end
    if arg == "es" or arg == "español" or arg == "espanol" or arg == "spanish" then
        arg = "es"
    elseif arg == "en" or arg == "english" or arg == "ingles" or arg == "inglés" then
        arg = "en"
    elseif arg ~= "auto" then
        return false, amenaza_core.localize(
            caller_name,
            S("Invalid language '@1'. Use: auto, es, or en.", arg)
        )
    end

    amenaza_core.set_player_language(caller_name, arg)

    -- Refresh active HUD banner immediately if present
    local player = minetest.get_player_by_name(caller_name)
    if player then
        if spectators[caller_name] then
            show_banner(
                player,
                S("GAME OVER"),
                S("You fell in the darkness. Fly freely in Spectator Mode to observe the city."),
                0xE63946
            )
        elseif game_state == "victory" then
            show_banner(
                player,
                S("VICTORY — SYSTEM SHUT DOWN"),
                S("The rogue mainframe is offline. Power has been restored across the city."),
                0x52D17A
            )
        end
    end

    if arg == "es" then
        return true, amenaza_core.localize(caller_name, S("Language set to Spanish."))
    elseif arg == "en" then
        return true, amenaza_core.localize(caller_name, S("Language set to English."))
    else
        return true, amenaza_core.localize(caller_name, S("Language set to automatic (client locale)."))
    end
end

minetest.register_chatcommand("idioma", {
    params = "[auto|es|en]",
    description = S("Change game language (auto, es, en)"),
    privs = {},
    func = handle_language_command,
})

minetest.register_chatcommand("lang", {
    params = "[auto|es|en]",
    description = S("Change game language (auto, es, en)"),
    privs = {},
    func = handle_language_command,
})

minetest.register_chatcommand("amenaza_blackout", {
    description = S("Immediately trigger the citywide blackout phase"),
    privs = { server = true },
    func = function(caller_name)
        if game_state ~= "dawn" then
            return false, amenaza_core.localize(caller_name, S("Current state is already: @1", game_state))
        end
        elapsed_time = BLACKOUT_SECONDS
        amenaza_core.trigger_blackout()
        return true, amenaza_core.localize(caller_name, S("Blackout triggered."))
    end,
})

minetest.register_chatcommand("amenaza_daylight", {
    params = "[on|off]",
    description = S("Toggle bright daylight override (for screenshots)"),
    privs = { server = true },
    func = function(caller_name, param)
        local arg = (param or ""):lower():match("^%s*(.-)%s*$")
        if arg == "" then
            daylight_override = not daylight_override
        elseif arg == "on" or arg == "1" or arg == "true" or arg == "day" then
            daylight_override = true
        elseif arg == "off" or arg == "0" or arg == "false" or arg == "normal" then
            daylight_override = false
        else
            return false, amenaza_core.localize(
                caller_name,
                S("Invalid option '@1'. Usage: /amenaza_daylight [on|off]", arg)
            )
        end

        apply_atmosphere_all()

        if daylight_override then
            return true, amenaza_core.localize(caller_name, S("Daylight override enabled."))
        else
            return true, amenaza_core.localize(caller_name, S("Daylight override disabled; normal lighting restored."))
        end
    end,
})

minetest.register_chatcommand("amenaza_reset", {
    description = S("Reset Amenaza session back to Dawn"),
    privs = { server = true },
    func = function(caller_name)
        game_state = "dawn"
        elapsed_time = 0
        dialogue_used = false
        daylight_override = false
        save_state()

        local spawn = (amenaza_mapgen and amenaza_mapgen.SPAWN_POS) or { x = 0, y = 2, z = -28 }
        for _, p in ipairs(minetest.get_connected_players()) do
            local pname = p:get_player_name()
            spectators[pname] = false
            clear_overlays(p)
            local privs = minetest.get_player_privs(pname)
            privs.fly = nil
            privs.noclip = nil
            privs.fast = nil
            minetest.set_player_privs(pname, privs)

            p:set_pos(spawn)
            p:set_look_horizontal(0)
            p:set_hp(20)
            p:set_armor_groups({ fleshy = 100 })
            p:set_physics_override({ speed = 1.0, gravity = 1.0 })
            p:set_properties({
                visual = "mesh",
                mesh = "character.b3d",
                textures = { "character.png" },
                visual_size = { x = 1, y = 1 },
                pointable = true,
                collide_with_objects = true,
                makes_footstep_sound = true,
            })
            enforce_no_inventory(p)
            apply_atmosphere(p)
        end

        sweep_world_for_state("dawn")

        for _, cb in ipairs(reset_callbacks) do
            cb()
        end
        return true, amenaza_core.localize(caller_name, S("Session reset to Dawn."))
    end,
})
