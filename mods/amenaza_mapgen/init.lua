-- amenaza_mapgen: Deterministic 5000x5000 VoxelManip procedural urban generator.
-- Architectural & urban layout inspiration: classic 19th-century European neoclassical
-- spa city (internally inspired by Wiesbaden's historic boulevards, plazas, and colonnade;
-- never referenced in any player-facing string).

amenaza_mapgen = {}

-- Key world coordinates exported for core & NPC mods
amenaza_mapgen.CITY_HALF_SIZE = 2500
amenaza_mapgen.SPAWN_POS = { x = 0, y = 2, z = -28 }
amenaza_mapgen.PLAZA_CENTER = { x = 0, y = 1, z = 4 }
amenaza_mapgen.DATACENTER_ENTRANCE = { x = -320, y = 1, z = 368 }
amenaza_mapgen.CORE_POS = { x = -320, y = 2, z = 420 }

local HALF = amenaza_mapgen.CITY_HALF_SIZE
local abs = math.abs
local floor = math.floor

-- Deterministic fast 2D integer hash -> 0..9999
local function hash2d(x, z)
    local h = (x * 374761393 + z * 668265263) % 2147483647
    h = ((h * 1274126177) % 2147483647)
    return abs(h) % 10000
end

-- Positive modulo helper
local function pmod(a, m)
    local r = a % m
    if r < 0 then r = r + m end
    return r
end

-- Content IDs cached on first mapgen call
local C = nil
local function init_content_ids()
    if C then return end
    local gid = minetest.get_content_id
    C = {
        air = gid("air"),
        bedrock = gid("amenaza_nodes:bedrock"),
        perimeter = gid("amenaza_nodes:perimeter_wall"),
        grass = gid("amenaza_nodes:park_grass"),
        gravel = gid("amenaza_nodes:park_gravel"),
        water = gid("amenaza_nodes:water"),
        trunk = gid("amenaza_nodes:tree_trunk"),
        leaves = gid("amenaza_nodes:tree_leaves"),
        asphalt = gid("amenaza_nodes:asphalt"),
        asphalt_x = gid("amenaza_nodes:asphalt_line_x"),
        asphalt_z = gid("amenaza_nodes:asphalt_line_z"),
        cobble = gid("amenaza_nodes:cobblestone"),
        cobble_trim = gid("amenaza_nodes:cobblestone_trim"),
        sidewalk = gid("amenaza_nodes:sidewalk"),
        curb = gid("amenaza_nodes:sidewalk_curb"),
        cable_x = gid("amenaza_nodes:power_cable_x"),
        cable_z = gid("amenaza_nodes:power_cable_z"),
        cable_j = gid("amenaza_nodes:power_cable_junction"),
        wall_cream = gid("amenaza_nodes:sandstone_cream"),
        wall_ochre = gid("amenaza_nodes:sandstone_ochre"),
        wall_terra = gid("amenaza_nodes:sandstone_terracotta"),
        wall_slate = gid("amenaza_nodes:sandstone_slate"),
        rusticated = gid("amenaza_nodes:rusticated_base"),
        cornice = gid("amenaza_nodes:cornice"),
        pillar = gid("amenaza_nodes:pillar"),
        win_lit = gid("amenaza_nodes:window_lit"),
        win_dark = gid("amenaza_nodes:window_dark"),
        roof_slate = gid("amenaza_nodes:roof_slate"),
        roof_copper = gid("amenaza_nodes:roof_copper"),
        lobby = gid("amenaza_nodes:lobby_floor"),
        post = gid("amenaza_nodes:lantern_post"),
        lantern_on = gid("amenaza_nodes:lantern_on"),
        lantern_off = gid("amenaza_nodes:lantern_off"),
        lantern_steady = gid("amenaza_nodes:lantern_steady"),
        dc_wall = gid("amenaza_nodes:datacenter_wall"),
        dc_vent = gid("amenaza_nodes:datacenter_vent"),
        dc_floor = gid("amenaza_nodes:datacenter_floor"),
        dc_beacon = gid("amenaza_nodes:datacenter_beacon"),
        dc_beacon_off = gid("amenaza_nodes:datacenter_beacon_off"),
        rack_on = gid("amenaza_nodes:server_rack_active"),
        rack_off = gid("amenaza_nodes:server_rack_shutdown"),
        core_on = gid("amenaza_nodes:mainframe_core"),
        core_off = gid("amenaza_nodes:mainframe_core_off"),
    }
    C.palettes = { C.wall_cream, C.wall_ochre, C.wall_terra, C.wall_slate }
