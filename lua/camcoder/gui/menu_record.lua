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
	local cc_tomenu = mk_btn(window, "Back to main menu", BOTTOM, function()
		utils.clear_window(window)
		main_menu_cb(icon, window)
	end)

	local cc_label = window:Add("DLabel")
	cc_label:SetText("Ready...")
	cc_label:SetFont("Trebuchet24")
	cc_label:Dock(TOP)

	local cc_togglerec, recstart, recording
	local function start_recording()
		cc_label:SetText("Requesting record start...")
		format.StartRecord(function()
			recording = true
			cc_label:SetText("Recording...")
			cc_togglerec:SetText("Stop recording")
			cc_togglerec:SetEnabled(true)
			recstart = CurTime()
			function cc_label:Think()
				cc_label:SetText("Recording "..utils.FormattedTime(CurTime()-recstart).."...")
			end
		end, function(d)
			cc_label:SetText("Failed to start recording: "..d[2])
			PrintTable(d)
			cc_togglerec:SetText("Start recording")
			cc_togglerec:SetEnabled(true)
		end)
		cc_togglerec:SetText("...")
		cc_togglerec:SetEnabled(false)
	end
	local function stop_recording()
		function cc_label:Think() end
		format.Stop(function()
			recording = false
			cc_label:SetText("Done recording! "..utils.FormattedTime(CurTime()-recstart))
			cc_togglerec:SetText("Start recording")
			cc_togglerec:SetEnabled(true)
		end, function(d)
			cc_label:SetText("Failed to stop recording: "..d[2])
			PrintTable(d)
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
end

return {menu=rm}