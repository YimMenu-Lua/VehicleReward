local vehicle_tab = gui.get_tab("GUI_TAB_VEHICLE")

local GARAGE_MENU_DATA    = 195 -- 3A ? 42 ? 71 3A ? 42 ? 71 3A ? 42 ? 71 3A ? 42 ? 71 3A ? 42 ? 71 71 +1
local VEHICLE_REWARD_DATA = 148 -- 3A ? 40 ? 5D ? ? ? 2A +1

local should_run_script = false

-- It's actually possible to save blacklisted vehicles as PV, but doing so requires patching a lot of scripts, and once the patches are disabled, the game will instantly delete these vehicles anyway, so it's not worth it.
local function IS_VEHICLE_VALID_FOR_PV(vehicle_hash)
    return scr_function.call_script_function("freemode", "IVVFPV", "2D 01 03 00 00 38 00 5D ? ? ? 56 ? ? 72 2E 01 01 38 00 28", "bool", {
        { "int", vehicle_hash }
    })
end

local function GIVE_VEHICLE_REWARD(vehicle_id, data, transaction, garage, slot, state)
    return scr_function.call_script_function("am_mp_vehicle_reward", "GVR", "2D 0C 1E 00 00", "bool", {
        { "int", vehicle_id },
        { "ptr", data },
        { "ptr", transaction },
        { "ptr", garage },
        { "ptr", slot },
        { "ptr", state },
        { "bool", false }, -- ???
        { "bool", true },  -- Set as Last PV
        { "bool", true },  -- Display Cancel Error Message
        { "bool", false }, -- Is Podium Vehicle
        { "int", 0 },      -- ???
        { "int", -1 }      -- ???
    })
end

local function RUN_SCRIPT()
    if not ENTITY.DOES_ENTITY_EXIST(self.get_veh()) then
        should_run_script = false
        return
    end

    local menu_data          = locals.get_pointer("am_mp_vehicle_reward", GARAGE_MENU_DATA)
    local transaction_result = locals.get_pointer("am_mp_vehicle_reward", VEHICLE_REWARD_DATA + 4)
    local garage_id          = locals.get_pointer("am_mp_vehicle_reward", VEHICLE_REWARD_DATA + 5)
    local garage_slot        = locals.get_pointer("am_mp_vehicle_reward", VEHICLE_REWARD_DATA + 6)
    local reward_state       = locals.get_pointer("am_mp_vehicle_reward", VEHICLE_REWARD_DATA + 7)
	
    if GIVE_VEHICLE_REWARD(self.get_veh(), menu_data, transaction_result, garage_id, garage_slot, reward_state) then
        if locals.get_int("am_mp_vehicle_reward", VEHICLE_REWARD_DATA + 7) ~= 3 then
            locals.set_int("am_mp_vehicle_reward", VEHICLE_REWARD_DATA + 4, 0)
            locals.set_int("am_mp_vehicle_reward", VEHICLE_REWARD_DATA + 5, 0)
            locals.set_int("am_mp_vehicle_reward", VEHICLE_REWARD_DATA + 6, 0)
            locals.set_int("am_mp_vehicle_reward", VEHICLE_REWARD_DATA + 7, 0)
            should_run_script = false
        end
    end
end

script.register_looped("Vehicle Reward", function()
    if not script.is_active("am_mp_vehicle_reward") then
        should_run_script = false
        return
    end

    if should_run_script then
        RUN_SCRIPT()
    end
end)

vehicle_tab:add_button("Claim Current Vehicle as PV", function()
    script.run_in_fiber(function()
        if network.is_session_started() and script.is_active("freemode") and script.is_active("am_mp_vehicle_reward") then
            if PED.IS_PED_IN_ANY_VEHICLE(self.get_ped(), false) then
                if IS_VEHICLE_VALID_FOR_PV(ENTITY.GET_ENTITY_MODEL(self.get_veh())) then
                    should_run_script = true
                else
                    gui.show_error("Vehicle Reward", "This vehicle cannot be saved as a personal vehicle.")
                end
            else
                gui.show_error("Vehicle Reward", "Please get in a vehicle.")
            end
        else
            gui.show_error("Vehicle Reward", "Cannot give vehicle at the moment. Are you online?")
        end
    end)

end)
