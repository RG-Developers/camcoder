local cs_files = {
	"camcoder/gui/camcoder_base.lua",
	"camcoder/format/buffer.lua",
	"camcoder/format/ccr_0000.lua",
	"camcoder/format/ccr_base.lua",
	"camcoder/gui/camcoder_base.lua",
	"camcoder/gui/menu_main.lua",
	"camcoder/gui/menu_play.lua",
	"camcoder/gui/menu_record.lua",
	"camcoder/gui/utils.lua",
	"camcoder/format/ccr_interface.lua",
	"camcoder/format/preferences.lua",
	"camcoder/cui/commands.lua"
}

for k,v in pairs(cs_files) do AddCSLuaFile(v) end

_G.CAMCODER_INCLUDES = _G.CAMCODER_INCLUDES or {}

include("camcoder/format/ccr_interface.lua")