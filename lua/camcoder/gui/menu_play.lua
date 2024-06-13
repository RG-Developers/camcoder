local utils = include("camcoder/gui/utils.lua")
local format = include("camcoder/format/ccr_0000.lua")

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
	if not LocalPlayer():IsListenServerHost() then
		LocalPlayer():ChatPrint("CamCoder player GUI is not available to non-server-hosts!")
		return main_menu_cb(icon, window)
	end
	window:ShowCloseButton(false)
	local selected = {}
	local cc_tomenu = mk_btn(window, "Back to main menu", BOTTOM, function()
		for _,v in pairs(selected) do v() end
		utils.clear_window(window)
		main_menu_cb(icon, window)
	end)

	local cc_label = window:Add("DLabel")
	cc_label:SetText("Ready...")
	cc_label:SetFont("Trebuchet18")
	cc_label:Dock(TOP)

	local cc_fileselect, cc_fileselected

	local cc_togglerep, replaying
	local function start_replaying()
		cc_label:SetText("Requesting replay start...")
		cc_togglerep:SetText("...")
		cc_togglerep:SetEnabled(false)
		local fns = {}
		for k,_ in pairs(selected) do fns[#fns+1] = k end
		format.Play(fns, function()
			for _,v in pairs(selected) do v() end
			replaying = true
			cc_label:SetText("Replaying...")
			cc_togglerep:SetText("Stop replaying")
			cc_togglerep:SetEnabled(true)
		end, function(d)
			PrintTable(d)
			cc_label:SetText("Failed to start replay: "..d[2])
			cc_togglerep:SetText("Stop replaying")
			cc_togglerep:SetEnabled(true)
		end)
	end
	local function stop_replaying()
		cc_label:SetText("Requesting replay stop...")
		cc_togglerep:SetText("...")
		cc_togglerep:SetEnabled(false)
		
		format.Stop(function()
			for k,_ in pairs(selected) do selected[k] = format.FromRAW(file.Read("camcoder/"..k, "DATA")):PlayPreview() end
			replaying = false
			cc_label:SetText("Done replaying!")
			cc_togglerep:SetText("Start replaying")
			cc_togglerep:SetEnabled(true)
		end, function(d)
			PrintTable(d)
			cc_label:SetText("Failed to stop playing: "..d[2])
			timer.Simple(1, function()
				cc_label:SetText("Replaying...")
			end)
			cc_togglerep:SetText("Stop replaying")
			cc_togglerep:SetEnabled(true)
		end)
	end
	cc_togglerep = mk_btn(window, "Start replaying", TOP, function()
		if replaying then return stop_replaying() end
		start_replaying()
	end)

	local cc_label_select = window:Add("DLabel")
	cc_label_select:SetText("Available")
	cc_label_select:SetFont("Trebuchet18")
	cc_label_select:Dock(TOP)
	local cc_fileselect = window:Add("DListView")
	cc_fileselect:SetSize(window:GetWide(), ScrH()/4)
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
	local cc_label_selected = window:Add("DLabel")
	cc_label_selected:SetText("Selected")
	cc_label_selected:SetFont("Trebuchet18")
	cc_label_selected:Dock(TOP)
	local cc_fileselected = window:Add("DListView")
	cc_fileselected:SetSize(window:GetWide(), ScrH()/4)
	cc_fileselected:Dock(TOP)
	cc_fileselected:SetMultiSelect(false)
	cc_fileselected:AddColumn("Filename")

	function cc_fileselect:OnRowSelected(index, pnl)
		local rname = pnl:GetColumnText(1)
		if rname == "fetching..." then return end
		cc_fileselected:AddLine(rname)
		cc_fileselect:RemoveLine(index)
		format.Fetch(rname, function()
			selected[rname] = format.FromRAW(file.Read("camcoder/"..rname, "DATA")):PlayPreview()
		end)
	end
	function cc_fileselected:OnRowSelected(index, pnl)
		local rname = pnl:GetColumnText(1)
		cc_fileselect:AddLine(rname)
		cc_fileselected:RemoveLine(index)
		selected[rname]()
		selected[rname] = nil
	end
end

return {menu=rm}