-- amenaza_npcs: Winkers-style protest crowd, multitud Skin_*.png speakers,
-- two-stage dialogue (initial protest explanation + compass directions to Data Center),
-- city-wide roaming protesters during Dawn, post-blackout riot AI, and instant Victory removal.

amenaza_npcs = {}

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)
local storage = minetest.get_mod_storage()

local TARGET_CROWD_SIZE = tonumber(minetest.settings:get("amenaza_crowd_size")) or 84
local CITY_CROWD_CAP = tonumber(minetest.settings:get("amenaza_city_crowd_size")) or 90

-- Collect Winkers civilian textures (non-speaking crowd) and multitud Skin_*.png (speakers)
local crowd_textures = {}
local speaker_textures = {}
local speaker_lookup = {}

for _, fname in ipairs(minetest.get_dir_list(modpath .. "/textures", false)) do
    if fname:match("^npc_character_%d+%.png$") then
        table.insert(crowd_textures, fname)
    elseif fname:match("^Skin_%d+%.png$") then
        table.insert(speaker_textures, fname)
        speaker_lookup[fname] = true
    end
end

if #crowd_textures == 0 then
    table.insert(crowd_textures, "character.png")
end
if #speaker_textures == 0 then
    table.insert(speaker_textures, "character.png")
    speaker_lookup["character.png"] = true
end

local sign_textures = {
    "amenaza_sign_1.png",
    "amenaza_sign_2.png",
    "amenaza_sign_3.png",
}

local crowd_sound_handles = {}

-- ============================================================================
-- Compass Direction Helper (Matches amenaza_compass: +Z = North, +X = East)
-- ============================================================================

local function get_compass_direction(from_pos, to_pos)
    local dx = to_pos.x - from_pos.x
    local dz = to_pos.z - from_pos.z
    local dist = math.floor(math.hypot(dx, dz) + 0.5)

    -- atan2(dx, dz): 0 = North (+Z), pi/2 = East (+X), pi = South (-Z), -pi/2 = West (-X)
    local angle = math.deg(math.atan2(dx, dz))
    if angle < 0 then angle = angle + 360 end

    local dirs = {
        S("North"), S("North-East"), S("East"), S("South-East"),
        S("South"), S("South-West"), S("West"), S("North-West"),
    }
    local idx = (math.floor((angle + 22.5) / 45) % 8) + 1
    return dirs[idx], dist
end

-- ============================================================================
-- Speaker Dialogues (Only Skin_*.png characters from multitud can speak)
-- ============================================================================

local function show_intro_dialogue(player)
    local title = amenaza_core.localize(player, S("PROTESTER"))
    local body = amenaza_core.localize(player, S(
        "\"We're out here because that rogue AI is bleeding the entire city's power grid dry. " ..
        "Look at the street lamps—the whole grid is about to collapse into a total blackout.\n\n" ..
        "Everyone in this plaza shouts and waves signs, demanding someone shut it down... " ..
        "but not a single person in this whole crowd has the courage to actually go find " ..
        "the main computer and pull the plug.\""
    ))
    local close_lbl = amenaza_core.localize(player, S("Close"))

    local fs = table.concat({
        "formspec_version[4]",
        "size[11,6.4]",
        "bgcolor[#0c0e14ee;true]",
        "box[0.3,0.3;10.4,5.8;#161a24ff]",
        "label[0.7,0.85;", minetest.formspec_escape(title), "]",
        "textarea[0.7,1.35;9.6,3.6;;;",
        minetest.formspec_escape(body),
        "]",
        "button_exit[4.0,5.25;3.0,0.7;close;", minetest.formspec_escape(close_lbl), "]",
    })
    minetest.show_formspec(player:get_player_name(), "amenaza_npcs:dialogue", fs)
end

