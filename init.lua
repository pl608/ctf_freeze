ctf_freeze = {}
ctf_freeze.frozen = {}
ctf_freeze.health = {}

ctf_freeze.use_freeze = true

function reg_entity(team)
    minetest.register_entity("ctf_freeze:fe_" .. team, {
        initial_properties = {
            visual = "cube",
            visual_size = {x=1,y=2},
            textures = {"default_ice.png","default_ice.png","default_ice.png","default_ice.png","default_ice.png","default_ice.png"},
            is_visible = true,
            physical = true,
            makes_footstep_sound = false,
            backface_culling = false,
            static_save = false,
            pointable = true,
            collision_box = {-2,-2,-2,2,2,2},
            armor_groups = {immortal=1},
        },
        on_punch = function(self, puncher) 
            if tostring(ctf_teams.get(puncher)) == team then
                ctf_freeze.thaw(self, puncher) 
            end 
        end,
        on_activate = function(self)
            local obj = self.object
            obj:set_armor_groups({immortal=1})
        end
    })
end

reg_entity("red")
reg_entity("blue")
reg_entity("orange")
reg_entity("green")
reg_entity("purple")

minetest.register_on_joinplayer(function(player)
    local istrapped = player:get_attribute("freeze:istrapped")

    if istrapped then
        trap = player:get_player_name()
        mode = "a"
        local pos = player:get_pos()

        minetest.after(0.3,function()
            minetest.add_entity(pos, "ctf_freeze:fe")
        end)
    end
end)

minetest.register_on_leaveplayer(function(player)
    local ppos = player:get_pos()
    for _, obj in ipairs(minetest.get_objects_inside_radius(ppos, 2)) do
        obj:remove()
    end
end)

function ctf_freeze.freeze(param)
	local player = param
    local team = ctf_teams.get(player)
    if player:get_attribute("ctf_freeze:f") == "true" then return end -- Player already frozen... looks like this enables pestering when frozen
    local obj = minetest.add_entity(player:get_pos(), "ctf_freeze:fe_"..team)
    local ent = obj:get_luaentity()
    ent.player = player
    if obj then
        --minetest.close_formspec(player:get_player_name(), "")
        player:set_attach(obj)
        player:set_properties({visual_size = {x=1,y=.5}})
        player:set_attribute("ctf_freeze:f", "true")
		ctf_freeze.frozen[player:get_player_name()] = obj
		ctf_freeze.health[player:get_player_name()] = player:get_properties().hp_max
	end
end

function ctf_freeze.thaw(self, player, force_thaw)
    if force_thaw == nil then force_thaw = false end
    local obj = self.object
    local pname = player:get_player_name()
    local tplayer = self.player
    if ctf_freeze.frozen[player:get_player_name()] ~= nil and force_thaw == false then return end-- hopefully not frozen guys freeing themselves
    if player:get_attribute("ctf_freeze:f") == "true" and force_thaw == false then return end-- double check with another method
    tplayer:set_attribute("ctf_freeze:f", nil)
    tplayer:set_properties({visual_size = {x=1,y=1}})
    tplayer:set_properties({hp_max = ctf_freeze.health[pname]})
    ctf_freeze.frozen[tplayer:get_player_name()] = nil
    --minetest.log(tostring(player:get_attribute("ctf_freeze:f") ~= "true"))
    obj:remove()
end

minetest.register_on_leaveplayer(function(ObjectRef, timed_out)
    local player = ObjectRef
    if ctf_freeze.frozen[player:get_player_name()] ~= nil then
        local obj = ctf_freeze.frozen[player:get_player_name()]
    end
    player:set_attribute("ctf_freeze:f", nil)
    ctf_freeze.frozen[player:get_player_name()] = nil
    ctf_freeze.health[player:get_player_name()] = nil
    if obj then
        obj:remove()
    end
end)

minetest.register_on_joinplayer(function(ObjectRef, last_login)
    local player = ObjectRef
    if ctf_freeze.frozen[player:get_player_name()] ~= nil then
        local obj = ctf_freeze.frozen[player:get_player_name()]
    end
    player:set_attribute("ctf_freeze:f", nil)
    ctf_freeze.frozen[player:get_player_name()] = nil
    ctf_freeze.health[player:get_player_name()] = nil
    if obj then
        obj:remove()
    end
end)

minetest.register_chatcommand("end", {
    description = "End build time",
    privs = {ctf_admin = true},
    func = function()
        ctf_modebase.build_timer.finish()
    end
})

minetest.register_chatcommand("freeze", {
    description = "Freeze a player if not frozen",
    privs = {ctf_admin = true},
    params = "<player>",
    func = function(name, param)
        if param == nil then return false, "No player name specified" end
        local player = minetest.get_player_by_name(param)
        if player:get_attribute("ctf_freeze:f") == "true" then return false, "Player already frozen!" end --Player is already frozen
        ctf_freeze.freeze(minetest.get_player_by_name(freeze))
    end
})

minetest.register_chatcommand("thaw", {
    description = "Thaw a player out(If frozen)",
    privs = {ctf_admin = true},
    params = "<player>",
    func = function(name, param)
        if param == nil then return false end
        local player = minetest.get_player_by_name(param)
        if player:get_attribute("ctf_freeze:f") == nil then return false, "Player not frozen!" end --Player is not frozen
        local obj = ctf_freeze.frozen[param]
        local luaent = obj:get_luaentity()
        ctf_freeze.thaw(luaent, minetest.get_player_by_name(name), true)
    end
})

minetest.register_chatcommand("thawme", {
    description = "Thaws yourself (If frozen)",
    privs = {ctf_admin = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player:get_attribute("ctf_freeze:f") == nil then return false, "Player not frozen!" end --Player is not frozen
        local obj = ctf_freeze.frozen[name]
        local luaent = obj:get_luaentity()
        ctf_freeze.thaw(luaent, player, true)
    end
})

if ctf_freeze.use_freeze == true then
    function ctf_modebase.prepare_respawn_delay(player)
        --minetest.close_formspec(player:get_player_name(), "")
        ctf_freeze.freeze(player)
    end
end