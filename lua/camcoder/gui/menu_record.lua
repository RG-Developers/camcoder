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

local function record_save(icon, window, ftime, sv_cb, bk_cb)
	local cc_label = window:Add("DLabel")
	cc_label:SetText("Saving scene. Recorded time: "..ftime)
	cc_label:SetFont("Trebuchet18")
	cc_label:Dock(TOP)

	local browser = window:Add("DFileBrowser")
	browser:Dock(FILL)

	browser:SetPath("DATA")
	browser:SetBaseFolder("camcoder")
	browser:SetOpen(true)
	browser:SetCurrentFolder("")

	function browser:OnSelect(path, pnl)
		--print(path)
	end

	local cc_backbtn = window:Add("DButton")
	cc_backbtn:SetText("Don't save")
	utils.style_button(cc_backbtn)
	cc_backbtn:Dock(BOTTOM)
	function cc_backbtn:DoClick()
		utils.clear_window(window)
		bk_cb()
	end

	local cc_savebtn = window:Add("DButton")
	cc_savebtn:SetText("Save")
	utils.style_button(cc_savebtn)
	cc_savebtn:Dock(BOTTOM)

	local filename = window:Add("DTextEntry")
	filename:Dock(BOTTOM)
	filename:DockMargin(5, 5, 5, 5)

	function cc_savebtn:DoClick()
		utils.clear_window(window)
		sv_cb(filename:GetValue())
	end
end

local function rm(icon, window, main_menu_cb)
	if not LocalPlayer():IsListenServerHost() and not preferences.othersrecord then
		LocalPlayer():ChatPrint("Server host disabled ability for others to record.")
		return main_menu_cb(icon, window)
	end
	window:ShowCloseButton(false)
	window:SetTitle("Camcoder - Record menu")
	local selected = {}
	local cc_tomenu = mk_btn(window, "Back to main menu", BOTTOM, function()
		for _,v in pairs(selected) do v() end
		utils.clear_window(window)
		main_menu_cb(icon, window)
	end)

	local cc_label = window:Add("DLabel")
	cc_label:SetText("Ready...")
	cc_label:SetFont("Trebuchet24")
	cc_label:Dock(TOP)

	local cc_togglerec, recstart, recend, recording
	local function start_recording()
		cc_label:SetText("Requesting record start...")
		format.StartRecord(function()
			for k,v in pairs(selected) do
				v()
				selected[k] = format.FromRAW(file.Read("camcoder/"..k, "DATA")):PlayPreview(true)
			end
			recording = true
			cc_label:SetText("Recording...")
			cc_togglerec:SetText("Stop recording")
			cc_togglerec:SetEnabled(true)
			recstart = CurTime()
			function cc_label:Think()
				cc_label:SetText("Recording "..utils.FormattedTime(CurTime()-recstart).."...")
			end
		end, function(d)
			PrintTable(d)
			cc_label:SetText("Failed to start recording: "..d[2])
			cc_togglerec:SetText("Start recording")
			cc_togglerec:SetEnabled(true)
		end)
		cc_togglerec:SetText("...")
		cc_togglerec:SetEnabled(false)
	end
	local function stop_recording()
		function cc_label:Think() end
		format.StopRecord(function()
			for k,v in pairs(selected) do
				v()
				selected[k] = format.FromRAW(file.Read("camcoder/"..k, "DATA")):PlayPreview(true)
			end
			recording = false
			recend = CurTime()
			cc_label:SetText("Done recording! "..utils.FormattedTime(recend-recstart))
			cc_togglerec:SetText("Start recording")
			cc_togglerec:SetEnabled(true)
		end, function(d)
			PrintTable(d)
			cc_label:SetText("Failed to stop recording: "..d[2])
			timer.Simple(1, function()
				function cc_label:Think()
					cc_label:SetText("Recording "..utils.FormattedTime(CurTime()-recstart).."...")
				end
			end)
			cc_togglerec:SetText("Stop recording")
			cc_togglerec:SetEnabled(true)
		end)
		cc_togglerec:SetText("...")
		cc_togglerec:SetEnabled(false)
	end
	cc_togglerec = mk_btn(window, "Start recording", TOP, function()
		if recording then return stop_recording() end
		start_recording()
	end)

	cc_save = mk_btn(window, "Save recording", TOP, function()
		if not recend or not recstart then return end
		utils.clear_window(window)
		record_save(icon, window, utils.FormattedTime(recend-recstart), function(fname)
			local cc_label = rm(icon, window, main_menu_cb)
			cc_label:SetText("Saving...")
			format.Save(fname, function(fnames)
				cc_label:SetText("Saved recording as "..fnames[2])
				cc_label:GetParent().cc_fileselect:AddLine(fnames[2])
			end, function(d)
				PrintTable(d)
				cc_label:SetText("Not saved: "..d[2])
			end)
		end, function()
			local cc_label = rm(icon, window, main_menu_cb)
			cc_label:SetText("Save aborted")
		end)
	end)

	local cc_label_select = window:Add("DLabel")
	cc_label_select:SetText("Available")
	cc_label_select:SetFont("Trebuchet18")
	cc_label_select:Dock(TOP)
	local cc_fileselect = window:Add("DListView")
	cc_fileselect:SetSize(window:GetWide(), ScrH()/9)
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
	window.cc_fileselect = cc_fileselect
	local cc_label_selected = window:Add("DLabel")
	cc_label_selected:SetText("Selected")
	cc_label_selected:SetFont("Trebuchet18")
	cc_label_selected:Dock(TOP)
	local cc_fileselected = window:Add("DListView")
	cc_fileselected:SetSize(window:GetWide(), ScrH()/9)
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

	return cc_label
end

return {menu=rm}