local function show_directions_dialogue(player, speaker_pos)
    local dc_pos = (amenaza_mapgen and amenaza_mapgen.DATACENTER_ENTRANCE) or { x = -320, y = 1, z = 368 }
    local dir_name, dist = get_compass_direction(speaker_pos, dc_pos)

    local msg
    if dist <= 45 then
        msg = S(
            "\"You're almost right on top of it! Look @1—the fortified dark bunker with the red warning beacon and cooling vents is just @2 meters away. Get inside and shut down the Mainframe Core before the grid dies!\"",
            dir_name,
            tostring(dist)
        )
    else
        local rounded = math.max(20, math.floor((dist + 5) / 10) * 10)
        msg = S(
            "\"You're actually going to shut down the AI? Check your compass and head @1—the Data Center is roughly @2 meters from here.\n\nYou can also follow the heavy yellow-striped power cables laid along the main streets. Look for the dark fortified bunker with the glowing red beacon over its entrance. Hurry!\"",
            dir_name,
            tostring(rounded)
        )
    end

    local title = amenaza_core.localize(player, S("PROTESTER — DIRECTIONS"))
    local body = amenaza_core.localize(player, msg)
    local close_lbl = amenaza_core.localize(player, S("Close"))

    local fs = table.concat({
        "formspec_version[4]",
        "size[11,6.0]",
        "bgcolor[#0c0e14ee;true]",
        "box[0.3,0.3;10.4,5.4;#161a24ff]",
        "label[0.7,0.85;", minetest.formspec_escape(title), "]",
        "textarea[0.7,1.35;9.6,3.2;;;",
        minetest.formspec_escape(body),
        "]",
        "button_exit[4.0,4.85;3.0,0.7;close;", minetest.formspec_escape(close_lbl), "]",
    })
    minetest.show_formspec(player:get_player_name(), "amenaza_npcs:dialogue", fs)
end

-- ============================================================================
-- Lightweight Protest Sign Entity (Held by standing plaza protesters)
-- ============================================================================

