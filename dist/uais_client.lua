
---------------------------------------------------------
---------------- Auto Bundled Code Block ----------------
---------------------------------------------------------

do
    local searchers = package.searchers or package.loaders
    local origin_seacher = searchers[2]
    searchers[2] = function(path)
        local files =
        {
------------------------
-- Modules part begin --
------------------------

["uais_shared_tag_collection_a_1_0"] = function()
--------------------
-- Module: 'uais_shared_tag_collection_a_1_0'
--------------------
-- Experimental tag collection module compatible with SAPP and Chimera's APIs.

-- Text tags: "NOTE"

module_table = {}

local module_console_name = "UAIS (Tag collection $)"
local module_console_color = 0xF

local actor_variant_tag_paths -- Tag paths
local biped_tag_paths
local vehicle_tag_paths
local weapon_tag_paths
local biped_tag_ids -- Tag IDs
local vehicle_tag_ids
local weapon_tag_ids
local scnr_tag_data -- Scenario tag data address

-- Functions

function ResetTagTables()
	actor_variant_tag_paths = {}
	biped_tag_paths = {}
	vehicle_tag_paths = {}
	weapon_tag_paths = {}
	biped_tag_ids = {}
	vehicle_tag_ids = {}
	weapon_tag_ids = {}
	scnr_tag_data = nil
end

function LoadTagTables(API) -- 1 == SAPP, 2 == Chimera
	ResetTagTables() -- Clear previous map's tag paths and tag IDs
	local scnr_tag_path_address = read_dword(0x40440028 + 0x10) -- Get (NOTE: Main or current?) scenario tag path and address
	local scnr_tag_path = read_string(scnr_tag_path_address)
	local scnr_tag_address
	if API == 1 then
		scnr_tag_address = lookup_tag("scnr", scnr_tag_path)
	elseif API == 2 then
		scnr_tag_address = get_tag("scnr", scnr_tag_path)
	end
	scnr_tag_data = read_dword(scnr_tag_address + 0x14)
	LoadScenarioVehicles(API)
	LoadGlobalsVehicles(API)
	LoadScenarioBipeds(API)
	LoadActorVariantBipeds(API)
end

-- NOTE: Vehicles

function LoadScenarioVehicles(API)
	local vehicles_count = read_dword(scnr_tag_data + 0x24C) -- Vehicles from the "Vehicle Palette" struct.
	local vehicles_first_address = read_dword(scnr_tag_data + 0x24C + 4)
	if vehicles_count > 0 then
		for i = 0, vehicles_count - 1 do
			local vehicle_address = vehicles_first_address + i * 48
			local vehicle_dependency_tag_path = read_string(read_dword(vehicle_address + 0x4))
			if vehicle_dependency_tag_path then
				TryToAddVehicleTag(API, vehicle_dependency_tag_path)
			end
		end
	end
end

function LoadGlobalsVehicles(API)
	local globals_tag_address
	if API == 1 then
		globals_tag_address = lookup_tag("matg", "globals\\globals")
	elseif API == 2 then
		globals_tag_address = get_tag("matg", "globals\\globals")
	end
	local globals_tag_data = read_dword(globals_tag_address + 0x14)
	local multiplayer_information_struct_address = read_dword(globals_tag_data + 0x164 + 4) -- Single item struct
	local vehicles_count = read_dword(multiplayer_information_struct_address + 0x20) -- Vehicles from the struct inside the "Multiplayer information" struct
	local vehicles_first_address = read_dword(multiplayer_information_struct_address + 0x20 + 4)
	if vehicles_count > 0 then
		for i = 0, vehicles_count - 1 do
			local vehicle_address = vehicles_first_address + i * 16
			local vehicle_dependency_tag_path = read_string(read_dword(vehicle_address + 0x4))
			if vehicle_dependency_tag_path then
				TryToAddVehicleTag(API, vehicle_dependency_tag_path)
			end
		end
	end
end

function TryToAddVehicleTag(API, VehicleTagPath)
	local new = true
	for i = 1, #vehicle_tag_paths do
		local tag_path = vehicle_tag_paths[i]
		if tag_path == VehicleTagPath then
			new = false
		end
	end
	if new then
		local tag_address
		if API == 1 then
			tag_address = lookup_tag("vehi", VehicleTagPath)
		elseif API == 2 then
			tag_address = get_tag("vehi", VehicleTagPath)
		end
		local tag_id = read_dword(tag_address + 0xC)
		table.insert(vehicle_tag_paths, VehicleTagPath)
		table.insert(vehicle_tag_ids, tag_id)
		if API == 1 then
			cprint(module_console_name..": Vehicle tag registered #"..#vehicle_tag_paths..": "..VehicleTagPath, module_console_color)
		elseif API == 2 then
			-- console_out(module_console_name..": Vehicle tag registered #"..#vehicle_tag_paths..": "..VehicleTagPath)
		end
		LoadVehicleSeatBipeds(API, tag_address)
	end
end

-- NOTE: Bipeds

function LoadScenarioBipeds(API)
	local bipeds_count = read_dword(scnr_tag_data + 0x234) -- Bipeds from the "Biped Palette" struct.
	local bipeds_first_address = read_dword(scnr_tag_data + 0x234 + 4)
	if bipeds_count > 0 then
		for i = 0, bipeds_count - 1 do
			local biped_address = bipeds_first_address + i * 48
			local biped_dependency_tag_path = read_string(read_dword(biped_address + 0x4))
			if biped_dependency_tag_path then
				TryToAddBipedTag(API, biped_dependency_tag_path)
			end
		end
	end
end

function LoadActorVariantBipeds(API)
	local actor_variants_count = read_dword(scnr_tag_data + 0x420) -- Bipeds from the "Actor Palette" struct.
	local actor_variants_first_address = read_dword(scnr_tag_data + 0x420 + 4)
	if actor_variants_count > 0 then
		for i = 0, actor_variants_count - 1 do
			local actor_variant_address = actor_variants_first_address + i * 16
			local actor_variant_tag_dependency_path = read_string(read_dword(actor_variant_address + 0x4))
			if actor_variant_tag_dependency_path then
				TryToAddActorVariantBipedTag(API, actor_variant_tag_dependency_path)
			end
		end
	end
end

function LoadVehicleSeatBipeds(API, VehicleTagAddress)
	local vehicle_tag_data = read_dword(VehicleTagAddress + 0x14)
	local seats_count = read_dword(vehicle_tag_data + 0x2E4)
	local seats_first_address = read_dword(vehicle_tag_data + 0x2E4 + 4)
	if seats_count > 0 then
		for i = 0, seats_count - 1 do
			local seat_address = seats_first_address + i * 284
			local built_in_rider_dependency_tag_path = read_string(read_dword(seat_address + 0xF8 + 0x4))
			if built_in_rider_dependency_tag_path then
				TryToAddActorVariantBipedTag(API, built_in_rider_dependency_tag_path)
			end
		end
	end
end

function TryToAddActorVariantBipedTag(API, ActorVariantTagPath)
	local actor_variant_tag_address
	if API == 1 then
		actor_variant_tag_address = lookup_tag("actv", ActorVariantTagPath)
	elseif API == 2 then
		actor_variant_tag_address = get_tag("actv", ActorVariantTagPath)
	end
	local actor_variant_tag_data = read_dword(actor_variant_tag_address + 0x14)
	local actor_variant_tag_unit_tag_dependency_path = read_string(read_dword(actor_variant_tag_data + 0x14 + 0x4))
	if actor_variant_tag_unit_tag_dependency_path then
		TryToAddBipedTag(API, actor_variant_tag_unit_tag_dependency_path)
		TryToAddActorVariantTagPath(API, ActorVariantTagPath)
		local weapon_tag_dependency_path = read_string(read_dword(actor_variant_tag_data + 0x64 + 0x4)) -- Add actor variant weapon tag path.
		if weapon_tag_dependency_path then
			TryToAddWeaponTag(API, weapon_tag_dependency_path)
		end
		local major_variant_tag_dependency_path = read_string(read_dword(actor_variant_tag_data + 0x24 + 0x4)) -- "Major variant" of this actor variant.
		if major_variant_tag_dependency_path then
			TryToAddActorVariantBipedTag(API, major_variant_tag_dependency_path)
		end
	end
end

function TryToAddBipedTag(API, BipedTagPath)
	local new = true
	for i = 1, #biped_tag_paths do
		local tag_path = biped_tag_paths[i]
		if tag_path == BipedTagPath then
			new = false
		end
	end
	if new then
		local tag_address
		if API == 1 then
			tag_address = lookup_tag("bipd", BipedTagPath)
		elseif API == 2 then
			tag_address = get_tag("bipd", BipedTagPath)
		end
		local tag_id = read_dword(tag_address + 0xC)
		table.insert(biped_tag_paths, BipedTagPath)
		table.insert(biped_tag_ids, tag_id)
		if API == 1 then
			cprint(module_console_name..": Biped tag registered #"..#biped_tag_paths..": "..BipedTagPath, module_console_color)
		elseif API == 2 then
			-- console_out(module_console_name..": Biped tag registered #"..#biped_tag_paths..": "..BipedTagPath)
		end
		local tag_data = read_dword(tag_address + 0x14) -- Add biped weapon tag path(s).
		local weapons_count = read_dword(tag_data + 0x2D8)
		local weapons_first_address = read_dword(tag_data + 0x2D8 + 4)
		if weapons_count > 0 then
			for i = 0, weapons_count - 1 do
				local weapon_address = weapons_first_address + i * 36
				local weapon_dependency_tag_path = read_string(read_dword(weapon_address + 0x4))
				if weapon_dependency_tag_path then
					TryToAddWeaponTag(API, weapon_dependency_tag_path)
				end
			end
		end
	end
end

-- NOTE: Weapons

function TryToAddWeaponTag(API, WeaponTagPath)
	local new = true
	for i = 1, #weapon_tag_paths do
		local tag_path = weapon_tag_paths[i]
		if tag_path == WeaponTagPath then
			new = false
		end
	end
	if new then
		local tag_address
		if API == 1 then
			tag_address = lookup_tag("weap", WeaponTagPath)
		elseif API == 2 then
			tag_address = get_tag("weap", WeaponTagPath)
		end
		local tag_id = read_dword(tag_address + 0xC)
		table.insert(weapon_tag_paths, WeaponTagPath)
		table.insert(weapon_tag_ids, tag_id)
		if API == 1 then
			cprint(module_console_name..": Weapon tag registered #"..#weapon_tag_paths..": "..WeaponTagPath, module_console_color)
		elseif API == 2 then
			-- console_out(module_console_name..": Weapon tag registered #"..#weapon_tag_paths..": "..WeaponTagPath)
		end
	end
end

-- NOTE: Actor variants, this one is necessary for a tag manipulation module function

function TryToAddActorVariantTagPath(API, ActorVariantTagPath)
	local new = true
	for i = 1, #actor_variant_tag_paths do
		local tag_path = actor_variant_tag_paths[i]
		if tag_path == ActorVariantTagPath then
			new = false
		end
	end
	if new then
		table.insert(actor_variant_tag_paths, ActorVariantTagPath)
		if API == 1 then
			cprint(module_console_name..": Actor variant tag registered #"..#actor_variant_tag_paths..": "..ActorVariantTagPath, module_console_color)
		elseif API == 2 then
			-- console_out(module_console_name..": Actor variant tag registered #"..#actor_variant_tag_paths..": "..ActorVariantTagPath)
		end
	end
end

-- NOTE: Export variables

function actv_tag_paths() return actor_variant_tag_paths end
function bipd_tag_paths() return biped_tag_paths end
function vehi_tag_paths() return vehicle_tag_paths end
function weap_tag_paths() return weapon_tag_paths end
function bipd_tag_ids() return biped_tag_ids end
function vehi_tag_ids() return vehicle_tag_ids end
function weap_tag_ids() return weapon_tag_ids end
function scnr_tag_data() return scnr_tag_data end

-- NOTE: Module setup

module_table.actv_tag_paths = actv_tag_paths
module_table.bipd_tag_paths = bipd_tag_paths
module_table.vehi_tag_paths = vehi_tag_paths
module_table.weap_tag_paths = weap_tag_paths
module_table.bipd_tag_ids = bipd_tag_ids
module_table.vehi_tag_ids = vehi_tag_ids
module_table.weap_tag_ids = weap_tag_ids
module_table.scnr_tag_data = scnr_tag_data

module_table.LoadTagTables = LoadTagTables

return module_table
end,

["uais_shared_tag_manipulation_a_1_0"] = function()
--------------------
-- Module: 'uais_shared_tag_manipulation_a_1_0'
--------------------
-- Experimental tag manipulation module compatible with SAPP and Chimera's APIs.

--[[

Things that will be disabled/modified server-side:
	- AI vehicle combat

Things that will be disabled/modified client-side:
	- Client side AI spawns (from the biped and encounter palettes, also from vehicles with built-in riders)
	- Biped collision model region health bounds that may cause desynchronization issues

--]]

-- Text tags: "NOTE"
-- NOTE: Patch animations and scripted AI spawns client-side if necessary.

module_table = {}

local module_console_name = "UAIS (Tag manipulation $)"
local module_console_color = 0xF

-- Functions

function TagManipulationServerSide(API, ActorVariantTagPaths)
	DisableAIVehicleCombat(API, ActorVariantTagPaths)
end

function TagManipulationClientSide(API, ScenarioTagData, BipedTagPaths, VehicleTagPaths)
	DisableScenarioEncounters(API, ScenarioTagData)
	DisableScenarioBipeds(API, ScenarioTagData)
	DisableVehicleBuiltInRiders(API, VehicleTagPaths)
	PatchBipedCollisionModels(API, BipedTagPaths)
end

-- NOTE: Disable AI

function DisableScenarioEncounters(API, ScenarioTagData)
	local encounters_count = read_dword(ScenarioTagData + 0x42C)
	local encounters_first_address = read_dword(ScenarioTagData + 0x42C + 4)
	if encounters_count > 0 then
		for i = 0, encounters_count - 1 do
			local encounter_address = encounters_first_address + i * 176
			-- local encounter_name = read_string(encounter_address)
			local bitmask_address = encounter_address + 0x20
			local not_initially_created
			local respawn_enabled
			if API == 1 then -- NOTE: SAPP's API only addresses a single byte, just a reminder
				not_initially_created = read_bit(bitmask_address, 0)
				respawn_enabled = read_bit(bitmask_address, 1)
			elseif API == 2 then
				not_initially_created = read_bit(bitmask_address, 0)
				respawn_enabled = read_bit(bitmask_address, 1)
			end
			if not_initially_created == 0 then
				if API == 1 then
					write_bit(bitmask_address, 0, 1)
				elseif API == 2 then
					write_bit(bitmask_address, 0, 1)
				end
			end
			if respawn_enabled == 1 then
				if API == 1 then
					write_bit(bitmask_address, 1, 0)
				elseif API == 2 then
					write_bit(bitmask_address, 1, 0)
				end
			end
		end
	end
end

function DisableScenarioBipeds(API, ScenarioTagData)
	local bipeds_count = read_dword(ScenarioTagData + 0x228)
	local bipeds_first_address = read_dword(ScenarioTagData + 0x228 + 4)
	if bipeds_count > 0 then
		for i = 0, bipeds_count - 1 do
			local biped_address = bipeds_first_address + i * 120
			local bitmask_address = biped_address + 0x4
			local not_placed_automatically
			if API == 1 then
				not_placed_automatically = read_bit(bitmask_address, 0)
			elseif API == 2 then
				not_placed_automatically = read_bit(bitmask_address, 0)
			end
			if not_placed_automatically == 0 then
				if API == 1 then
					write_bit(bitmask_address, 0, 1)
				elseif API == 2 then
					write_bit(bitmask_address, 0, 1)
				end
			end
		end
	end
end

function DisableVehicleBuiltInRiders(API, VehicleTagPaths)
	for i = 1, #VehicleTagPaths do
		local tag_path = VehicleTagPaths[i]
		local tag_address
		if API == 1 then
			tag_address = lookup_tag("vehi", tag_path)
		elseif API == 2 then
			tag_address = get_tag("vehi", tag_path)
		end
		local tag_data = read_dword(tag_address + 0x14)
		local seats_count = read_dword(tag_data + 0x2E4)
		local seats_first_address = read_dword(tag_data + 0x2E4 + 4)
		if seats_count > 0 then
			for j = 0, seats_count - 1 do
				local seat_address = seats_first_address + j * 284
				local seat_built_in_rider_tag_dependency_path = read_string(read_dword(seat_address + 0xF8 + 4))
				-- local seat_label = read_string(seat_address + 0x04)
				-- local seat_built_in_gunner_tag_dependency_id = read_dword(seat_address + 0xF8 + 0xC)
				if seat_built_in_gunner_tag_dependency_path then
					write_dword(seat_address + 0xF8 + 0xC, 0xFFFFFFFF) -- Nulled
				end
			end
		end
	end
end

-- NOTE: Disable biped collision model health bounds

function PatchBipedCollisionModels(API, BipedTagPaths)
	for i = 1, #BipedTagPaths do
		local tag_path = BipedTagPaths[i]
		local tag_address
		if API == 1 then
			tag_address = lookup_tag("bipd", tag_path)
		elseif API == 2 then
			tag_address = get_tag("bipd", tag_path)
		end
		local tag_data = read_dword(tag_address + 0x14)
		local collision_model_tag_dependency_path = read_string(read_dword(tag_data + 0x70 + 4))
		if collision_model_tag_dependency_path then
			local coll_tag_address
			if API == 1 then
				coll_tag_address = lookup_tag("coll", collision_model_tag_dependency_path)
			elseif API == 2 then
				coll_tag_address = get_tag("coll", collision_model_tag_dependency_path)
			end
			local coll_tag_data = read_dword(coll_tag_address + 0x14)
			local regions_count = read_dword(coll_tag_data + 0x240)
			local regions_first_address = read_dword(coll_tag_data + 0x240 + 4)
			if regions_count > 0 then
				for j = 0, regions_count - 1 do
					local region_address = regions_first_address + j * 84
					-- local region_name = read_string(region_address)
					local bitmask_address = region_address + 0x20
					local forces_weapon_drop_bit
					if API == 1 then
						forces_weapon_drop_bit = read_bit(bitmask_address + 1, 0) -- NOTE: Needs testing
					elseif API == 2 then
						forces_weapon_drop_bit = read_bit(bitmask_address, 8)
					end
					if forces_weapon_drop_bit == 1 then
						local damage_threshold_address = region_address + 0x28
						if API == 1 then
							write_bit(bitmask_address + 1, 0, 0) -- NOTE: Needs testing
						elseif API == 2 then
							write_bit(bitmask_address, 8, 0)
						end
						write_float(damage_threshold_address, 0) -- Set to 0 (invincible)
					end
				end
			end
		end
	end
end

-- NOTE: Disable AI vehicle combat

function DisableAIVehicleCombat(API, ActorVariantTagPaths)
	for i = 1, #ActorVariantTagPaths do
		local tag_path = ActorVariantTagPaths[i]
		local tag_address
		if API == 1 then
			tag_address = lookup_tag("actv", tag_path)
		elseif API == 2 then
			tag_address = get_tag("actv", tag_path)
		end
		local tag_data = read_dword(tag_address + 0x14)
		local actor_tag_dependency_path = read_string(read_dword(tag_data + 0x04 + 0x4))
		local actr_tag_address
		if API == 1 then
			actr_tag_address = lookup_tag("actr", actor_tag_dependency_path)
		elseif API == 2 then
			actr_tag_address = get_tag("actr", actor_tag_dependency_path)
		end
		local actr_tag_data = read_dword(actr_tag_address + 0x14)
		local actr_more_flags_bitmask_address = actr_tag_data + 0x04
		local disallow_vehicle_combat_bit
		if API == 1 then
			disallow_vehicle_combat_bit = read_bit(actr_more_flags_bitmask_address, 3)
		elseif API == 2 then
			disallow_vehicle_combat_bit = read_bit(actr_more_flags_bitmask_address, 3)
		end
		if disallow_vehicle_combat_bit == 0 then
			if API == 1 then
				write_bit(actr_more_flags_bitmask_address, 3, 1)
			elseif API == 2 then
				write_bit(actr_more_flags_bitmask_address, 3, 1)
			end
		end
	end
end

-- NOTE: Module setup

module_table.TagManipulationServerSide = TagManipulationServerSide
module_table.TagManipulationClientSide = TagManipulationClientSide

return module_table
end,

["uais_shared_object_table_a_1_0"] = function()
--------------------
-- Module: 'uais_shared_object_table_a_1_0'
--------------------
-- Yeah. I know what this does, or at least should... No need to write it twice.
-- "NOTE"

module_table = {}

local module_console_name = "UAIS (Object table hook $)"
local module_console_color = 0xF

local client_1_10_object_table_address = 0x400506B4 -- Credits to Devieth
local sapp_1_10_object_table_address

-- Functions

function LoadSAPPObjectTableAddress()
	sapp_1_10_object_table_address = read_dword(read_dword(sig_scan("8B0D????????8B513425FFFF00008D") + 2)) -- Credits to Devieth.
	cprint(module_console_name..": ".."SAPP object table address loaded!", module_console_color)
end

function GetObjects(API, ObjectType, Items) 
	-- API: 1 = SAPP, 2 = Chimera
	-- ObjectType: 0 = Bipeds, 1 = Vehicles (possible values for an object's "type" variable)
	-- Items: 1 = Object IDs, 2 = Object memory addresses, 3 = Both (see further)
	local final_object_ids = {}
	local final_object_addresses = {}
	local object_count
	local object_base
	if API == 1 then
		if not sapp_1_10_object_table_address then
			LoadSAPPObjectTableAddress()
		end
		object_count = read_word(sapp_1_10_object_table_address + 0x2E)
		object_base = read_dword(sapp_1_10_object_table_address + 0x34)
	elseif API == 2 then
		object_count = read_word(client_1_10_object_table_address + 0x2E)
		object_base = read_dword(client_1_10_object_table_address + 0x34)
	end
	for i = 0, object_count - 1 do
		local object_address = read_dword(object_base + i * 0xC + 0x8)
		local object_id = read_word(object_base + i * 12) * 0x10000 + i
		if object_address ~= 0 then
			local object_type = read_word(object_address + 0xB4)
			if object_type == ObjectType then
				if Items == 1 then
					table.insert(final_object_ids, object_id)
				elseif Items == 2 then
					table.insert(final_object_addresses, object_address)
				elseif Items == 3 then
					table.insert(final_object_ids, object_id)
					table.insert(final_object_addresses, object_address)
				end
			end
		end
	end
	if Items == 1 then -- Output
		return final_object_ids
	elseif Items == 2 then
		return final_object_addresses
	elseif Items == 3 then
		return {final_object_ids, final_object_addresses}
	end
end

function HideAutoGeneratedBipeds(UAISClientSyncedBipeds) -- NOTE: Chimera API specific
	local total_bipeds = GetObjects(2, 0, 1)
	for k, v in pairs(total_bipeds) do
		local automatically_generated = true
		for i, b in pairs(UAISClientSyncedBipeds) do
			if v == b then
				automatically_generated = false
				break
			end
		end
		if automatically_generated then
			local object_address = get_object(v)
			if object_address then
				local player_id = read_dword(object_address + 0xC0)
				if player_id == 0xFFFFFFFF then -- NOTE: Might also hide player corpses, minor issue that could be fixed later
					write_bit(object_address + 0x10, 0, 1) -- Ghost mode = True
					write_bit(object_address + 0x10, 24, 1) -- No collision = True
				end
			end
		end
	end
end

-- NOTE: Module setup

module_table.GetObjects = GetObjects
module_table.HideAutoGeneratedBipeds = HideAutoGeneratedBipeds

return module_table
end,

["uais_shared_data_compression_a_1_0"] = function()
--------------------
-- Module: 'uais_shared_data_compression_a_1_0'
--------------------

-- Pending: Must check 6-bit integer com << >> decom, decom probably not working, and Base85ToNumber...

module_table = {}

local char_table = { -- NOTE: Unicode character set (Available: 32 <-> 126 [All] & 160 <-> 255 [confirmed: 160 <-> 176])
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
	"k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
	"u", "v", "w", "x", "y", "z", "A", "B", "C", "D",
	"E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
	"O", "P", "Q", "R", "S", "T", "U", "V", "W", "X",
	"Y", "Z", "!", "+", "#", "$", "%", "&", "~", "(",
	")", "=", ",", "*", ".", ":", "-", "_", "<", ">",
	"{", "}", "[", "]", "?"
}

local nums_table = {} -- TESTING: Filled manually...

-- Functions

function LoadCharValuesTable() -- NOTE: OnScriptLoad (SAPP) / OnGameStart (Chimera)
	if #nums_table == 0 then
		for k, v in pairs(char_table) do
			nums_table[v] = k - 1
		end
	end
end

-- Compression functions

function Integer6ToPrintableChar(Value, Table) -- 0 <= Value <= 63 / NOTE: Can accept either a number or a 6 bit (0/1) table.
	--[[ Used for:
		- 6-bit bitmasks (Big endian)
		- Positive integers smaller than 64
	--]]
	local char
	if Table then
		char = string.format("%c", tonumber(table.concat(Table), 2) + 32)
	else -- Added
		char = string.char(Value + 32)
	end
	return char
end

function Word16ToHex(Value) -- 0 <= Value <= 65535
	--[[ Used for:
		- Object indexes
		- Animation IDs 
	--]]
	local raw_hex = string.format("%x", Value)
	local hex = string.sub("0000"..raw_hex, -4, -1)
	return hex
end

function Dword32ToBase85(Value) -- NOTE: Testing, compress long number to a 5 char string...
	local q = Value
	local e = 0
	local d = 0
	local c = 0
	local b = 0
	local a = 0
	local base85 = nil
	while q > (51586500 + 606900 + 7140 + 84) do -- Tens of thousands
		q = q - 52200625
		e = e + 1
	end
	while q > (606900 + 7140 + 84) do -- Thousands
		q = q - 614125
		d = d + 1
	end
	while q > (7140 + 84) do -- Hundreds
		q = q - 7225
		c = c + 1
	end
	while q > 84 do -- Tens
		q = q - 85
		b = b + 1
	end
	a = q -- Units
	e = char_table[(e + 1)]
	d = char_table[(d + 1)]
	c = char_table[(c + 1)]
	b = char_table[(b + 1)]
	a = char_table[(a + 1)]
	base85 = e..d..c..b..a -- NOTE: Could be improved, using a table and performing "concat" instead of individual variables
	return base85
end

-- Decompression functions

function PrintableCharToInteger6(String, IsTable) -- NOTE: If "IsTable" is true, then returns a 6 bit (0/1) bitmask.
	local num = string.byte(String) - 32
	if IsTable then
		local bitmask = {0, 0, 0, 0, 0 ,0} -- NOTE: Big endian. Decimal to binary conversion.
		local bit_index = 0
		local q = num
		local m
		while q > 0 do
			m = q % 2
			q = math.floor(q/2)
			bitmask[6 - bit_index] = m
			bit_index = bit_index + 1
		end
		return bitmask
	end
	return num
end

function HexToNumber(String)
	local num = tonumber(String, 16)
	return num
end

function Base85ToNumber(String)
	local num = 0
	local e = nums_table[string.sub(String, 1, 1)]
	local d = nums_table[string.sub(String, 2, 2)]
	local c = nums_table[string.sub(String, 3, 3)]
	local b = nums_table[string.sub(String, 4, 4)]
	local a = nums_table[string.sub(String, 5, 5)]

	num = e * 52200625 + d * 614125 + c * 7225 + b * 85 + a
	return num
end

-- Math functions

function Dword32ToFloat(Value)
	local binary = {0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0} -- NOTE: Stored in big endian.
	local bit_index = 0
	local q = Value
	local m
	while q > 0 do
		m = q % 2
		q = math.floor(q/2)
		binary[32 - bit_index] = m
		bit_index = bit_index + 1
	end
	local b_sign = binary[1]
	local b_exponent = -127
	local b_mantissa = 1
	for i = 1, 8 do -- Calculate exponent.
		local bit_value = 2 ^ (8 - i)
		if binary[i + 1] == 1 then
			b_exponent = b_exponent + bit_value
		end
	end
	for i = 1, 23 do -- Calculate mantissa.
		local bit_value = 2 ^ (-i)
		if binary[i + 9] == 1 then
			b_mantissa = b_mantissa + bit_value
		end
	end
	local float = (-1) ^ b_sign * 2 ^ b_exponent * b_mantissa
	return float
end

-- Module setup

module_table.LoadCharValuesTable = LoadCharValuesTable

module_table.Integer6ToPrintableChar = Integer6ToPrintableChar
module_table.Word16ToHex = Word16ToHex
module_table.Dword32ToBase85 = Dword32ToBase85

module_table.PrintableCharToInteger6 = PrintableCharToInteger6
module_table.HexToNumber = HexToNumber
module_table.Base85ToNumber = Base85ToNumber

module_table.Dword32ToFloat = Dword32ToFloat

return module_table
end,

["uais_globals_a_1_0"] = function()
--------------------
-- Module: 'uais_globals_a_1_0'
--------------------

module_table = {}

-- Handshake
local hs_call_attempts = 5
local hs_call_delay = 3000
local hs_failed_warning_delay = 7500
local hs_failed_warning_messages = {
	"SERVER NOTICE: ",
	"This server uses the Universal AI synchronization mod by IceCrow14",
	"You must have installed a VALID version of Chimera (w/Lua support)",
	"and the client-side scripts in the right location.",
	"For more information look up any of these sites:",
	"A) IceCrow14's YouTube channel",
	"B) OpenCarnage forums post",
	"C) Shadow Mods Discord server"
}

-- RCON
local rc_password = "@uais"
local rc_handshake_message = "@uais_join"
local rc_default_updates_per_tick = 8

-- Misc.
local client_template = { -- NOTE: This just as a reference, not actually used for anything...
	connected = false,
	calls_left = hs_call_attempts,
	rcon_updates_per_tick = rc_default_updates_per_tick,
	bipds = {},
	bipds_last_update_tick = {},
	bipds_requesting_update = {}, -- I'll stick with the basics for now
	bipds_last_x = {},
	bipds_last_y = {},
	bipds_last_z = {},
	bipds_last_pitch = {},
	bipds_last_yaw = {}
}

-- Module setup
module_table.hs_call_attempts = hs_call_attempts
module_table.hs_call_delay = hs_call_delay
module_table.hs_failed_warning_delay = hs_failed_warning_delay
module_table.hs_failed_warning_messages = hs_failed_warning_messages

module_table.rc_password = rc_password
module_table.rc_handshake_message = rc_handshake_message
module_table.rc_default_updates_per_tick = rc_default_updates_per_tick

return module_table
end,

----------------------
-- Modules part end --
----------------------
        }
        if files[path] then
            return files[path]
        else
            return origin_seacher(path)
        end
    end
end
---------------------------------------------------------
---------------- Auto Bundled Code Block ----------------
---------------------------------------------------------

-- V.1.4 BETA paradigm. By IceCrow14

-- "Pending"

-- This sucks... For safety, avoid using Base 85 conversion functions from the client to the server

clua_version = 2.042

set_callback("map load", "OnGameStart")
set_callback("rcon message", "OnRcon")

tag_collection_module = require("uais_shared_tag_collection_a_1_0")
tag_manipulation_module = require("uais_shared_tag_manipulation_a_1_0")
object_table_module = require("uais_shared_object_table_a_1_0")
data_compression_module = require("uais_shared_data_compression_a_1_0")
globals_module = require("uais_globals_a_1_0")

bipeds = {} -- NOTE: Must reset after each OnGameStart callback

weapons = {} -- Testing

function OnGameStart()

	-- Pending: Protected map check

	bipeds = {}

	weapons = {} -- Testing

	if server_type == "dedicated" then
		tag_collection_module.LoadTagTables(2)
		tag_manipulation_module.TagManipulationClientSide(2, tag_collection_module.scnr_tag_data(), tag_collection_module.bipd_tag_paths(), tag_collection_module.vehi_tag_paths())
		data_compression_module.LoadCharValuesTable()
	end

end

function OnRcon(Message)
	if string.len(Message) >= 3 then
		local hash_char = string.sub(Message, 1, 1)
		local object_char = string.sub(Message, 2, 2)
		local action_char = string.sub(Message, 3, 3)
		if hash_char == "@" then -- Main RCON handle
			if object_char == "b" then
				if action_char == "d" then -- Static format
					DeleteBiped(Message)
				elseif action_char == "c" then -- Static
					CreateBiped(Message)
				elseif action_char == "k" then -- Static
					KillBiped(Message)
				elseif action_char == "u" then -- Dynamic
					-- Pending: "u"
					UpdateBiped(Message)
				end
				console_out(action_char)
				return false
			else
				if Message == globals_module.rc_handshake_message then
					AnswerHandshake()
				end
			end
		end
	end
end

-- Additional functions:

-- Migrated from the Handshake module
function AnswerHandshake()
	execute_script("rcon "..globals_module.rc_password.." "..globals_module.rc_handshake_message)
end

-- Local
function CreateBiped(Message)
	local packet_object_index = string.sub(Message, 4, 7)
	local packet_x = string.sub(Message, 12, 16)
	local packet_y = string.sub(Message, 17, 21)
	local packet_z = string.sub(Message, 22, 26)
	local packet_pitch = string.sub(Message, 27, 31)
	local packet_yaw = string.sub(Message, 32, 36)
	local packet = "@bc"..packet_object_index

	local object_index = data_compression_module.HexToNumber( packet_object_index )
	local tag_index = data_compression_module.HexToNumber( string.sub(Message, 8, 11) )

	local weapon_tag_index = data_compression_module.HexToNumber( string.sub(Message, 37, 40) ) -- NOTE: New, testing

	local x = data_compression_module.Dword32ToFloat( data_compression_module.Base85ToNumber( packet_x ) )
	local y = data_compression_module.Dword32ToFloat( data_compression_module.Base85ToNumber( packet_y ) )
	local z = data_compression_module.Dword32ToFloat( data_compression_module.Base85ToNumber( packet_z ) )
	local pitch = data_compression_module.Dword32ToFloat( data_compression_module.Base85ToNumber( packet_pitch ) )
	local yaw = data_compression_module.Dword32ToFloat( data_compression_module.Base85ToNumber( packet_yaw ) )

	if not bipeds[object_index] then

		object_table_module.HideAutoGeneratedBipeds(bipeds) -- NOTE: Test if always works, or if should be placed after

		bipeds[object_index] = spawn_object("bipd", tag_collection_module.bipd_tag_paths()[tag_index], x, y, z)
		local object_id = bipeds[object_index]
		local object_address = get_object(object_id)
		write_bit(object_address + 0x106, 11, 1) -- Make invincible, rotate as indicated and answer with new RCON packet
		write_float(object_address + 0x74, pitch)
		write_float(object_address + 0x78, yaw)

		if weapon_tag_index ~= 0 then

			local weapon_tag_path = tag_collection_module.weap_tag_paths()[weapon_tag_index]
			if weapon_tag_path then -- Truly necessary?

				weapons[object_index] = spawn_object("weap", weapon_tag_path, x, y, z)

				local weapon = weapons[object_index]
				local weapon_object_address = get_object(weapon)
				if weapon_object_address then -- Just for caution
					write_dword(object_address + 0x2F8, weapon) -- Set weapon as primary
					-- write_word(object_address + 0x2F2, 0) -- Set weapon slot to primary
					write_bit(weapon_object_address + 0x1F4, 0, 1) -- Set as in inventory
				end

				-- Set coords to 0? Biped origin?
				
			end

			-- console_out("")

		end

	end
	execute_script("rcon "..globals_module.rc_password.." "..packet)
end

function DeleteBiped(Message)
	local packet_object_index = string.sub(Message, 4, 7)
	local packet = "@bd"..packet_object_index
	local object_index = data_compression_module.HexToNumber( packet_object_index )
	local biped = bipeds[object_index]
	if biped then
		local object_address = get_object(biped)
		if object_address then

			-- Pending: Delete weapon, if any. Needs testing
			local weapon = weapons[object_index]
			if weapon then
				local weapon_object_address = get_object(weapon)
				if weapon_object_address then
					delete_object(weapon)
				end
			end

			delete_object(biped)
		end
	end
	execute_script("rcon "..globals_module.rc_password.." "..packet)
end

function KillBiped(Message)
	local packet_object_index = string.sub(Message, 4, 7)
	local packet = "@bk"..packet_object_index
	local object_index = data_compression_module.HexToNumber( packet_object_index )
	local biped = bipeds[object_index]
	if biped then
		local object_address = get_object(biped)
		if object_address then

			-- Pending: Delete weapon, if any. Needs testing
			local weapon = weapons[object_index]
			if weapon then
				local weapon_object_address = get_object(weapon)
				if weapon_object_address then
					delete_object(weapon)
				end
			end

			write_float(object_address + 0xE0, 0) -- Health = 0
			write_bit(object_address + 0x106, 11, 0) -- Invincible = false
			write_bit(object_address + 0x106, 2, 1) -- Health empty = true
			-- write_bit(object_address + 0x106, 4, 1) -- NOTE: Possible "shield down" bit? = true

		end
	end
	execute_script("rcon "..globals_module.rc_password.." "..packet)
end

-- LAST DAMN FUNCTION

--[[function UpdateBiped(Message)
	local packet_object_index = string.sub(Message, 4, 7)
	local packet_update_request_bitmask = string.sub(Message, 8, 8)

	local packet_x
	local packet_y
	local packet_z
	local packet_pitch
	local packet_yaw

	local object_index = data_compression_module.HexToNumber( packet_object_index )
	local update_request_bitmask = data_compression_module.PrintableCharToInteger6( packet_update_request_bitmask, true )

	if update_request_bitmask[1] == 1 then
		-- Position data included
		packet_x = string.sub(Message, 9, 13)
		packet_y = string.sub(Message, 14, 18)
		packet_z = string.sub(Message, 19, 23) -- PENDING: Write (as DWORDS) to memory. Done?

		if update_request_bitmask[2] == 1 then
			-- Rotation data included
			packet_pitch = string.sub(Message, 24, 28)
			packet_yaw = string.sub(Message, 29, 33)
		end

	else

		if update_request_bitmask[2] == 1 then
			-- Rotation data included
			packet_pitch = string.sub(Message, 9, 13)
			packet_yaw = string.sub(Message, 14, 18)
		end
	end

	local biped = bipeds[object_index]
	if biped then
		local object_address = get_object(biped)
		if object_address then

			local dword_x
			local dword_y
			local dword_z
			local dword_pitch
			local dword_yaw

			if packet_x then
				dword_x = data_compression_module.Base85ToNumber( packet_x )
				write_dword(object_address + 0x5C, dword_x)
			end
			if packet_y then
				dword_y = data_compression_module.Base85ToNumber( packet_y )
				write_dword(object_address + 0x60, dword_y)
			end
			if packet_z then
				dword_z = data_compression_module.Base85ToNumber( packet_z )
				write_dword(object_address + 0x64, dword_z)
			end
			if packet_pitch then
				dword_pitch = data_compression_module.Base85ToNumber( packet_pitch )
				write_dword(object_address + 0x74, dword_pitch)
			end
			if packet_yaw then
				dword_yaw = data_compression_module.Base85ToNumber( packet_yaw )
				write_dword(object_address + 0x78, dword_yaw)
			end

		end
	end

	-- Finish, lookup server-side script.

end]]

function UpdateBiped(Message)
	local packet_object_index = string.sub(Message, 4, 7)
	local packet_update_request_bitmask = string.sub(Message, 8, 8)

	local packet_x -- REMINDER: Write floats as DWORDS
	local packet_y
	local packet_z
	local packet_pitch
	local packet_yaw
	local packet_animation

	local object_index = data_compression_module.HexToNumber( packet_object_index )
	local update_request_bitmask = data_compression_module.PrintableCharToInteger6( packet_update_request_bitmask, true )

	if update_request_bitmask[1] == 1 then
		packet_x = string.sub(Message, 9, 13)
		packet_y = string.sub(Message, 14, 18)
		packet_z = string.sub(Message, 19, 23)
		if update_request_bitmask[2] == 1 then
			packet_pitch = string.sub(Message, 24, 28)
			packet_yaw = string.sub(Message, 29, 33)
			if update_request_bitmask[3] == 1 then
				packet_animation = string.sub(Message, 34, 37)
			end
		else
			if update_request_bitmask[3] == 1 then
				packet_animation = string.sub(Message, 24, 27)
			end
		end
	else
		if update_request_bitmask[2] == 1 then
			packet_pitch = string.sub(Message, 9, 13)
			packet_yaw = string.sub(Message, 14, 18)
			if update_request_bitmask[3] == 1 then
				packet_animation = string.sub(Message, 19, 22)
			end
		else
			if update_request_bitmask[3] == 1 then
				packet_animation = string.sub(Message, 9, 12)
			end
		end
	end

	local biped = bipeds[object_index]
	if biped then
		local object_address = get_object(biped)
		if object_address then

			local dword_x
			local dword_y
			local dword_z
			local dword_pitch
			local dword_yaw

			local word_animation

			if packet_x then
				dword_x = data_compression_module.Base85ToNumber( packet_x )
				write_dword(object_address + 0x5C, dword_x)
			end
			if packet_y then
				dword_y = data_compression_module.Base85ToNumber( packet_y )
				write_dword(object_address + 0x60, dword_y)
			end
			if packet_z then
				dword_z = data_compression_module.Base85ToNumber( packet_z )
				write_dword(object_address + 0x64, dword_z)
			end
			if packet_pitch then
				dword_pitch = data_compression_module.Base85ToNumber( packet_pitch )
				write_dword(object_address + 0x74, dword_pitch)
			end
			if packet_yaw then
				dword_yaw = data_compression_module.Base85ToNumber( packet_yaw )
				write_dword(object_address + 0x78, dword_yaw)
			end
			if packet_animation then
				word_animation = data_compression_module.HexToNumber( packet_animation )
				write_word(object_address + 0xD2, 0) -- Current frame of the base animation
				write_word(object_address + 0xD0, word_animation) -- Base animation
			end

		end
	end

end