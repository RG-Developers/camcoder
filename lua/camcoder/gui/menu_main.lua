local utils = include("camcoder/gui/utils.lua")

local function menu(icon, window)
	window:ShowCloseButton(true)
	window:SetTitle("Camcoder - Main menu")
	local cc_recmenu = window:Add("DButton")
	cc_recmenu:SetText("Record menu")
	utils.style_button(cc_recmenu)
	function cc_recmenu:DoClick()
		utils.clear_window(window)
		include("camcoder/gui/menu_record.lua").menu(icon, window, menu)
	end
	local cc_repmenu = window:Add("DButton")
	cc_repmenu:SetText("Replay menu")
	utils.style_button(cc_repmenu)
	function cc_repmenu:DoClick()
		utils.clear_window(window)
		include("camcoder/gui/menu_play.lua").menu(icon, window, menu)
	end
end

return {main_menu=menu}