minetest.register_entity("amenaza_npcs:sign", {
    initial_properties = {
        visual = "upright_sprite",
        visual_size = { x = 0.75, y = 0.75 },
        textures = { "amenaza_sign_1.png" },
        physical = false,
        pointable = false,
        static_save = false,
    },
    on_activate = function(self, staticdata)
        if amenaza_core.get_state() ~= "dawn" then
            self.object:remove()
            return
        end
        local tex = (staticdata and staticdata ~= "") and staticdata or sign_textures[math.random(#sign_textures)]
        self.object:set_properties({ textures = { tex } })
    end,
})

-- ============================================================================
-- Protester NPC Entity (Standing Plaza Crowd + Roaming City Crowd + Riot AI)
-- ============================================================================

local function attach_sign_if_needed(self)
    if self._sign_obj then return end
    if self._has_sign and not self._roaming and amenaza_core.get_state() == "dawn" then
        local pos = self.object:get_pos()
        if not pos then return end
        local tex = sign_textures[math.random(#sign_textures)]
        local sign = minetest.add_entity(pos, "amenaza_npcs:sign", tex)
        if sign then
            sign:set_attach(self.object, "", { x = 0.35, y = 1.55, z = 0.25 }, { x = 0, y = 0, z = 0 })
            self._sign_obj = sign
        end
    end
end

local function detach_sign(self)
    if self._sign_obj then
        self._sign_obj:remove()
        self._sign_obj = nil
    end
end

local function enter_riot_mode(self)
    if self._rioting then return end
    self._rioting = true
    detach_sign(self)
    self.object:set_animation({ x = 168, y = 187 }, 44, 0)
    self._speed = 4.6 + math.random() * 1.1
    local yaw = math.random() * math.pi * 2
    self.object:set_yaw(yaw)
end

minetest.register_entity("amenaza_npcs:protester", {
    initial_properties = {
        hp_max = 18,
        physical = true,
        pointable = true,
        collide_with_objects = true,
        collisionbox = { -0.3, 0.0, -0.3, 0.3, 1.7, 0.3 },
        selectionbox = { -0.45, 0.0, -0.45, 0.45, 1.85, 0.45 },
        visual = "mesh",
        mesh = "character.b3d",
        textures = { crowd_textures[1] },
        makes_footstep_sound = true,
        stepheight = 1.1,
        armor_groups = { fleshy = 100 },
        nametag = "",
    },

    on_activate = function(self, staticdata)
        -- Instant cleanup if the AI has already been shut down
        if amenaza_core.get_state() == "victory" then
            self.object:remove()
            return
        end

        local data = minetest.deserialize(staticdata or "") or {}
        if data.texture then
            -- Migrate any legacy speaker texture saved in an existing world
            if data.texture == "skin_from_multitude.png" then
                self._texture = speaker_textures[math.random(#speaker_textures)]
                self._is_speaker = true
            else
                self._texture = data.texture
                self._is_speaker = (speaker_lookup[data.texture] == true)
            end
            self._has_sign = data.has_sign or false
            self._ephemeral = data.ephemeral or false
            self._roaming = data.roaming or false
            self._gave_intro = data.gave_intro or false
            self._idle_stand = data.idle_stand or false
            self._base_yaw = data.base_yaw or 0
        else
            self._is_speaker = false
            self._texture = crowd_textures[math.random(#crowd_textures)]
            self._has_sign = (math.random(1, 5) == 1)
            self._ephemeral = false
            self._roaming = false
            self._gave_intro = false
            self._idle_stand = false
            self._base_yaw = 0
        end

        self.object:set_properties({
            textures = { self._texture },
            nametag = "",
        })
        self.object:set_acceleration({ x = 0, y = -9.81, z = 0 })

        -- Staggered timers for smooth frame rates with large crowds
        self._ai_timer = math.random() * 0.35
        self._attack_cd = 0
        self._stuck_count = 0
        self._last_pos = self.object:get_pos()
        self._rioting = false
        self._speed = self._roaming and (2.0 + math.random() * 1.8) or 4.8

        if amenaza_core.get_state() == "blackout" then
            enter_riot_mode(self)
        elseif self._roaming then
            -- Walking/hurrying city pedestrians with speed-matched animation
            local walk_anim_speed = math.floor(self._speed * 9.5)
            self.object:set_animation({ x = 168, y = 187 }, walk_anim_speed, 0)
            local yaw = math.random() * math.pi * 2
            self.object:set_yaw(yaw)
            local dir = minetest.yaw_to_dir(yaw)
            self.object:set_velocity({ x = dir.x * self._speed, y = 0, z = dir.z * self._speed })
        else
            -- Standing plaza protesters & city bystanders
            self.object:set_yaw(self._base_yaw)
            if self._idle_stand and not self._has_sign then
                local anim_speed = 16 + math.random(0, 12)
                self.object:set_animation({ x = 0, y = 79 }, anim_speed, 0)
            else
                local anim_speed = 12 + math.random(0, 10)
                self.object:set_animation({ x = 189, y = 198 }, anim_speed, 0)
            end
            attach_sign_if_needed(self)
        end
    end,

    get_staticdata = function(self)
        if self._ephemeral then
            return ""
        end
        return minetest.serialize({
            texture = self._texture,
            has_sign = self._has_sign,
            ephemeral = self._ephemeral,
            roaming = self._roaming,
            gave_intro = self._gave_intro,
            idle_stand = self._idle_stand,
            base_yaw = self._base_yaw,
        })
    end,

    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local name = clicker:get_player_name()
        if amenaza_core.is_spectator(name) then return end
        if amenaza_core.get_state() ~= "dawn" then return end

        -- Turn toward the player
        local my_pos = self.object:get_pos()
        local p_pos = clicker:get_pos()
        if my_pos and p_pos then
            local dir = vector.subtract(p_pos, my_pos)
            self.object:set_yaw(minetest.dir_to_yaw(dir))
        end

        -- ONLY protesters wearing multitud Skin_*.png textures can speak
        if not self._is_speaker then
            return
        end

        if not amenaza_core.is_dialogue_used() then
            -- First speaker talked to: explains the protest & rogue AI
            amenaza_core.mark_dialogue_used()
            self._gave_intro = true
            show_intro_dialogue(clicker)
        elseif not self._gave_intro and my_pos then
            -- Every OTHER special-skin speaker gives live compass directions to the Data Center
            show_directions_dialogue(clicker, my_pos)
        end
    end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
        if amenaza_core.get_state() == "dawn" and puncher and puncher:is_player() then
            self:on_rightclick(puncher)
            return true -- Prevent hurting peaceful protesters during Dawn
        end
    end,

    on_death = function(self, killer)
        detach_sign(self)
    end,

    on_step = function(self, dtime)
        local state = amenaza_core.get_state()
        if state == "victory" then
            detach_sign(self)
            self.object:remove()
            return
        end

        if self._attack_cd > 0 then
            self._attack_cd = self._attack_cd - dtime
        end

        self._ai_timer = self._ai_timer + dtime
        local step_interval
        if self._rioting then
            step_interval = 0.25
        elseif self._roaming then
            step_interval = 0.5
        else
            step_interval = 0.9
        end
        if self._ai_timer < step_interval then
            return
        end
        self._ai_timer = 0

        local pos = self.object:get_pos()
        if not pos then return end

        -- Check nearest player distance for smart activation / despawn
        local nearest_player_dist = 9999
        for _, p in ipairs(minetest.get_connected_players()) do
            local d = vector.distance(pos, p:get_pos())
            if d < nearest_player_dist then
                nearest_player_dist = d
            end
        end
        if self._ephemeral and nearest_player_dist > 85 then
            detach_sign(self)
            self.object:remove()
            return
        end

        -- Phase 1: Dawn
        if state == "dawn" then
            if not self._roaming then
                -- Standing plaza protesters & city bystanders
                if math.random(1, 8) == 1 then
                    local yaw = (self._base_yaw or 0) + (math.random() - 0.5) * 0.9
                    self.object:set_yaw(yaw)
                end
                local vel = self.object:get_velocity()
                if vel and (math.abs(vel.x) > 0.05 or math.abs(vel.z) > 0.05) then
                    self.object:set_velocity({ x = 0, y = vel.y, z = 0 })
                end
                return
            end

            -- Roaming city protesters running/hurrying through the streets
            local vel = self.object:get_velocity() or { x = 0, y = 0, z = 0 }
            local yaw = self.object:get_yaw()

            if self._last_pos and vector.distance(pos, self._last_pos) < 0.2 then
                self._stuck_count = self._stuck_count + 1
                if self._stuck_count >= 2 then
                    yaw = yaw + (math.random() * math.pi - math.pi / 2)
                    self.object:set_yaw(yaw)
                    if math.abs(vel.y) < 0.1 then
                        vel.y = 4.5
                    end
                    self._stuck_count = 0
                elseif math.abs(vel.y) < 0.1 then
                    vel.y = 4.5
                end
            else
                self._stuck_count = 0
                if math.random(1, 14) == 1 then
                    yaw = yaw + (math.random() - 0.5) * 1.1
                    self.object:set_yaw(yaw)
                end
            end
            self._last_pos = pos

            local dir = minetest.yaw_to_dir(yaw)
            self.object:set_velocity({
                x = dir.x * self._speed,
                y = vel.y,
                z = dir.z * self._speed,
            })
            return
        end

        -- Phase 2: Blackout — Panic & Riot AI (attack each other AND the player!)
        if not self._rioting then
            enter_riot_mode(self)
        end

        if nearest_player_dist > 60 then
            return
        end

        local target_obj = nil
        local best_dist = 20.0
        local objects = minetest.get_objects_inside_radius(pos, 18)
        for _, obj in ipairs(objects) do
            if obj ~= self.object then
                local valid = false
                local priority_bias = 0
                if obj:is_player() then
                    if not amenaza_core.is_spectator(obj:get_player_name()) then
                        valid = true
                        priority_bias = -2.5
                    end
                else
                    local ent = obj:get_luaentity()
                    if ent and ent.name == "amenaza_npcs:protester" then
                        valid = true
                    end
                end

                if valid then
                    local opos = obj:get_pos()
                    if opos then
                        local dist = vector.distance(pos, opos) + priority_bias
                        if dist < best_dist then
                            best_dist = dist
                            target_obj = obj
                        end
                    end
                end
            end
        end

        local vel = self.object:get_velocity() or { x = 0, y = 0, z = 0 }
        local yaw = self.object:get_yaw()

        if target_obj then
            local tpos = target_obj:get_pos()
            if tpos then
                local dir = vector.subtract(tpos, pos)
                local flat_dist = math.hypot(dir.x, dir.z)
                yaw = minetest.dir_to_yaw(dir)
                self.object:set_yaw(yaw)

                if flat_dist <= 2.2 and math.abs(dir.y) <= 2.0 then
                    if self._attack_cd <= 0 then
                        self._attack_cd = 0.85
                        target_obj:punch(self.object, 1.0, {
                            full_punch_interval = 0.85,
                            damage_groups = { fleshy = 4 },
                        }, vector.normalize(dir))
                        if math.random(1, 3) == 1 then
                            minetest.sound_play("amenaza_panic", {
                                pos = pos,
                                gain = 0.45,
                                max_hear_distance = 22,
                            }, true)
                        end
                    end
                end
            end
        else
            if math.random(1, 5) == 1 then
                yaw = yaw + (math.random() - 0.5) * 1.4
                self.object:set_yaw(yaw)
            end
        end

        if self._last_pos and vector.distance(pos, self._last_pos) < 0.25 then
            self._stuck_count = self._stuck_count + 1
            if self._stuck_count >= 2 then
                yaw = yaw + (math.random() * math.pi - math.pi / 2)
                self.object:set_yaw(yaw)
                if math.abs(vel.y) < 0.1 then
                    vel.y = 4.6
                end
                self._stuck_count = 0
            end
        else
            self._stuck_count = 0
        end
        self._last_pos = pos

        local move_dir = minetest.yaw_to_dir(yaw)
        self.object:set_velocity({
            x = move_dir.x * self._speed,
            y = vel.y,
            z = move_dir.z * self._speed,
        })
    end,
})

-- ============================================================================
-- Plaza Crowd Spawner (Initial Standing Protest Crowd at Spawn)
-- ============================================================================

local function spawn_protester_at(pos, is_speaker, ephemeral, roaming, opts)
    opts = opts or {}
    local tex
    if is_speaker then
        tex = speaker_textures[math.random(#speaker_textures)]
    else
        tex = crowd_textures[math.random(#crowd_textures)]
    end
    local base_yaw = opts.base_yaw
    if base_yaw == nil then
        if roaming or ephemeral then
            base_yaw = math.random() * math.pi * 2
        else
            base_yaw = (math.random() - 0.5) * 0.8
        end
    end
    local has_sign = opts.has_sign
    if has_sign == nil then
        has_sign = (not is_speaker) and (not roaming) and (math.random(1, 4) == 1)
    end
    local staticdata = minetest.serialize({
        texture = tex,
        has_sign = has_sign,
        ephemeral = ephemeral or false,
        roaming = roaming or false,
        idle_stand = opts.idle_stand or false,
        base_yaw = base_yaw,
    })
    local obj = minetest.add_entity(pos, "amenaza_npcs:protester", staticdata)
    if obj then
        obj:set_yaw(base_yaw)
    end
    return obj
end

local function spawn_initial_plaza_crowd()
    if amenaza_core.get_state() ~= "dawn" then return end
    if storage:get_string("crowd_spawned") == "true" then return end
    storage:set_string("crowd_spawned", "true")

    -- Guarantee 5 accessible Skin_*.png speakers near the front/middle of the plaza crowd
    local guaranteed_speakers = {
        { x = -4, y = 1.5, z = -15 },
        { x = 5,  y = 1.5, z = -13 },
        { x = 0,  y = 1.5, z = -16 },
        { x = -9, y = 1.5, z = 4 },
        { x = 10, y = 1.5, z = 6 },
    }
    local spawned = 0
    for _, spos in ipairs(guaranteed_speakers) do
        spawn_protester_at(spos, true, false, false)
        spawned = spawned + 1
    end

    -- Fill out the dense protest crowd (standing + some walking) across the Central Plaza
    local attempts = 0
    while spawned < TARGET_CROWD_SIZE and attempts < 500 do
        attempts = attempts + 1
        local px = math.random(-26, 26)
        local pz = math.random(-18, 28)

        -- Keep clear of the central fountain at (0, -6) radius 7
        local fd2 = px * px + (pz + 6) * (pz + 6)
        if fd2 > 56 then
            local is_speaker = (spawned < 15) -- ~15 total Skin_*.png speakers in the plaza
            local is_walking = (not is_speaker) and (math.random(1, 7) == 1)
            spawn_protester_at(
                { x = px + (math.random() - 0.5) * 0.6, y = 1.5, z = pz + (math.random() - 0.5) * 0.6 },
                is_speaker,
                false,
                is_walking
            )
            spawned = spawned + 1
        end
    end
end

-- ============================================================================
-- State Transition Hooks (Blackout Riot / Victory Instant Removal / Reset)
-- ============================================================================

local function stop_all_crowd_audio()
    for pname, handle in pairs(crowd_sound_handles) do
        minetest.sound_stop(handle)
        crowd_sound_handles[pname] = nil
    end
end

amenaza_core.register_on_blackout(function()
    stop_all_crowd_audio()
    for _, ent in pairs(minetest.luaentities) do
        if ent.name == "amenaza_npcs:protester" then
            enter_riot_mode(ent)
        elseif ent.name == "amenaza_npcs:sign" then
            ent.object:remove()
        end
    end
end)

amenaza_core.register_on_victory(function()
    stop_all_crowd_audio()
    for _, ent in pairs(minetest.luaentities) do
        if ent.name == "amenaza_npcs:protester" or ent.name == "amenaza_npcs:sign" then
            ent.object:remove()
        end
    end
end)

amenaza_core.register_on_reset(function()
    stop_all_crowd_audio()
    for _, ent in pairs(minetest.luaentities) do
        if ent.name == "amenaza_npcs:protester" or ent.name == "amenaza_npcs:sign" then
            ent.object:remove()
        end
    end
    storage:set_string("crowd_spawned", "")
    minetest.after(1.0, spawn_initial_plaza_crowd)
end)

minetest.register_on_joinplayer(function(player)
    if amenaza_core.get_state() == "dawn" then
        minetest.after(1.5, spawn_initial_plaza_crowd)
    end
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    if crowd_sound_handles[name] then
        minetest.sound_stop(crowd_sound_handles[name])
        crowd_sound_handles[name] = nil
    end
end)

-- ============================================================================
-- Global Step: Plaza Crowd Audio & City-Wide Roaming Protesters (Dawn + Blackout)
-- ============================================================================

local ambient_timer = 0
local city_spawn_timer = 0

local WALKABLE_STREET_NODES = {
    ["amenaza_nodes:asphalt"] = true,
    ["amenaza_nodes:asphalt_line_x"] = true,
    ["amenaza_nodes:asphalt_line_z"] = true,
    ["amenaza_nodes:cobblestone"] = true,
    ["amenaza_nodes:cobblestone_trim"] = true,
    ["amenaza_nodes:sidewalk"] = true,
    ["amenaza_nodes:sidewalk_curb"] = true,
    ["amenaza_nodes:park_gravel"] = true,
    ["amenaza_nodes:park_grass"] = true,
    ["amenaza_nodes:power_cable_x"] = true,
    ["amenaza_nodes:power_cable_z"] = true,
    ["amenaza_nodes:power_cable_junction"] = true,
}

local function find_walkable_spawn_y(sx, sz)
    local spot_in_dc = (sx >= -352 and sx <= -288 and sz >= 368 and sz <= 432)
    local spot_in_plaza = (math.abs(sx) <= 32 and sz >= -24 and sz <= 32)
    if spot_in_dc or spot_in_plaza
        or math.abs(sx) >= amenaza_mapgen.CITY_HALF_SIZE - 20
        or math.abs(sz) >= amenaza_mapgen.CITY_HALF_SIZE - 20
    then
        return nil
    end

    for _, gy in ipairs({ 1, 0 }) do
        local gname = minetest.get_node({ x = sx, y = gy, z = sz }).name
        if WALKABLE_STREET_NODES[gname] then
            local a1 = minetest.get_node({ x = sx, y = gy + 1, z = sz }).name
            local a2 = minetest.get_node({ x = sx, y = gy + 2, z = sz }).name
            if a1 == "air" and a2 == "air" then
                return gy + 1.1
            end
        end
    end
    return nil
end

minetest.register_globalstep(function(dtime)
    local state = amenaza_core.get_state()
    if state == "victory" then return end

    local players = minetest.get_connected_players()
    if #players == 0 then return end

    -- 1. Ambient murmuring crowd sound near the starting plaza during Dawn
    ambient_timer = ambient_timer + dtime
    if ambient_timer >= 2.0 then
        ambient_timer = 0
        local plaza = amenaza_mapgen.PLAZA_CENTER
        for _, player in ipairs(players) do
            local name = player:get_player_name()
            local dist = vector.distance(player:get_pos(), plaza)
            if state == "dawn" and dist < 58 then
                if not crowd_sound_handles[name] then
                    crowd_sound_handles[name] = minetest.sound_play("amenaza_crowd", {
                        to_player = name,
                        gain = 0.4,
                        loop = true,
                    })
                end
            else
                if crowd_sound_handles[name] then
                    minetest.sound_stop(crowd_sound_handles[name])
                    crowd_sound_handles[name] = nil
                end
            end
        end
    end

    -- 2. City-Wide Walking & Standing Crowd (keeps the 5000x5000 city lively in Dawn & Blackout)
    city_spawn_timer = city_spawn_timer + dtime
    if city_spawn_timer >= 1.2 then
        city_spawn_timer = 0
        local cap = (state == "dawn") and CITY_CROWD_CAP or math.max(24, math.floor(CITY_CROWD_CAP * 0.72))
        for _, player in ipairs(players) do
            local ppos = player:get_pos()
            -- Don't spawn protesters inside the AI Data Center bunker
            local inside_dc = (ppos.x >= -355 and ppos.x <= -285 and ppos.z >= 365 and ppos.z <= 435)
            if not inside_dc then
                local nearby = minetest.get_objects_inside_radius(ppos, 68)
                local count = 0
                for _, o in ipairs(nearby) do
                    local e = o:get_luaentity()
                    if e and e.name == "amenaza_npcs:protester" then
                        count = count + 1
                    end
                end
                if count < cap then
                    local to_spawn = math.min(10, cap - count)
                    local spawned = 0
                    local attempts = 0
                    local max_attempts = to_spawn * 5
                    while spawned < to_spawn and attempts < max_attempts do
                        attempts = attempts + 1
                        local angle = math.random() * math.pi * 2
                        local dist = math.random(16, 62)
                        local sx = math.floor(ppos.x + math.cos(angle) * dist)
                        local sz = math.floor(ppos.z + math.sin(angle) * dist)

                        local spawn_y = find_walkable_spawn_y(sx, sz)
                        if spawn_y then
                            -- During Dawn: ~55% walking pedestrians, ~45% standing people (solo & small groups)
                            local is_walking = (state ~= "dawn") or (math.random(1, 100) <= 55)
                            local is_speaker = (state == "dawn") and (math.random(1, 5) == 1)
                            if is_walking then
                                spawn_protester_at(
                                    { x = sx + (math.random() - 0.5) * 0.4, y = spawn_y, z = sz + (math.random() - 0.5) * 0.4 },
                                    is_speaker,
                                    true,
                                    true
                                )
                                spawned = spawned + 1
                            else
                                -- Standing city person or small gathered group of 2-3 people
                                local group_size = (math.random(1, 2) == 1) and math.min(math.random(2, 3), to_spawn - spawned) or 1
                                local group_yaw = math.random() * math.pi * 2
                                for g = 1, group_size do
                                    local gx, gz = sx, sz
                                    local gy = spawn_y
                                    if g > 1 then
                                        local gangle = math.random() * math.pi * 2
                                        local gdist = 1.4 + math.random() * 1.8
                                        gx = math.floor(sx + math.cos(gangle) * gdist + 0.5)
                                        gz = math.floor(sz + math.sin(gangle) * gdist + 0.5)
                                        gy = find_walkable_spawn_y(gx, gz)
                                    end
                                    if gy then
                                        local member_speaker = (g == 1) and is_speaker or (math.random(1, 6) == 1)
                                        local facing
                                        if group_size > 1 then
                                            -- Face roughly toward the center of the standing group
                                            facing = minetest.dir_to_yaw({ x = sx - gx, y = 0, z = sz - gz }) + (math.random() - 0.5) * 0.7
                                            if g == 1 then
                                                facing = group_yaw
                                            end
                                        else
                                            facing = math.random() * math.pi * 2
                                        end
                                        spawn_protester_at(
                                            { x = gx + (math.random() - 0.5) * 0.35, y = gy, z = gz + (math.random() - 0.5) * 0.35 },
                                            member_speaker,
                                            true,
                                            false,
                                            {
                                                base_yaw = facing,
                                                idle_stand = (math.random(1, 2) == 1),
                                                has_sign = (not member_speaker) and (math.random(1, 5) == 1),
                                            }
                                        )
                                        spawned = spawned + 1
                                        if spawned >= to_spawn then
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