end

-- Check if (x, z) lies on the heavy power conduit trail leading to the AI Data Center.
-- Route (100% along open plaza, boulevards, and streets):
--   1. (-28, 0)  -> (-80, 0)   West along the main boulevard (Z = 0)
--   2. (-80, 0)  -> (-80, 240) North along the X = -80 street
--   3. (-80, 240) -> (-320, 240) West along the Z = 240 boulevard
--   4. (-320, 240) -> (-320, 418) North along the X = -320 street directly into the Data Center core
local function get_cable_node(x, z)
    if (x == -28 and z == 0)
        or (x == -80 and z == 0)
        or (x == -80 and z == 240)
        or (x == -320 and z == 240)
        or (x == -320 and z == 369)
    then
        return C.cable_j
    end
    if z == 0 and x >= -80 and x <= -28 then
        return (x % 16 == 0) and C.cable_j or C.cable_x
    end
    if x == -80 and z >= 0 and z <= 240 then
        return (z % 16 == 0) and C.cable_j or C.cable_z
    end
    if z == 240 and x >= -320 and x <= -80 then
        return (x % 16 == 0) and C.cable_j or C.cable_x
    end
    if x == -320 and z >= 240 and z <= 418 then
        return (z % 16 == 0 and z < 370) and C.cable_j or C.cable_z
    end
    return nil
end

-- Place a boulevard/park tree at column (x, z) if within canopy radius of tree center (tx, tz)
local function sample_tree(x, z, y, tx, tz)
    local dx = x - tx
    local dz = z - tz
    if dx == 0 and dz == 0 and y >= 2 and y <= 6 then
        return C.trunk
    end
    if y >= 5 and y <= 8 then
        local r2 = dx * dx + dz * dz
        if (y == 5 or y == 6) and r2 <= 5 then
            return C.leaves
        elseif y == 7 and r2 <= 2 then
            return C.leaves
        elseif y == 8 and r2 <= 1 then
            return C.leaves
        end
    end
    return nil
end

-- Place a street lantern at (lx, lz) standing on sidewalk Y=1 (post Y=2..5, lamp Y=6)
local function sample_lantern(x, z, y, lantern_cid)
    if y >= 2 and y <= 5 then
        return C.post
    elseif y == 6 then
        return lantern_cid
    end
    return nil
end

