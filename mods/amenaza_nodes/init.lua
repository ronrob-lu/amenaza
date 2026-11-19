-- amenaza_nodes: All custom blocks, blinking street lanterns, power cables,
-- neoclassical architectural nodes, and AI Data Center hardware.

amenaza_nodes = {}

local S = minetest.get_translator("amenaza_nodes")

local function register_static(name, def)
    if def.description then
        def.description = S(def.description)
    end
    def.diggable = false
    def.pointable = def.pointable or false
    def.drop = ""
    def.is_ground_content = false
    def.groups = def.groups or { unbreakable = 1 }
    def.groups.unbreakable = 1
    minetest.register_node("amenaza_nodes:" .. name, def)
end

-- ============================================================================
-- World Foundation, Perimeter & Park Elements
-- ============================================================================

register_static("bedrock", {
    description = "City Foundation",
    tiles = { "amenaza_bedrock.png" },
})

register_static("perimeter_wall", {
    description = "City Perimeter Barrier",
    tiles = { "amenaza_perimeter_wall.png" },
})

register_static("park_grass", {
    description = "Park Lawn",
    tiles = { "amenaza_park_grass.png" },
})

register_static("park_gravel", {
    description = "Park Promenade Gravel",
    tiles = { "amenaza_park_gravel.png" },
})

register_static("water", {
    description = "Ornamental Basin Water",
    tiles = { "amenaza_water.png" },
    walkable = true,
    paramtype = "light",
})

register_static("tree_trunk", {
    description = "Boulevard Tree Trunk",
    tiles = { "amenaza_tree_trunk.png" },
})

register_static("tree_leaves", {
    description = "Boulevard Tree Canopy",
    tiles = { "amenaza_tree_leaves.png" },
    paramtype = "light",
})

-- ============================================================================
-- Streets, Plazas & Sidewalks
-- ============================================================================

register_static("asphalt", {
    description = "Asphalt Road",
    tiles = { "amenaza_asphalt.png" },
})

register_static("asphalt_line_x", {
    description = "Asphalt Road (East-West Lane)",
    tiles = { "amenaza_asphalt_line_x.png", "amenaza_asphalt.png" },
})

register_static("asphalt_line_z", {
    description = "Asphalt Road (North-South Lane)",
    tiles = { "amenaza_asphalt_line_z.png", "amenaza_asphalt.png" },
})

register_static("cobblestone", {
    description = "Historic Cobblestone",
    tiles = { "amenaza_cobblestone.png" },
})

register_static("cobblestone_trim", {
    description = "Plaza Border Stone",
    tiles = { "amenaza_cobblestone_trim.png" },
})

register_static("sidewalk", {
    description = "Stone Sidewalk",
    tiles = { "amenaza_sidewalk.png" },
})

register_static("sidewalk_curb", {
    description = "Sidewalk Curbstone",
    tiles = { "amenaza_sidewalk.png", "amenaza_sidewalk.png", "amenaza_sidewalk_curb.png" },
})

-- ============================================================================
-- Heavy Power Conduits (Environmental Trail Leading to the AI Data Center)
-- ============================================================================

register_static("power_cable_x", {
    description = "Heavy Power Conduit (E-W)",
    tiles = { "amenaza_power_cable_x.png", "amenaza_asphalt.png" },
    light_source = 3,
    groups = { amenaza_cable = 1 },
})

register_static("power_cable_z", {
    description = "Heavy Power Conduit (N-S)",
    tiles = { "amenaza_power_cable_z.png", "amenaza_asphalt.png" },
    light_source = 3,
    groups = { amenaza_cable = 1 },
})

register_static("power_cable_junction", {
    description = "Power Conduit Junction",
    tiles = { "amenaza_power_cable_junction.png", "amenaza_asphalt.png" },
    light_source = 6,
    groups = { amenaza_cable = 1 },
})

-- ============================================================================
-- Neoclassical & Historic European Architecture
-- ============================================================================

register_static("sandstone_cream", {
    description = "Cream Neoclassical Facade",
    tiles = { "amenaza_sandstone_cream.png" },
})

register_static("sandstone_ochre", {
    description = "Ochre Historic Plaster",
    tiles = { "amenaza_sandstone_ochre.png" },
})

