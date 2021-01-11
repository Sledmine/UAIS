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