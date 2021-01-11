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