register_static("sandstone_terracotta", {
    description = "Terracotta Historic Plaster",
    tiles = { "amenaza_sandstone_terracotta.png" },
})

register_static("sandstone_slate", {
    description = "Slate Limestone Facade",
    tiles = { "amenaza_sandstone_slate.png" },
})

register_static("rusticated_base", {
    description = "Rusticated Stone Base",
    tiles = { "amenaza_rusticated_base.png" },
})

register_static("cornice", {
    description = "Sculpted Cornice",
    tiles = { "amenaza_sandstone_cream.png", "amenaza_sandstone_cream.png", "amenaza_cornice.png" },
})

register_static("pillar", {
    description = "Fluted Neoclassical Column",
    tiles = { "amenaza_sandstone_cream.png", "amenaza_sandstone_cream.png", "amenaza_pillar.png" },
})

register_static("window_lit", {
    description = "Lit Facade Window",
    tiles = { "amenaza_window_lit.png" },
    light_source = 11,
    groups = { amenaza_window = 1 },
})

register_static("window_dim", {
    description = "Flickering Facade Window",
    tiles = { "amenaza_window_lit.png^[multiply:#7a5830" },
    light_source = 3,
    groups = { amenaza_window = 1 },
})

register_static("window_dark", {
    description = "Dark Facade Window",
    tiles = { "amenaza_window_dark.png" },
    light_source = 0,
    groups = { amenaza_window = 1 },
})

register_static("roof_slate", {
    description = "Slate Roof Tiles",
    tiles = { "amenaza_roof_slate.png" },
})

register_static("roof_copper", {
    description = "Verdigris Copper Roof",
    tiles = { "amenaza_roof_copper.png" },
})

register_static("lobby_floor", {
    description = "Checkered Marble Lobby Floor",
    tiles = { "amenaza_lobby_floor.png" },
})

-- ============================================================================
-- Blinking Street Lanterns
-- ============================================================================

register_static("lantern_post", {
    description = "Wrought-Iron Lamppost",
    tiles = { "amenaza_lantern_post.png" },
    drawtype = "nodebox",
    paramtype = "light",
    node_box = {
        type = "fixed",
        fixed = { -0.14, -0.5, -0.14, 0.14, 0.5, 0.14 },
    },
    collision_box = {
        type = "fixed",
        fixed = { -0.18, -0.5, -0.18, 0.18, 0.5, 0.18 },
    },
})

local lantern_box = {
    type = "fixed",
    fixed = {
        { -0.28, -0.5, -0.28, 0.28, 0.35, 0.28 },
        { -0.34, 0.35, -0.34, 0.34, 0.5, 0.34 },
    },
}

register_static("lantern_on", {
    description = "Street Lantern (Active)",
    tiles = { "amenaza_lantern_post.png", "amenaza_lantern_post.png", "amenaza_lantern_on.png" },
    drawtype = "nodebox",
    paramtype = "light",
    node_box = lantern_box,
    light_source = 14,
    groups = { amenaza_lantern = 1 },
})

register_static("lantern_dim", {
    description = "Street Lantern (Flickering)",
    tiles = { "amenaza_lantern_post.png", "amenaza_lantern_post.png", "amenaza_lantern_dim.png" },
    drawtype = "nodebox",
    paramtype = "light",
    node_box = lantern_box,
    light_source = 4,
    groups = { amenaza_lantern = 1 },
})

register_static("lantern_off", {
    description = "Street Lantern (Extinguished)",
    tiles = { "amenaza_lantern_post.png", "amenaza_lantern_post.png", "amenaza_lantern_off.png" },
    drawtype = "nodebox",
    paramtype = "light",
    node_box = lantern_box,
    light_source = 0,
    groups = { amenaza_lantern = 1 },
})

register_static("lantern_steady", {
    description = "Street Lantern (Restored)",
    tiles = { "amenaza_lantern_post.png", "amenaza_lantern_post.png", "amenaza_lantern_steady.png" },
    drawtype = "nodebox",
    paramtype = "light",
    node_box = lantern_box,
    light_source = 14,
    groups = { amenaza_lantern = 1 },
})

-- ============================================================================
-- AI Data Center & Server Hardware
-- ============================================================================

