local utils = include("camcoder/gui/utils.lua")
local preferences = include("camcoder/format/preferences.lua")
local format = include("camcoder/format/ccr_interface.lua")

local function mk_btn(window, text, dock, onclick)
	local btn = window:Add("DButton")
	btn:SetText(text)
	utils.style_button(btn)
	btn:Dock(dock)
	function btn:DoClick()
		onclick()
	end
	return btn
end

local function rm(icon, window, main_menu_cb)
	window:ShowCloseButton(false)
	window:SetTitle("Camcoder - Records manager")
	local oldw, oldh = window:GetSize()
	local oldx, oldy = window:GetPos()
	local cc_tomenu = mk_btn(window, "Back to main menu", BOTTOM, function()
		window:SetSize(oldw, oldh)
		window:SetPos(oldx, oldy)
		utils.clear_window(window)
		main_menu_cb(icon, window)
	end)
	window:SetSize(ScrW()/2, ScrH()/2)
	window:SetPos(ScrW()/4, ScrH()/4)

	local cc_label = window:Add("DLabel")
	cc_label:SetText("Records manager")
	cc_label:SetFont("Trebuchet18")
	cc_label:Dock(TOP)

	local cc_fileselect = window:Add("DListView")
	cc_fileselect:SetSize(window:GetWide()/3, window:GetTall())
	cc_fileselect:Dock(LEFT)
	cc_fileselect:SetMultiSelect(false)
	cc_fileselect:AddColumn("Filename")
	cc_fileselect:AddLine("fetching...")
	format.ListRecords(function(list)
		cc_fileselect:RemoveLine(1)
		for _,file in pairs(list) do
			cc_fileselect:AddLine(file)
		end
	end)
end

return {menu=rm}