-- ============================================================================
-- Landmark 1: AI Data Center (X: -350..-290, Z: 370..430)
-- ============================================================================
local function generate_datacenter_column(data, area, x, z, miny, maxy, state)
    local rack_cid = (state == "victory") and C.rack_off or C.rack_on
    local core_cid = (state == "victory") and C.core_off or C.core_on
    local beacon_cid = (state == "victory") and C.dc_beacon_off or C.dc_beacon

    local lx = x - (-320) -- -30..30
    local lz = z - 370    -- 0..60

    local y0 = math.max(miny, -4)
    local y1 = math.min(maxy, 18)

    local is_outer_wall = (abs(lx) == 30 or lz == 0 or lz == 60)
    local is_entrance = (lz == 0 and abs(lx) <= 2)
    local is_partition_1 = (lz == 14 and abs(lx) > 2)
    local is_partition_2 = (lz == 42 and abs(lx) > 2)

    -- Server rack rows inside the Main Server Hall (lz: 18..38)
    local is_server_rack = false
    if lz >= 18 and lz <= 38 and (lz % 4 ~= 0) then
        if abs(lx) == 6 or abs(lx) == 12 or abs(lx) == 18 or abs(lx) == 24 then
            is_server_rack = true
        end
    end
    -- Flanking server racks in the Mainframe Core Chamber (lz: 46..54)
    if lz >= 46 and lz <= 54 and (abs(lx) == 8 or abs(lx) == 14) and (lz % 3 ~= 0) then
        is_server_rack = true
    end

    local is_core_pedestal = (abs(lx) <= 1 and lz >= 49 and lz <= 51)
    local is_core_pos = (lx == 0 and lz == 50)

    local cable = get_cable_node(x, z)

    for y = y0, y1 do
        local vi = area:index(x, y, z)
        if y < 0 then
            data[vi] = C.bedrock
        elseif y == 0 then
            if cable then
                data[vi] = cable
            else
                data[vi] = C.dc_floor
            end
        elseif y >= 1 and y <= 14 then
            if is_outer_wall then
                if is_entrance and y <= 5 then
                    data[vi] = C.air
                elseif is_entrance and y == 6 then
                    data[vi] = beacon_cid
                elseif (y == 3 or y == 8) and ((abs(lx) == 30 and lz % 6 == 0) or ((lz == 0 or lz == 60) and abs(lx) % 6 == 0)) then
                    data[vi] = C.dc_vent
                else
                    data[vi] = C.dc_wall
                end
            elseif y == 11 or y == 14 then
                data[vi] = C.dc_wall
            elseif y > 11 then
                -- Roof parapet & cooling units
                if abs(lx) >= 28 or lz <= 2 or lz >= 58 then
                    data[vi] = C.dc_wall
                elseif (y == 12 or y == 13) and (abs(lx) % 10 == 0) and (lz % 10 == 0) then
                    data[vi] = C.dc_vent
                else
                    data[vi] = C.air
                end
            else
                -- Interior y = 1..10
                if is_partition_1 or is_partition_2 then
                    data[vi] = C.dc_wall
                elseif is_core_pos and y == 2 then
                    data[vi] = core_cid
                elseif is_core_pedestal and y == 1 then
                    data[vi] = C.dc_wall
                elseif is_server_rack and y >= 1 and y <= 5 then
                    data[vi] = rack_cid
                else
                    data[vi] = C.air
                end
            end
        end
    end
end

