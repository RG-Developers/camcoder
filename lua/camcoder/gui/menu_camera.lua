local utils = include("camcoder/gui/utils.lua")
local preferences = include("camcoder/format/preferences.lua")
local format = include("camcoder/format/ccr_camera.lua")

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
	cc_label:SetText("Saving camera path. Recorded time: "..ftime)
	cc_label:SetFont("Trebuchet18")
	cc_label:Dock(TOP)

	local browser = window:Add("DFileBrowser")
	browser:Dock(FILL)

	browser:SetPath("DATA")
	browser:SetBaseFolder("camcoder/camerarecs")
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
	if not LocalPlayer():IsSuperAdmin() and not preferences.othersrecordcamera then
		LocalPlayer():ChatPrint("Server host disabled ability for others to record camera.")
		return main_menu_cb(icon, window)
	end

	window:ShowCloseButton(false)
	window:SetTitle("Camcoder - Camera record menu")
	local selected = {}
	local cc_tomenu = mk_btn(window, "Back to main menu", BOTTOM, function()
		for _,v in pairs(selected) do v() end
		hook.Remove("HUDPaint", "CamCoder_Recorder_HUD")
		utils.clear_window(window)
		main_menu_cb(icon, window)
	end)

	local cc_label = window:Add("DLabel")
	cc_label:SetText("Ready...")
	cc_label:SetFont("Trebuchet24")
	cc_label:Dock(TOP)

	local cc_togglerec, cc_save, recstart, recend, recording, cc_voicepath
	local function start_recording()
		cc_tomenu:SetEnabled(false)
		cc_save:SetEnabled(false)
		cc_label:SetText("Requesting camera record start...")
		format.StartRecord(function()
			for k,v in pairs(selected) do
				v()
				selected[k] = format.ReadFromFile(k):PlayPreview(true)
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
			print("[CAMCODER] "..d[2])
			cc_label:SetText("Failed to start recording: "..d[2])
			cc_togglerec:SetText("Start recording")
			cc_togglerec:SetEnabled(true)
			cc_tomenu:SetEnabled(true)
			cc_save:SetEnabled(true)
		end)
		cc_togglerec:SetText("...")
		cc_togglerec:SetEnabled(false)
	end
	local function stop_recording()
		function cc_label:Think() end
		format.StopRecord(function()
			for k,v in pairs(selected) do
				v()
				selected[k] = format.ReadFromFile(k):PlayPreview()
			end
			recording = false
			recend = CurTime()
			cc_label:SetText("Done recording! "..utils.FormattedTime(recend-recstart))
			cc_togglerec:SetText("Start recording")
			cc_togglerec:SetEnabled(true)
			cc_tomenu:SetEnabled(true)
			cc_save:SetEnabled(true)
		end, function(d)
			print("[CAMCODER] "..d[2])
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
		for _,v in pairs(selected) do v() end
		hook.Remove("HUDPaint", "CamCoder_Recorder_HUD")
		utils.clear_window(window)
		record_save(icon, window, utils.FormattedTime(recend-recstart), function(fname)
			local cc_label = rm(icon, window, main_menu_cb)
			cc_label:SetText("Saving...")
			format.Save(fname, function(fnames)
				cc_label:SetText("Saved recording as "..fnames[2])
				cc_label:GetParent().cc_fileselect:AddLine(fnames[2])
			end, function(d)
				print("[CAMCODER] "..d[2])
				cc_label:SetText("Not saved: "..d[2])
			end)
		end, function()
			local cc_label = rm(icon, window, main_menu_cb)
			cc_label:SetText("Save aborted")
		end)
	end)
	cc_save:SetEnabled(false)

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
		if recording then return end
		local rname = pnl:GetColumnText(1)
		if rname == "fetching..." then return end
		cc_fileselected:AddLine(rname)
		cc_fileselect:RemoveLine(index)
		format.Fetch(rname, function()
			selected[rname] = format.ReadFromFile(rname):PlayPreview()
		end)
	end
	function cc_fileselected:OnRowSelected(index, pnl)
		if recording then return end
		local rname = pnl:GetColumnText(1)
		cc_fileselect:AddLine(rname)
		cc_fileselected:RemoveLine(index)
		selected[rname]()
		selected[rname] = nil
	end

	hook.Add("HUDPaint", "CamCoder_Recorder_HUD", function()
		local ftime = utils.FormattedTime(0)
		local col = Color(55,55,55,((math.sin(RealTime())+1)/2*127+127))
		local txt = "IDL"
		if recstart and not recend then
			ftime = utils.FormattedTime(CurTime()-recstart)
			col = Color(255,0,0,((math.sin(RealTime()*5)+1)/2*255))
			txt = "REC"
		end
		if recend then
			ftime = utils.FormattedTime(recend-recstart)
		end
		draw.RoundedBox(10, ScrW()-160, 10, 150, 50, Color(55, 55, 55, 127))
		draw.RoundedBox(10, ScrW()-160, 70, 150, 25, Color(55, 55, 55, 127))
		draw.RoundedBox(10, ScrW()-150, 20, 30, 30, col)
		draw.DrawText(txt, "camcoder_bigfont", ScrW()-110, 10, Color(255, 255, 255), TEXT_ALIGN_LEFT)
		draw.DrawText(ftime, "DermaDefault", ScrW()-85, 75, Color(255, 255, 255), TEXT_ALIGN_CENTER)
	end)

	return cc_label
end

return {menu=rm}