register_static("datacenter_wall", {
    description = "Reinforced Data Center Wall",
    tiles = { "amenaza_datacenter_wall.png" },
})

register_static("datacenter_vent", {
    description = "Industrial Cooling Vent",
    tiles = { "amenaza_datacenter_wall.png", "amenaza_datacenter_wall.png", "amenaza_datacenter_vent.png" },
})

register_static("datacenter_floor", {
    description = "Server Room Floor Grate",
    tiles = { "amenaza_datacenter_floor.png" },
})

register_static("datacenter_beacon", {
    description = "Facility Warning Beacon",
    tiles = { "amenaza_datacenter_wall.png", "amenaza_datacenter_wall.png", "amenaza_datacenter_beacon.png" },
    light_source = 8,
    groups = { amenaza_beacon = 1 },
})

register_static("datacenter_beacon_off", {
    description = "Facility Beacon (Safe)",
    tiles = { "amenaza_datacenter_wall.png", "amenaza_datacenter_wall.png", "amenaza_datacenter_beacon_off.png" },
    light_source = 5,
    groups = { amenaza_beacon = 1 },
})

register_static("server_rack_active", {
    description = "Active AI Server Rack",
    tiles = {
        "amenaza_datacenter_wall.png",
        "amenaza_datacenter_wall.png",
        {
            name = "amenaza_server_rack_active.png",
            animation = {
                type = "vertical_frames",
                aspect_w = 32,
                aspect_h = 32,
                length = 1.6,
            },
        },
    },
    light_source = 6,
    groups = { amenaza_server = 1 },
})

register_static("server_rack_shutdown", {
    description = "Deactivated Server Rack",
    tiles = {
        "amenaza_datacenter_wall.png",
        "amenaza_datacenter_wall.png",
        "amenaza_server_rack_shutdown.png",
    },
    light_source = 0,
    groups = { amenaza_server = 1 },
})

local function on_core_interact(pos, node, player)
    if not player or not player:is_player() then
        return
    end
    local core = rawget(_G, "amenaza_core")
    if core and core.trigger_victory then
        core.trigger_victory(player, pos)
    end
end

register_static("mainframe_core", {
    description = "Mainframe Core — Shutdown Terminal",
    pointable = true,
    tiles = {
        "amenaza_datacenter_wall.png",
        "amenaza_datacenter_wall.png",
        {
            name = "amenaza_mainframe_core.png",
            animation = {
                type = "vertical_frames",
                aspect_w = 32,
                aspect_h = 32,
                length = 1.2,
            },
        },
    },
    light_source = 9,
    groups = { amenaza_core = 1 },
    on_rightclick = function(pos, node, clicker)
        on_core_interact(pos, node, clicker)
    end,
    on_punch = function(pos, node, puncher)
        on_core_interact(pos, node, puncher)
    end,
})

register_static("mainframe_core_off", {
    description = "Mainframe Core (Shut Down)",
    pointable = true,
    tiles = {
        "amenaza_datacenter_wall.png",
        "amenaza_datacenter_wall.png",
        "amenaza_mainframe_core_off.png",
    },
    light_source = 6,
    groups = { amenaza_core = 1 },
})

-- ============================================================================
-- Dramatic Sub-Second Power Grid Instability Controller (Lanterns & Windows)
-- ============================================================================

local GRID_SCAN_RADIUS = 50
local GRID_SCAN_INTERVAL = 1.6

local cached_lanterns = {}
local cached_window_units = {} -- Each entry: { positions = { pos1, pos2, ... }, x = x, z = z, state = node_name }
local scan_accum = GRID_SCAN_INTERVAL
local last_scan_centers = {}

-- Grid instability phase state machine:
--   "unstable" -> lively erratic sub-second flickering across lanterns & windows
--   "sputter"  -> violent rapid strobe / voltage surge across the whole street
--   "brownout" -> rolling blackout wave plunging lanterns & windows into darkness
--   "recovery" -> stuttering power surge slamming back on
local grid_phase = "unstable"
local phase_timer = 2.8
local phase_duration = 2.8
local tick_accum = 0
local next_tick = 0.14
local surge_polarity = false
local wave_dx = 1
local wave_dz = 0
local wave_min_proj = 0
local wave_max_proj = 1
local last_ambient_ratio = nil