-- ============================================================================
-- Landmark 2: Grand Central Plaza & Neoclassical Colonnade
-- Plaza: X: -52..52, Z: -52..33
-- Colonnade & Hall: X: -44..44, Z: 34..74
-- ============================================================================
local function generate_central_plaza_column(data, area, x, z, miny, maxy, lantern_cid, win_cid)
    local y0 = math.max(miny, -4)
    local y1 = math.min(maxy, 26)
    local cable = get_cable_node(x, z)

    -- Grand Neoclassical Hall & Colonnade (Z: 34..74, X: -44..44)
    if z >= 34 and z <= 74 and abs(x) <= 44 then
        local ax = abs(x)
        local is_steps = (z >= 34 and z <= 36 and ax <= 36)
        local is_portico = (z >= 37 and z <= 43 and ax <= 36)
        local is_hall = (z >= 44 and z <= 74 and ax <= 44)

        for y = y0, y1 do
            local vi = area:index(x, y, z)
            if y < 0 then
                data[vi] = C.bedrock
            elseif y == 0 then
                data[vi] = C.cobble
            elseif is_steps then
                if y == 1 and z >= 35 then
                    data[vi] = C.sidewalk
                elseif y == 2 and z == 36 then
                    data[vi] = C.sidewalk
                else
                    data[vi] = C.air
                end
            elseif is_portico then
                if y <= 2 then
                    data[vi] = C.lobby
                elseif y >= 3 and y <= 13 then
                    -- Fluted neoclassical columns along the front portico
                    if z == 38 and ax <= 32 and (ax % 8 == 0) then
                        data[vi] = C.pillar
                    else
                        data[vi] = C.air
                    end
                elseif y == 14 or y == 15 then
                    data[vi] = C.cornice
                elseif y >= 16 and y <= 21 then
                    -- Triangular neoclassical pediment
                    local ped_half = 36 - (y - 16) * 6
                    if ax <= ped_half then
                        data[vi] = (ax == ped_half or y == 16) and C.cornice or C.wall_cream
                    else
                        data[vi] = C.air
                    end
                else
                    data[vi] = C.air
                end
            elseif is_hall then
                if y <= 2 then
                    data[vi] = C.lobby
                elseif y >= 3 and y <= 15 then
                    local on_wall = (z == 44 or z == 74 or ax == 44)
                    local is_entry = (z == 44 and ax <= 3 and y <= 8)
                    if on_wall and not is_entry then
                        if y == 15 or y == 9 then
                            data[vi] = C.cornice
                        elseif (y == 5 or y == 6 or y == 11 or y == 12) and ((ax % 6 == 0 and ax < 42) or ((z - 44) % 6 == 0 and z < 72)) then
                            data[vi] = win_cid
                        else
                            data[vi] = C.wall_cream
                        end
                    else
                        data[vi] = C.air
                    end
                elseif y >= 16 and y <= 23 then
                    -- Verdigris copper landmark roof
                    local inset = y - 16
                    if ax <= 44 - inset and z >= 44 + inset and z <= 74 - inset then
                        data[vi] = C.roof_copper
                    else
                        data[vi] = C.air
                    end
                else
                    data[vi] = C.air
                end
            else
                data[vi] = C.air
            end
        end
        return
    end

    -- Open Grand Cobblestone Plaza (X: -52..52, Z: -52..33)
    local dist_fountain = (x * x) + ((z + 6) * (z + 6))
    local is_plaza_lantern = (
        (abs(x) == 42 and (z == -42 or z == -20 or z == 2 or z == 24))
        or (abs(x) == 18 and (z == -42 or z == 28))
    )

    for y = y0, y1 do
        local vi = area:index(x, y, z)
        if y < 0 then
            data[vi] = C.bedrock
        elseif y == 0 then
            if cable then
                data[vi] = cable
            elseif dist_fountain <= 25 then
                data[vi] = C.water
            elseif dist_fountain <= 36 then
                data[vi] = C.cobble_trim
            elseif (abs(x) % 12 == 0 or abs(z) % 12 == 0) then
                data[vi] = C.cobble_trim
            else
                data[vi] = C.cobble
            end
        elseif y == 1 then
            if dist_fountain > 25 and dist_fountain <= 36 then
                data[vi] = C.cobble_trim
            elseif x == 0 and z == -6 then
                data[vi] = C.pillar
            elseif is_plaza_lantern then
                data[vi] = C.sidewalk_curb or C.curb
            else
                data[vi] = C.air
            end
        else
            if x == 0 and z == -6 and y <= 4 then
                data[vi] = C.pillar
            elseif is_plaza_lantern then
                local ln = sample_lantern(x, z, y, lantern_cid)
                data[vi] = ln or C.air
            else
                data[vi] = C.air
            end
        end
    end
end

