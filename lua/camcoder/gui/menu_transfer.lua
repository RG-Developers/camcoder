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
	window:SetTitle("Camcoder - Transfer menu")

	if LocalPlayer():IsListenServerHost() and false then
		LocalPlayer():ChatPrint("You do not need this tab! It's only used to transfer records from and to you.")
		return main_menu_cb(icon, window)
	end
	if not preferences.fetchrecords and not preferences.pushrecords then
		LocalPlayer():ChatPrint("Records fetching and pushing disabled by server host.")
		return main_menu_cb(icon, window)
	end
	if not preferences.fetchrecords  then
		LocalPlayer():ChatPrint("Records fetching disabled by server host.")
	end
	if not preferences.pushrecords  then
		LocalPlayer():ChatPrint("Records pushing disabled by server host.")
	end

	local cc_tomenu = mk_btn(window, "Back to main menu", BOTTOM, function()
		utils.clear_window(window)
		main_menu_cb(icon, window)
	end)

	local cc_label_select_r = window:Add("DLabel")
	cc_label_select_r:SetText("Remote")
	cc_label_select_r:SetFont("Trebuchet18")
	cc_label_select_r:Dock(TOP)
	local cc_remoteselect = window:Add("DListView")
	cc_remoteselect:SetSize(window:GetWide(), ScrH()/8)
	cc_remoteselect:Dock(TOP)
	cc_remoteselect:SetMultiSelect(false)
	cc_remoteselect:AddColumn("Filename")
	local cc_label_select_l = window:Add("DLabel")
	cc_label_select_l:SetText("Local")
	cc_label_select_l:SetFont("Trebuchet18")
	cc_label_select_l:Dock(TOP)
	local cc_localselect = window:Add("DListView")
	cc_localselect:SetSize(window:GetWide(), ScrH()/8)
	cc_localselect:Dock(TOP)
	cc_localselect:SetMultiSelect(false)
	cc_localselect:AddColumn("Filename")
	local function rebuild_remote()
		for k, line in pairs(cc_remoteselect:GetLines()) do
		    cc_remoteselect:RemoveLine(line:GetID())
		end
		cc_remoteselect:AddLine("fetching...")
		format.ListRecords(function(list)
			cc_remoteselect:RemoveLine(1)
			for _,file in pairs(list) do
				cc_remoteselect:AddLine(file)
			end
		end)
	end
	local function rebuild_local()
		for k, line in pairs(cc_localselect:GetLines()) do
		    cc_localselect:RemoveLine(line:GetID())
		end
		local list,_ = file.Find("camcoder/recordings/*", "DATA")
		for _,file in pairs(list) do
			cc_localselect:AddLine(file)
		end
	end
	function cc_remoteselect:OnRowSelected(index, pnl)
		if not preferences.fetchrecords  then
			LocalPlayer():ChatPrint("Records fetching disabled by server host.")
		end
		local rname = pnl:GetColumnText(1)
		if rname == "fetching..." then return end
		format.Fetch(rname, function()
			rebuild_local()
			notification.AddLegacy(rname.." successfully downloaded!", NOTIFY_GENERIC, 2)
		end)
	end
	function cc_localselect:OnRowSelected(index, pnl)
		if not preferences.pushrecords  then
			LocalPlayer():ChatPrint("Records pushing disabled by server host.")
		end
		local rname = pnl:GetColumnText(1)
		format.Push(rname, function()
			rebuild_remote()
			notification.AddLegacy(rname.." successfully uploaded!", NOTIFY_GENERIC, 2)
		end)
	end

	rebuild_remote()
	rebuild_local()
end

return {menu=pm}