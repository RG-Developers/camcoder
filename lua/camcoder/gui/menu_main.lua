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
	local cc_recmenu = window:Add("DButton")
	cc_recmenu:SetText("Camera record menu")
	utils.style_button(cc_recmenu)
	function cc_recmenu:DoClick()
		utils.clear_window(window)
		include("camcoder/gui/menu_camera.lua").menu(icon, window, menu)
	end
	local cc_repmenu = window:Add("DButton")
	cc_repmenu:SetText("Replay menu")
	utils.style_button(cc_repmenu)
	function cc_repmenu:DoClick()
		utils.clear_window(window)
		include("camcoder/gui/menu_play.lua").menu(icon, window, menu)
	end
	local cc_dlmenu = window:Add("DButton")
	cc_dlmenu:SetText("Transfer menu")
	utils.style_button(cc_dlmenu)
	function cc_dlmenu:DoClick()
		utils.clear_window(window)
		include("camcoder/gui/menu_transfer.lua").menu(icon, window, menu)
	end
	local cc_mgrmenu = window:Add("DButton")
	cc_mgrmenu:SetText("Manager menu")
	utils.style_button(cc_mgrmenu)
	function cc_mgrmenu:DoClick()
		utils.clear_window(window)
		include("camcoder/gui/menu_manager.lua").menu(icon, window, menu)
	end
	local cc_prefmenu = window:Add("DButton")
	cc_prefmenu:SetText("Preferences")
	utils.style_button(cc_prefmenu)
	function cc_prefmenu:DoClick()
		utils.clear_window(window)
		include("camcoder/gui/menu_preferences.lua").menu(icon, window, menu)
	end
end

return {main_menu=menu}