-- ============================================================================
-- Landmark 3: Grand Spa Park (X: 56..230, Z: -160..160)
-- ============================================================================
local function generate_park_column(data, area, x, z, miny, maxy, lantern_cid)
    local y0 = math.max(miny, -4)
    local y1 = math.min(maxy, 12)

    local is_main_path = (abs(z) <= 4 or abs(x - 140) <= 4 or abs(z - 80) <= 2 or abs(z + 80) <= 2)
    local pond_d2 = ((x - 175) * (x - 175)) / 4 + ((z - 0) * (z - 0)) / 9
    local is_pond = (pond_d2 < 140) and not is_main_path

    -- Grid of park trees
    local tx = floor((x + 9) / 18) * 18
    local tz = floor((z + 9) / 18) * 18
    local has_tree = (hash2d(tx, tz) % 3 ~= 0) and (abs(tz) > 9) and (abs(tx - 140) > 9)
        and (((tx - 175) * (tx - 175)) / 4 + (tz * tz) / 9 > 180)
        and (tx >= 64 and tx <= 222 and abs(tz) <= 150)

    local is_lantern = (abs(z) == 5 and (x % 24 == 0)) or (abs(x - 140) == 5 and (z % 24 == 0))

    for y = y0, y1 do
        local vi = area:index(x, y, z)
        if y < 0 then
            data[vi] = C.bedrock
        elseif y == 0 then
            if is_main_path then
                data[vi] = C.gravel
            elseif is_pond then
                data[vi] = C.water
            else
                data[vi] = C.grass
            end
        elseif y == 1 then
            if is_lantern then
                data[vi] = C.curb
            elseif has_tree and x == tx and z == tz then
                data[vi] = C.trunk
            else
                data[vi] = C.air
            end
        else
            if is_lantern then
                data[vi] = sample_lantern(x, z, y, lantern_cid) or C.air
            elseif has_tree then
                data[vi] = sample_tree(x, z, y, tx, tz) or C.air
            else
                data[vi] = C.air
            end
        end
    end
end

