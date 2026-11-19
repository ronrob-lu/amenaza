-- amenaza_compass
-- Standalone HUD compass and optional 24-hour clock for Amenaza.
-- Adapted from hud_compass by David_G (kestral246@gmail.com) so it is
-- completely independent of any external hud_compass mod or global settings.

local amenaza_compass = {}
local S = minetest.get_translator("amenaza_compass")
local storage = minetest.get_mod_storage()

-- State of amenaza_compass
--   1 = NE, 2 = SE, 3 = SW, 4 = NW (just compass)
--   5 = NE, 6 = SE, 7 = SW, 8 = NW (both compass and clock)
--   positive == enabled, negative == disabled

-- Define default (if not overridden): NE corner, compass only, enabled by default
local default_corner = tonumber(minetest.settings:get("amenaza_compass_default_corner")) or 1
if default_corner == 0 or default_corner < -8 or default_corner > 8 then
	default_corner = 1
end

local lookup_compass = {
	{type="image", text="", position={x=1,y=0}, scale={x=4,y=4}, alignment={x=-1,y=1}, offset={x=-8,y=4}, z_index=100},
	{type="image", text="", position={x=1,y=1}, scale={x=4,y=4}, alignment={x=-1,y=-1}, offset={x=-8,y=-4}, z_index=100},
	{type="image", text="", position={x=0,y=1}, scale={x=4,y=4}, alignment={x=1,y=-1}, offset={x=8,y=-4}, z_index=100},
	{type="image", text="", position={x=0,y=0}, scale={x=4,y=4}, alignment={x=1,y=1}, offset={x=8,y=4}, z_index=100},
	{type="image", text="", position={x=1,y=0}, scale={x=4,y=4}, alignment={x=-1,y=1}, offset={x=-76,y=4}, z_index=100},
	{type="image", text="", position={x=1,y=1}, scale={x=4,y=4}, alignment={x=-1,y=-1}, offset={x=-76,y=-4}, z_index=100},
	{type="image", text="", position={x=0,y=1}, scale={x=4,y=4}, alignment={x=1,y=-1}, offset={x=76,y=-4}, z_index=100},
	{type="image", text="", position={x=0,y=0}, scale={x=4,y=4}, alignment={x=1,y=1}, offset={x=76,y=4}, z_index=100}
}
local lookup_clock = {
	{type="image", text="", position={x=1,y=0}, scale={x=4,y=4}, alignment={x=-1,y=1}, offset={x=-8,y=4}, z_index=100},
	{type="image", text="", position={x=1,y=1}, scale={x=4,y=4}, alignment={x=-1,y=-1}, offset={x=-8,y=-4}, z_index=100},
	{type="image", text="", position={x=0,y=1}, scale={x=4,y=4}, alignment={x=1,y=-1}, offset={x=8,y=-4}, z_index=100},
	{type="image", text="", position={x=0,y=0}, scale={x=4,y=4}, alignment={x=1,y=1}, offset={x=8,y=4}, z_index=100},
	{type="image", text="", position={x=1,y=0}, scale={x=4,y=4}, alignment={x=-1,y=1}, offset={x=-8,y=4}, z_index=100},
	{type="image", text="", position={x=1,y=1}, scale={x=4,y=4}, alignment={x=-1,y=-1}, offset={x=-8,y=-4}, z_index=100},
	{type="image", text="", position={x=0,y=1}, scale={x=4,y=4}, alignment={x=1,y=-1}, offset={x=8,y=-4}, z_index=100},
	{type="image", text="", position={x=0,y=0}, scale={x=4,y=4}, alignment={x=1,y=1}, offset={x=8,y=4}, z_index=100}
}

-- backward compatibility (core version < 5.9.0)
local has_feature = (minetest and minetest.has_feature) or (core and core.has_feature)
local use_type_field = has_feature and has_feature("hud_def_type_field")
if not use_type_field then
	for _, t in pairs({lookup_compass, lookup_clock}) do
		for _, def in pairs(t) do
			def.hud_elem_type = def.type
			def.type = nil
		end
	end
end

local function build_hud_def(template, text)
	local def = {}
	for k, v in pairs(template) do
		def[k] = v
	end
	def.text = text or ""
	return def
end

local function get_compass_index(player)
	local dir = player:get_look_horizontal() or 0
	local angle_relative = math.deg(dir)
	return math.floor((angle_relative / 22.5) + 0.5) % 16
