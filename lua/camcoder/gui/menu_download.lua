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

local function pm(icon, window, main_menu_cb)
	window:ShowCloseButton(false)
	window:SetTitle("Camcoder - Download menu")

	if LocalPlayer():IsListenServerHost() then
		LocalPlayer():ChatPrint("You do not need this tab! It's only used to download records from you.")
		return main_menu_cb(icon, window)
	end
	if not preferences.fetchrecords then
		LocalPlayer():ChatPrint("Records fetching disabled by server host.")
		return main_menu_cb(icon, window)
	end

	local cc_tomenu = mk_btn(window, "Back to main menu", BOTTOM, function()
		utils.clear_window(window)
		main_menu_cb(icon, window)
	end)

	local cc_label_select = window:Add("DLabel")
	cc_label_select:SetText("Available")
	cc_label_select:SetFont("Trebuchet18")
	cc_label_select:Dock(TOP)
	local cc_fileselect = window:Add("DListView")
	cc_fileselect:SetSize(window:GetWide(), ScrH()/8)
	cc_fileselect:Dock(TOP)
	cc_fileselect:SetMultiSelect(false)
	cc_fileselect:AddColumn("Filename")
	cc_fileselect:AddLine("fetching...")
	format.ListRecords(function(list)
		cc_fileselect:RemoveLine(1)
		for _,file in pairs(list) do
			cc_fileselect:AddLine(file)
		end
	end)
	function cc_fileselect:OnRowSelected(index, pnl)
		local rname = pnl:GetColumnText(1)
		if rname == "fetching..." then return end
		format.Fetch(rname, function()
			notification.AddLegacy(rname.." successfully downloaded!", NOTIFY_GENERIC, 2)
		end)
	end
end

return {menu=pm}