-- ============================================================================
-- Standard City Grid: Boulevards, Roundabouts, Side Streets, Alleys, Buildings
-- ============================================================================
local function generate_city_column(data, area, x, z, miny, maxy, lantern_cid, win_cid)
    local y0 = math.max(miny, -4)
    local y1 = math.min(maxy, 32)
    local cable = get_cable_node(x, z)

    -- Superblock coordinates (240x240) for primary boulevards & roundabouts
    local mx = pmod(x + 120, 240) - 120 -- -120..119, boulevard centered at 0
    local mz = pmod(z + 120, 240) - 120
    local amx = abs(mx)
    local amz = abs(mz)

    -- Roundabout at major boulevard intersections (240x240)
    local r2 = mx * mx + mz * mz
    if r2 <= 484 then -- radius 22
        local is_center_island = (r2 <= 49) -- radius 7
        local is_ring_curb = (r2 > 49 and r2 <= 64)
        local is_outer_curb = (r2 > 361 and r2 <= 484)
        local is_lantern = ((amx == 19 and mz == 0) or (mx == 0 and amz == 19))

        for y = y0, y1 do
            local vi = area:index(x, y, z)
            if y < 0 then
                data[vi] = C.bedrock
            elseif y == 0 then
                if cable then
                    data[vi] = cable
                elseif is_center_island then
                    data[vi] = C.grass
                elseif is_ring_curb or is_outer_curb then
                    data[vi] = C.cobble_trim
                else
                    data[vi] = C.cobble
                end
            elseif y == 1 then
                if is_ring_curb then
                    data[vi] = C.curb
                elseif mx == 0 and mz == 0 then
                    data[vi] = C.pillar
                elseif is_lantern then
                    data[vi] = C.curb
                else
                    data[vi] = C.air
                end
            else
                if mx == 0 and mz == 0 and y <= 6 then
                    data[vi] = C.pillar
                elseif is_lantern then
                    data[vi] = sample_lantern(x, z, y, lantern_cid) or C.air
                else
                    data[vi] = C.air
                end
            end
        end
        return
    end

    -- Primary Boulevards (asphalt: -6..6, sidewalk: 7..9)
    local on_blvd_x_road = (amz <= 6)
    local on_blvd_z_road = (amx <= 6)
    local on_blvd_x_walk = (amz >= 7 and amz <= 9)
    local on_blvd_z_walk = (amx >= 7 and amx <= 9)

    if on_blvd_x_road or on_blvd_z_road or on_blvd_x_walk or on_blvd_z_walk then
        local is_road = on_blvd_x_road or on_blvd_z_road
        local is_curb = (not is_road) and (amz == 7 or amx == 7)
        local is_lantern = (not is_road) and (
            (amz == 7 and pmod(x, 20) == 0 and amx > 10)
            or (amx == 7 and pmod(z, 20) == 0 and amz > 10)
        )
        -- Boulevard trees spaced between lanterns (centers at ..., -10, 10, 30, ...)
        local tx = floor(x / 20) * 20 + 10
        local tz = floor(z / 20) * 20 + 10
        local tree_z = (mz >= 0) and (z - mz + 8) or (z - mz - 8)
        local tree_x = (mx >= 0) and (x - mx + 8) or (x - mx - 8)
        local near_blvd_tree_x = (not is_road) and on_blvd_x_walk and (abs(amx) > 14) and (abs(x - tx) <= 2) and (abs(z - tree_z) <= 2)
        local near_blvd_tree_z = (not is_road) and on_blvd_z_walk and (abs(amz) > 14) and (abs(z - tz) <= 2) and (abs(x - tree_x) <= 2)

        for y = y0, y1 do
            local vi = area:index(x, y, z)
            if y < 0 then
                data[vi] = C.bedrock
            elseif y == 0 then
                if cable then
                    data[vi] = cable
                elseif is_road then
                    if on_blvd_x_road and mz == 0 and (pmod(x, 6) < 3) and not on_blvd_z_road then
                        data[vi] = C.asphalt_x
                    elseif on_blvd_z_road and mx == 0 and (pmod(z, 6) < 3) and not on_blvd_x_road then
                        data[vi] = C.asphalt_z
                    else
                        data[vi] = C.asphalt
                    end
                else
                    data[vi] = C.sidewalk
                end
            elseif y == 1 then
                if is_road then
                    data[vi] = C.air
                else
                    data[vi] = is_curb and C.curb or C.sidewalk
                end
            else
                if is_lantern then
                    data[vi] = sample_lantern(x, z, y, lantern_cid) or C.air
                elseif near_blvd_tree_x then
                    data[vi] = sample_tree(x, z, y, tx, tree_z) or C.air
                elseif near_blvd_tree_z then
                    data[vi] = sample_tree(x, z, y, tree_x, tz) or C.air
                else
                    data[vi] = C.air
                end
            end
        end
        return
    end

    -- Secondary Streets every 80 blocks (asphalt: -3..3, sidewalk: 4..5)
    local sx = pmod(x + 40, 80) - 40
    local sz = pmod(z + 40, 80) - 40
    local asx = abs(sx)
    local asz = abs(sz)

    local on_sec_x_road = (asz <= 3)
    local on_sec_z_road = (asx <= 3)
    local on_sec_x_walk = (asz == 4 or asz == 5)
    local on_sec_z_walk = (asx == 4 or asx == 5)

    if on_sec_x_road or on_sec_z_road or on_sec_x_walk or on_sec_z_walk then
        local is_road = on_sec_x_road or on_sec_z_road
        local is_curb = (not is_road) and (asz == 4 or asx == 4)
        local is_lantern = (not is_road) and (
            (asz == 4 and pmod(x, 24) == 0 and asx > 6)
            or (asx == 4 and pmod(z, 24) == 0 and asz > 6)
        )

        for y = y0, y1 do
            local vi = area:index(x, y, z)
            if y < 0 then
                data[vi] = C.bedrock
            elseif y == 0 then
                if cable then
                    data[vi] = cable
                elseif is_road then
                    data[vi] = C.asphalt
                else
                    data[vi] = C.sidewalk
                end
            elseif y == 1 then
                if is_road then
                    data[vi] = C.air
                else
                    data[vi] = is_curb and C.curb or C.sidewalk
                end
            else
                if is_lantern then
                    data[vi] = sample_lantern(x, z, y, lantern_cid) or C.air
                else
                    data[vi] = C.air
                end
            end
        end
        return
    end

    -- Inside an 80x80 City Block (local coords bx, bz in 6..74)
    local block_id_x = floor((x + 40) / 80)
    local block_id_z = floor((z + 40) / 80)
    local bx = pmod(x + 40, 80) -- 0..79 (streets occupy 0..5 and 75..79)
    local bz = pmod(z + 40, 80)

    -- Bisect block with a narrow historic cobblestone alley (width 4)
    local block_h = hash2d(block_id_x, block_id_z)
    if (bx >= 38 and bx <= 41) or ((block_h % 2 == 0) and bz >= 38 and bz <= 41) then
        for y = y0, y1 do
            local vi = area:index(x, y, z)
            if y < 0 then
                data[vi] = C.bedrock
            elseif y == 0 then
                data[vi] = C.cobble
            else
                data[vi] = C.air
            end
        end
        return
    end

    -- Determine which building parcel (quadrant of the 80x80 block)
    local px0, px1 = (bx < 38) and 7 or 42, (bx < 38) and 37 or 73
    local pz0, pz1 = (bz < 38) and 7 or 42, (bz < 38) and 37 or 73
    if (block_h % 2 ~= 0) then
        pz0, pz1 = 7, 73
    end

    -- Outside parcel footprint -> sidewalk/courtyard border
    if bx < px0 or bx > px1 or bz < pz0 or bz > pz1 then
        for y = y0, y1 do
            local vi = area:index(x, y, z)
            if y < 0 then
                data[vi] = C.bedrock
            elseif y <= 1 then
                data[vi] = C.sidewalk
            else
                data[vi] = C.air
            end
        end
        return
    end

    -- Deterministic architectural parameters for this parcel
    local ph = hash2d(block_id_x * 4 + (bx < 38 and 1 or 2), block_id_z * 4 + (bz < 38 and 1 or 2))
    local stories = 3 + (ph % 3) -- 3 to 5 stories
    local wall_h = stories * 4 + 2 -- 14, 18, or 22 nodes
    local wall_cid = C.palettes[(ph % 4) + 1]
    local roof_cid = ((ph % 5) == 0) and C.roof_copper or C.roof_slate

    local dx_edge = math.min(bx - px0, px1 - bx)
    local dz_edge = math.min(bz - pz0, pz1 - bz)
    local d_edge = math.min(dx_edge, dz_edge)

    -- Inner courtyard for large parcels
    local in_courtyard = (dx_edge >= 8 and dz_edge >= 8)
    if in_courtyard then
        for y = y0, y1 do
            local vi = area:index(x, y, z)
            if y < 0 then
                data[vi] = C.bedrock
            elseif y == 0 then
                data[vi] = ((bx + bz) % 4 == 0) and C.grass or C.cobble
            else
                data[vi] = C.air
            end
        end
        return
    end

    local on_outer_wall = (d_edge == 0)
    local on_inner_wall = (dx_edge == 7 or dz_edge == 7)
    -- Open ground-floor lobby doorway facing the nearest street
    local mid_x = floor((px0 + px1) / 2)
    local mid_z = floor((pz0 + pz1) / 2)
    local is_doorway = (
        ((bz == pz0 or bz == pz1) and abs(bx - mid_x) <= 1)
        or ((bx == px0 or bx == px1) and abs(bz - mid_z) <= 1)
    )

    for y = y0, y1 do
        local vi = area:index(x, y, z)
        if y < 0 then
            data[vi] = C.bedrock
        elseif y == 0 then
            data[vi] = C.lobby
        elseif y == 1 then
            if on_outer_wall and not is_doorway then
                data[vi] = C.rusticated
            elseif on_inner_wall and not is_doorway then
                data[vi] = C.rusticated
            else
                data[vi] = C.lobby
            end
        elseif y >= 2 and y <= wall_h then
            if on_outer_wall then
                if is_doorway and y <= 4 then
                    data[vi] = C.air
                elseif y <= 4 then
                    data[vi] = C.rusticated
                elseif y == 5 or y == wall_h then
                    data[vi] = C.cornice
                elseif (y % 4 == 2 or y % 4 == 3) and ((bx % 4 == 0) ~= (bz % 4 == 0)) then
                    -- Recessed window pattern; some lit during dawn, all dark during blackout
                    local lit_roll = hash2d(x + y * 7, z) % 3
                    data[vi] = (lit_roll == 0) and win_cid or C.win_dark
                else
                    data[vi] = wall_cid
                end
            elseif on_inner_wall then
                if is_doorway and y <= 4 then
                    data[vi] = C.air
                else
                    data[vi] = wall_cid
                end
            elseif y == 6 then
                -- Ground-floor lobby ceiling slab
                data[vi] = C.sidewalk
            else
                data[vi] = C.air
            end
        elseif y > wall_h and y <= wall_h + 4 then
            -- Pitched mansard / slate roof
            local inset = y - wall_h
            if d_edge >= inset and d_edge <= 7 - inset then
                data[vi] = roof_cid
            else
                data[vi] = C.air
            end
        else
            data[vi] = C.air
        end
    end
