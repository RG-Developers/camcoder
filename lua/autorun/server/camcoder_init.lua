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
}

for k,v in pairs(cs_files) do AddCSLuaFile(v) end

include("camcoder/format/ccr_0000.lua")