end

local function get_clock_index()
	return math.floor(24 * minetest.get_timeofday()) % 24
end

local function create_player_huds(player, corner)
	local abs_corner = math.abs(corner)
	local compass_idx = -1
	local compass_tex = ""
	if corner > 0 then
		compass_idx = get_compass_index(player)
		compass_tex = "amenaza_compass_" .. compass_idx .. ".png"
	end

	local id_clock = nil
	local clock_idx = -1
	if abs_corner >= 5 then
		local clock_tex = ""
		if corner >= 5 then
			clock_idx = get_clock_index()
			clock_tex = "amenaza_clock_" .. clock_idx .. ".png"
		end
		id_clock = player:hud_add(build_hud_def(lookup_clock[abs_corner], clock_tex))
	end

	return {
		id_compass = player:hud_add(build_hud_def(lookup_compass[abs_corner], compass_tex)),
		last_image_compass = compass_idx,
		id_clock = id_clock,
		last_image_clock = clock_idx,
		state = corner,
	}
end

local function remove_player_huds(player, data)
	if not data then
		return
	end
	if data.id_compass then
		player:hud_remove(data.id_compass)
		data.id_compass = nil
	end
	if data.id_clock then
		player:hud_remove(data.id_clock)
		data.id_clock = nil
	end
end

minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	local corner = default_corner
	local saved = storage:get(pname)
	if saved and tonumber(saved) then  -- validate mod storage value
		local temp = math.floor(tonumber(saved))
		if temp ~= 0 and temp >= -8 and temp <= 8 then
			corner = temp
		end
	end
	amenaza_compass[pname] = create_player_huds(player, corner)
end)

local compass_cmd_def = {
	params = "[<corner>]",
	description = S("Change display of HUD Compass."),
	privs = {},
	func = function(pname, params)
		local player = minetest.get_player_by_name(pname)
		local data = amenaza_compass[pname]
		if not player or not data then
			return false
		end
		if params and string.len(params) > 0 then  -- includes corner parameter
			local corner = tonumber(string.match(params, "^%d$"))
			if corner and corner == 0 then  -- disable compass and clock
				if data.id_compass then
					player:hud_change(data.id_compass, "text", "") -- blank hud compass
				end
				data.last_image_compass = -1
				if data.id_clock then
					player:hud_change(data.id_clock, "text", "") -- blank hud clock
				end
				data.last_image_clock = -1
				data.state = -1 * math.abs(data.state)
				storage:set_string(pname, tostring(data.state))
			elseif corner and corner >= 1 and corner <= 8 then  -- enable compass (and optionally clock) at given corner
				remove_player_huds(player, data)
				amenaza_compass[pname] = create_player_huds(player, corner)
				storage:set_string(pname, tostring(corner))
			end
		else  -- just toggle hud
			if data.state > 0 then  -- is enabled -> disable
				if data.id_compass then
					player:hud_change(data.id_compass, "text", "")  -- blank hud compass
				end
				data.last_image_compass = -1
				if data.id_clock then
					player:hud_change(data.id_clock, "text", "")  -- blank hud clock
				end
				data.last_image_clock = -1
			end
			data.state = -1 * data.state  -- toggle state
			storage:set_string(pname, tostring(data.state))
		end
	end,
}

if minetest.registered_chatcommands and minetest.registered_chatcommands["compass"] then
	minetest.override_chatcommand("compass", compass_cmd_def)
else
	minetest.register_chatcommand("compass", compass_cmd_def)
end

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	if amenaza_compass[pname] then
		amenaza_compass[pname] = nil
	end
end)

minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	local image_clock = get_clock_index()
	for _, player in ipairs(players) do
		local pname = player:get_player_name()
		local data = amenaza_compass[pname]
		if data and data.state > 0 then
			local image_compass = get_compass_index(player)
			if data.id_compass and image_compass ~= data.last_image_compass then
				local rc = player:hud_change(data.id_compass, "text", "amenaza_compass_" .. image_compass .. ".png")
				if rc then
					data.last_image_compass = image_compass
				end
			end
			if data.state >= 5 and data.id_clock and image_clock ~= data.last_image_clock then
				local rc = player:hud_change(data.id_clock, "text", "amenaza_clock_" .. image_clock .. ".png")
				if rc then
					data.last_image_clock = image_clock
				end
			end
		end
	end
end)