end

-- ============================================================================
-- Main VoxelManip Mapgen Callback
-- ============================================================================
local data_buf = {}

minetest.register_on_generated(function(minp, maxp, blockseed)
    init_content_ids()

    -- Skip chunks far above or below the city
    if maxp.y < -5 or minp.y > 82 then
        return
    end

    local core = rawget(_G, "amenaza_core")
    local state = core and core.get_state and core.get_state() or "dawn"

    local lantern_cid = C.lantern_on
    local win_cid = C.win_lit
    if state == "blackout" then
        lantern_cid = C.lantern_off
        win_cid = C.win_dark
    elseif state == "victory" then
        lantern_cid = C.lantern_steady
        win_cid = C.win_lit
    end

    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })
    vm:get_data(data_buf)

    local miny = minp.y
    local maxy = maxp.y

    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            -- Impassable Perimeter Barrier beyond 5000 x 5000 (-2500..+2500)
            if abs(x) > HALF or abs(z) > HALF then
                local is_wall = (abs(x) <= HALF + 8 and abs(z) <= HALF + 8)
                local y0 = math.max(miny, -4)
                local y1 = math.min(maxy, 80)
                for y = y0, y1 do
                    local vi = area:index(x, y, z)
                    if y < 0 then
                        data_buf[vi] = C.bedrock
                    elseif is_wall then
                        data_buf[vi] = C.perimeter
                    else
                        data_buf[vi] = C.air
                    end
                end
            elseif x >= -350 and x <= -290 and z >= 370 and z <= 430 then
                -- AI Data Center Facility
                generate_datacenter_column(data_buf, area, x, z, miny, maxy, state)
            elseif abs(x) <= 52 and z >= -52 and z <= 74 then
                -- Grand Central Plaza & Neoclassical Colonnade
                generate_central_plaza_column(data_buf, area, x, z, miny, maxy, lantern_cid, win_cid)
            elseif x >= 56 and x <= 230 and abs(z) <= 160 then
                -- Grand Spa Park
                generate_park_column(data_buf, area, x, z, miny, maxy, lantern_cid)
            else
                -- Standard 19th-century European Neoclassical City Grid
                generate_city_column(data_buf, area, x, z, miny, maxy, lantern_cid, win_cid)
            end
        end
    end

    vm:set_data(data_buf)
    vm:calc_lighting()
    vm:write_to_map()
end)
