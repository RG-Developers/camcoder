local cs_files = {
	"camcoder/format/buffer.lua",
	"camcoder/format/ccr_0000.lua",
	"camcoder/format/ccr_base.lua",
	"camcoder/format/ccr_interface.lua",
	"camcoder/format/preferences.lua",
	"camcoder/format/gui_helpers.lua",

	"camcoder/gui/camcoder_base.lua",
	"camcoder/gui/menu_main.lua",
	"camcoder/gui/menu_play.lua",
	"camcoder/gui/menu_record.lua",
	"camcoder/gui/menu_transfer.lua",
	"camcoder/gui/menu_manager.lua",
	"camcoder/gui/menu_preferences.lua",
	"camcoder/gui/utils.lua",

	"camcoder/cui/commands.lua",
}

for k,v in pairs(cs_files) do AddCSLuaFile(v) end

_G.CAMCODER_INCLUDES = _G.CAMCODER_INCLUDES or {}

include("camcoder/format/ccr_interface.lua")