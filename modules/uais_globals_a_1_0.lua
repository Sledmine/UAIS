
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