local function set_dawn_ambient(core, ratio)
    if core and core.set_dawn_ambient_ratio and last_ambient_ratio ~= ratio then
        last_ambient_ratio = ratio
        core.set_dawn_ambient_ratio(ratio)
    end
end

local function rescan_grid_nodes(players)
    cached_lanterns = {}
    cached_window_units = {}

    local seen_lanterns = {}
    local unit_by_key = {}

    for _, player in ipairs(players) do
        local p = vector.round(player:get_pos())
        local minp = { x = p.x - GRID_SCAN_RADIUS, y = 1, z = p.z - GRID_SCAN_RADIUS }
        local maxp = { x = p.x + GRID_SCAN_RADIUS, y = 26, z = p.z + GRID_SCAN_RADIUS }

        local lanterns = minetest.find_nodes_in_area(minp, maxp, { "group:amenaza_lantern" })
        for i = 1, #lanterns do
            local lp = lanterns[i]
            local key = lp.x .. "," .. lp.y .. "," .. lp.z
            if not seen_lanterns[key] then
                seen_lanterns[key] = true
                cached_lanterns[#cached_lanterns + 1] = {
                    pos = lp,
                    state = minetest.get_node(lp).name,
                }
            end
        end

        local windows = minetest.find_nodes_in_area(minp, maxp, { "group:amenaza_window" })
        for i = 1, #windows do
            local wp = windows[i]
            -- Group 2-block-tall architectural windows on the same floor so both panes blink together
            local floor_band = math.floor(wp.y / 4)
            local ukey = wp.x .. "," .. floor_band .. "," .. wp.z
            local unit = unit_by_key[ukey]
            if not unit then
                unit = {
                    positions = { wp },
                    x = wp.x,
                    z = wp.z,
                    state = minetest.get_node(wp).name,
                }
                unit_by_key[ukey] = unit
                cached_window_units[#cached_window_units + 1] = unit
            else
                -- Avoid duplicate positions when multiple players have overlapping scan volumes
                local dup = false
                for j = 1, #unit.positions do
                    if unit.positions[j].y == wp.y then
                        dup = true
                        break
                    end
                end
                if not dup then
                    unit.positions[#unit.positions + 1] = wp
                end
            end
        end
    end
end

local function set_lantern_state(entry, target)
    if entry.state ~= target then
        entry.state = target
        minetest.swap_node(entry.pos, { name = target })
    end
end

local function set_window_unit_state(unit, target)
    if unit.state ~= target then
        unit.state = target
        local positions = unit.positions
        for i = 1, #positions do
            minetest.swap_node(positions[i], { name = target })
        end
    end
end

local function pick_different_lantern(current, progress)
    -- Bias away from current state so every flicker tick creates an unmistakable visual snap
    local off_weight = 40 + math.floor(progress * 20)
    local dim_weight = 32
    local roll = math.random(1, 100)
    local target
    if roll <= off_weight then
        target = "amenaza_nodes:lantern_off"
    elseif roll <= off_weight + dim_weight then
        target = "amenaza_nodes:lantern_dim"
    else
        target = "amenaza_nodes:lantern_on"
    end
    if target == current then
        if current == "amenaza_nodes:lantern_on" then
            target = (math.random(1, 100) <= 65) and "amenaza_nodes:lantern_off" or "amenaza_nodes:lantern_dim"
        elseif current == "amenaza_nodes:lantern_off" then
            target = (math.random(1, 100) <= 65) and "amenaza_nodes:lantern_on" or "amenaza_nodes:lantern_dim"
        else
            target = (math.random(1, 100) <= 55) and "amenaza_nodes:lantern_off" or "amenaza_nodes:lantern_on"
        end
    end
    return target
end

local function pick_different_window(current, progress)
    local dark_weight = 44 + math.floor(progress * 18)
    local dim_weight = 24
    local roll = math.random(1, 100)
    local target
    if roll <= dark_weight then
        target = "amenaza_nodes:window_dark"
    elseif roll <= dark_weight + dim_weight then
        target = "amenaza_nodes:window_dim"
    else
        target = "amenaza_nodes:window_lit"
    end
    if target == current then
        if current == "amenaza_nodes:window_lit" then
            target = (math.random(1, 100) <= 70) and "amenaza_nodes:window_dark" or "amenaza_nodes:window_dim"
        elseif current == "amenaza_nodes:window_dark" then
            target = (math.random(1, 100) <= 68) and "amenaza_nodes:window_lit" or "amenaza_nodes:window_dim"
        else
            target = (math.random(1, 100) <= 55) and "amenaza_nodes:window_dark" or "amenaza_nodes:window_lit"
        end
    end
    return target
end

local function compute_wave_bounds()
    local angle = math.random() * math.pi * 2
    wave_dx = math.cos(angle)
    wave_dz = math.sin(angle)
    local minp, maxp = math.huge, -math.huge
    for i = 1, #cached_lanterns do
        local lp = cached_lanterns[i].pos
        local proj = lp.x * wave_dx + lp.z * wave_dz
        if proj < minp then minp = proj end
        if proj > maxp then maxp = proj end
    end
    for i = 1, #cached_window_units do
        local u = cached_window_units[i]
        local proj = u.x * wave_dx + u.z * wave_dz
        if proj < minp then minp = proj end
        if proj > maxp then maxp = proj end
    end
    if minp >= maxp then
        wave_min_proj = -50
        wave_max_proj = 50
    else
        wave_min_proj = minp
        wave_max_proj = maxp
    end
end

local function advance_grid_phase(progress)
    if grid_phase == "unstable" then
        if math.random(1, 100) <= (52 + math.floor(progress * 20)) then
            grid_phase = "sputter"
            phase_duration = 1.0 + math.random() * 0.8 + progress * 0.4
        else
            grid_phase = "brownout"
            phase_duration = 1.5 + math.random() * 1.1 + progress * 0.9
            compute_wave_bounds()
        end
    elseif grid_phase == "sputter" then
        if math.random(1, 100) <= (65 + math.floor(progress * 20)) then
            grid_phase = "brownout"
            phase_duration = 1.5 + math.random() * 1.2 + progress * 1.0
            compute_wave_bounds()
        else
            grid_phase = "unstable"
            phase_duration = 2.0 + math.random() * 1.8 - progress * 0.6
        end
    elseif grid_phase == "brownout" then
        grid_phase = "recovery"
        phase_duration = 0.8 + math.random() * 0.5
        compute_wave_bounds()
    else
        grid_phase = "unstable"
        phase_duration = 2.2 + math.random() * 1.8 - progress * 0.7
    end
    phase_duration = math.max(0.7, phase_duration)
    phase_timer = phase_duration
    surge_polarity = false
end

local function run_grid_tick(core, progress)
    local base_ratio = (core and core.DAWN_BASE_LIGHT_RATIO) or 0.22
    local n_lanterns = #cached_lanterns
    local n_windows = #cached_window_units
    if n_lanterns == 0 and n_windows == 0 then
        return
    end

    if grid_phase == "unstable" then
        set_dawn_ambient(core, base_ratio)

        -- Lively, erratic blinking across a large slice of nearby lanterns and windows
        local l_chance = 34 + math.floor(progress * 18)
        for i = 1, n_lanterns do
            if math.random(1, 100) <= l_chance then
                local entry = cached_lanterns[i]
                set_lantern_state(entry, pick_different_lantern(entry.state, progress))
            end
        end

        local w_chance = 24 + math.floor(progress * 16)
        for i = 1, n_windows do
            if math.random(1, 100) <= w_chance then
                local unit = cached_window_units[i]
                set_window_unit_state(unit, pick_different_window(unit.state, progress))
            end
        end

        next_tick = 0.13 + math.random() * 0.10

    elseif grid_phase == "sputter" then
        -- Violent alternating voltage strobe across lanterns, windows, and ambient light
        surge_polarity = not surge_polarity
        if surge_polarity then
            set_dawn_ambient(core, base_ratio + 0.04)
        else
            set_dawn_ambient(core, base_ratio - 0.07)
        end

        for i = 1, n_lanterns do
            if math.random(1, 100) <= 78 then
                local entry = cached_lanterns[i]
                if surge_polarity then
                    local target = (math.random(1, 100) <= 78) and "amenaza_nodes:lantern_on" or "amenaza_nodes:lantern_dim"
                    set_lantern_state(entry, target)
                else
                    local target = (math.random(1, 100) <= 78) and "amenaza_nodes:lantern_off" or "amenaza_nodes:lantern_dim"
                    set_lantern_state(entry, target)
                end
            end
        end

        for i = 1, n_windows do
            if math.random(1, 100) <= 62 then
                local unit = cached_window_units[i]
                if surge_polarity then
                    local target = (math.random(1, 100) <= 74) and "amenaza_nodes:window_lit" or "amenaza_nodes:window_dim"
                    set_window_unit_state(unit, target)
                else
                    local target = (math.random(1, 100) <= 82) and "amenaza_nodes:window_dark" or "amenaza_nodes:window_dim"
                    set_window_unit_state(unit, target)
                end
            end
        end

        next_tick = 0.09 + math.random() * 0.05

    elseif grid_phase == "brownout" then
        -- Rolling blackout wave sweeping across the streets & facades
        local frac = 1.0 - (phase_timer / math.max(0.1, phase_duration))
        local wave_front = wave_min_proj + (wave_max_proj - wave_min_proj) * math.min(1.0, frac * 1.9)

        if frac > 0.25 then
            set_dawn_ambient(core, 0.12)
        else
            set_dawn_ambient(core, 0.16)
        end

        for i = 1, n_lanterns do
            local entry = cached_lanterns[i]
            local proj = entry.pos.x * wave_dx + entry.pos.z * wave_dz
            if proj <= wave_front then
                -- Dying filament sputter on a tiny handful of lanterns; rest pitch dark
                local roll = math.random(1, 100)
                if roll <= 90 then
                    set_lantern_state(entry, "amenaza_nodes:lantern_off")
                elseif roll <= 97 then
                    set_lantern_state(entry, "amenaza_nodes:lantern_dim")
                else
                    set_lantern_state(entry, "amenaza_nodes:lantern_on")
                end
            elseif proj <= wave_front + 14 then
                -- Leading edge of the wave dims right before dying
                set_lantern_state(entry, "amenaza_nodes:lantern_dim")
            end
        end

        for i = 1, n_windows do
            local unit = cached_window_units[i]
            local proj = unit.x * wave_dx + unit.z * wave_dz
            if proj <= wave_front then
                local roll = math.random(1, 100)
                if roll <= 88 then
                    set_window_unit_state(unit, "amenaza_nodes:window_dark")
                elseif roll <= 96 then
                    set_window_unit_state(unit, "amenaza_nodes:window_dim")
                else
                    set_window_unit_state(unit, "amenaza_nodes:window_lit")
                end
            elseif proj <= wave_front + 12 then
                set_window_unit_state(unit, "amenaza_nodes:window_dim")
            end
        end

        next_tick = 0.11

    elseif grid_phase == "recovery" then
        -- Power slams back on in a stuttering surge wave
        local frac = 1.0 - (phase_timer / math.max(0.1, phase_duration))
        local wave_front = wave_min_proj + (wave_max_proj - wave_min_proj) * math.min(1.0, frac * 1.6)
        local false_dip = (frac > 0.35 and frac < 0.55)

        if false_dip then
            set_dawn_ambient(core, 0.15)
        elseif frac < 0.25 then
            set_dawn_ambient(core, base_ratio + 0.05)
        else
            set_dawn_ambient(core, base_ratio)
        end

        for i = 1, n_lanterns do
            local entry = cached_lanterns[i]
            local proj = entry.pos.x * wave_dx + entry.pos.z * wave_dz
            if false_dip and math.random(1, 100) <= 65 then
                set_lantern_state(entry, "amenaza_nodes:lantern_dim")
            elseif proj <= wave_front then
                local target = (math.random(1, 100) <= 80) and "amenaza_nodes:lantern_on" or "amenaza_nodes:lantern_dim"
                set_lantern_state(entry, target)
            end
        end

        for i = 1, n_windows do
            local unit = cached_window_units[i]
            local proj = unit.x * wave_dx + unit.z * wave_dz
            if false_dip and math.random(1, 100) <= 55 then
                set_window_unit_state(unit, "amenaza_nodes:window_dark")
            elseif proj <= wave_front then
                local roll = math.random(1, 100)
                if roll <= 52 then
                    set_window_unit_state(unit, "amenaza_nodes:window_lit")
                elseif roll <= 74 then
                    set_window_unit_state(unit, "amenaza_nodes:window_dim")
                else
                    set_window_unit_state(unit, "amenaza_nodes:window_dark")
                end
            end
        end

        next_tick = 0.10
    end
end

minetest.register_globalstep(function(dtime)
    local core = rawget(_G, "amenaza_core")
    local state = core and core.get_state and core.get_state() or "dawn"
    if state ~= "dawn" then
        last_ambient_ratio = nil
        return
    end

    local players = minetest.get_connected_players()
    if #players == 0 then
        return
    end

    -- Refresh cached lanterns & windows periodically or when a player moves significantly
    scan_accum = scan_accum + dtime
    local moved_far = false
    for i = 1, #players do
        local p = players[i]
        local pname = p:get_player_name()
        local pos = p:get_pos()
        local prev = last_scan_centers[pname]
        if not prev or vector.distance(pos, prev) >= 10 then
            moved_far = true
        end
    end

    if scan_accum >= GRID_SCAN_INTERVAL or moved_far then
        scan_accum = 0
        last_scan_centers = {}
        for i = 1, #players do
            local p = players[i]
            last_scan_centers[p:get_player_name()] = p:get_pos()
        end
        rescan_grid_nodes(players)
    end

    local progress = (core and core.get_blackout_progress and core.get_blackout_progress()) or 0

    phase_timer = phase_timer - dtime
    if phase_timer <= 0 then
        advance_grid_phase(progress)
    end

    tick_accum = tick_accum + dtime
    if tick_accum >= next_tick then
        tick_accum = 0
        run_grid_tick(core, progress)
    end
end)

-- ============================================================================
-- Fallback State-Sync ABMs (For Distant / Newly-Loaded Chunks)
-- ============================================================================

minetest.register_abm({
    label = "Amenaza Street Lantern State Sync",
    nodenames = { "group:amenaza_lantern" },
    interval = 2,
    chance = 1,
    catch_up = false,
    action = function(pos, node)
        local core = rawget(_G, "amenaza_core")
        local state = core and core.get_state and core.get_state() or "dawn"

        if state == "blackout" then
            if node.name ~= "amenaza_nodes:lantern_off" then
                minetest.swap_node(pos, { name = "amenaza_nodes:lantern_off" })
            end
        elseif state == "victory" then
            if node.name ~= "amenaza_nodes:lantern_steady" then
                minetest.swap_node(pos, { name = "amenaza_nodes:lantern_steady" })
            end
        end
    end,
})

minetest.register_abm({
    label = "Amenaza Building Window Power State",
    nodenames = { "group:amenaza_window" },
    interval = 2,
    chance = 1,
    catch_up = false,
    action = function(pos, node)
        local core = rawget(_G, "amenaza_core")
        local state = core and core.get_state and core.get_state() or "dawn"
        if state == "blackout" then
            if node.name ~= "amenaza_nodes:window_dark" then
                minetest.swap_node(pos, { name = "amenaza_nodes:window_dark" })
            end
        elseif state == "victory" then
            if node.name == "amenaza_nodes:window_dim" then
                minetest.swap_node(pos, { name = "amenaza_nodes:window_lit" })
            end
        end
    end,
})

minetest.register_abm({
    label = "Amenaza Data Center Shutdown Sync",
    nodenames = {
        "amenaza_nodes:server_rack_active",
        "amenaza_nodes:datacenter_beacon",
        "amenaza_nodes:mainframe_core",
    },
    interval = 2,
    chance = 1,
    catch_up = false,
    action = function(pos, node)
        local core = rawget(_G, "amenaza_core")
        local state = core and core.get_state and core.get_state() or "dawn"
        if state == "victory" then
            if node.name == "amenaza_nodes:server_rack_active" then
                minetest.swap_node(pos, { name = "amenaza_nodes:server_rack_shutdown" })
            elseif node.name == "amenaza_nodes:datacenter_beacon" then
                minetest.swap_node(pos, { name = "amenaza_nodes:datacenter_beacon_off" })
            elseif node.name == "amenaza_nodes:mainframe_core" then
                minetest.swap_node(pos, { name = "amenaza_nodes:mainframe_core_off" })
            end
        end
    end,
})
