local utils = include("camcoder/gui/utils.lua")
local preferences = include("camcoder/format/preferences.lua")
local format = include("camcoder/format/ccr_interface.lua")

local guihelps = include("camcoder/format/gui_helpers.lua")

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
	if not preferences.fetchrecords and not LocalPlayer():IsListenServerHost() then
		notification.AddLegacy("Records fetching disabled by server host. Manager not available.", NOTIFY_GENERIC, 2)
		return main_menu_cb(icon, window)
	end

	local selected = nil
	local selected_section = nil
	local selected_filename = nil

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
	window:SetSize(ScrW()/4*3, ScrH()/4*3)
	window:SetPos(ScrW()/2-window:GetWide()/2, ScrH()/2-window:GetTall()/2)

	local cc_label = window:Add("DLabel")
	cc_label:SetText("Records manager")
	cc_label:SetFont("Trebuchet18")
	cc_label:Dock(TOP)

	local cc_control = window:Add("DPanel")
	cc_control:SetSize(window:GetWide(), window:GetTall()/2)
	cc_control:Dock(BOTTOM)
	function cc_control:Paint() end

	local cc_render = window:Add("DPanel")
	cc_render:SetWide(window:GetWide())
	cc_render:Dock(FILL)

	local center = Vector(0, 0, 0)
	local curpos = Vector(0, 0, 0)
	local angles = Angle(0, 0, 0)
	local step = 100
	local zoom = 0.5

	function cc_render:Paint() end
	local cc_xy_view = cc_render:Add("DPanel")
	cc_xy_view:SetSize(cc_render:GetWide()/4, cc_render:GetTall())
	cc_xy_view:Dock(LEFT)
	function cc_xy_view:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
		local relative = center - curpos
		surface.SetDrawColor(255,255,255,25)
		for i=w/2+center.x%(step*zoom), w+center.x%(step*zoom), step*zoom do surface.DrawRect(i, 0, 1, h) end
		for i=w/2+center.x%(step*zoom), 0, -step*zoom do surface.DrawRect(i, 0, 1, h) end
		for i=h/2+center.y%(step*zoom), h+center.y%(step*zoom), step*zoom do surface.DrawRect(0, i, w, 1) end
		for i=h/2+center.y%(step*zoom), 0, -step*zoom do surface.DrawRect(0, i, w, 1) end
		local x, y = relative.x*zoom, relative.y*zoom
		draw.RoundedBox(5, w/2-5+x, h/2-5+y, 10, 10, Color(255, 255, 255))
		local fwd = Vector(1, 0, 0)
		fwd:Rotate(angles)
		local xa, ya = fwd.x*zoom*100, fwd.y*zoom*100
		surface.SetDrawColor(255,255,255,255)
		surface.DrawLine(w/2+x, h/2+y, w/2+x+xa, h/2+y+ya)
	end
	local cc_xz_view = cc_render:Add("DPanel")
	cc_xz_view:SetSize(cc_render:GetWide()/4, cc_render:GetTall())
	cc_xz_view:Dock(LEFT)
	function cc_xz_view:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
		local relative = center - curpos
		surface.SetDrawColor(255,255,255,25)
		for i=w/2+center.x%(step*zoom), w+center.x%(step*zoom), step*zoom do surface.DrawRect(i, 0, 1, h) end
		for i=w/2+center.x%(step*zoom), 0, -step*zoom do surface.DrawRect(i, 0, 1, h) end
		for i=h/2+center.z%(step*zoom), h+center.z%(step*zoom), step*zoom do surface.DrawRect(0, i, w, 1) end
		for i=h/2+center.z%(step*zoom), 0, -step*zoom do surface.DrawRect(0, i, w, 1) end
		local x, y = relative.x*zoom, relative.z*zoom
		draw.RoundedBox(5, w/2-5+x, h/2-5+y, 10, 10, Color(255, 255, 255))
		local fwd = Vector(1, 0, 0)
		fwd:Rotate(angles)
		local xa, ya = fwd.x*zoom*100, fwd.z*zoom*100
		surface.SetDrawColor(255,255,255,255)
		surface.DrawLine(w/2+x, h/2+y, w/2+x+xa, h/2+y+ya)
	end
	local cc_yz_view = cc_render:Add("DPanel")
	cc_yz_view:SetSize(cc_render:GetWide()/4, cc_render:GetTall())
	cc_yz_view:Dock(LEFT)
	function cc_yz_view:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
		local relative = center - curpos
		surface.SetDrawColor(255,255,255,25)
		for i=w/2+center.y%(step*zoom), w+center.y%(step*zoom), step*zoom do surface.DrawRect(i, 0, 1, h) end
		for i=w/2+center.y%(step*zoom), 0, -step*zoom do surface.DrawRect(i, 0, 1, h) end
		for i=h/2+center.z%(step*zoom), h+center.z%(step*zoom), step*zoom do surface.DrawRect(0, i, w, 1) end
		for i=h/2+center.z%(step*zoom), 0, -step*zoom do surface.DrawRect(0, i, w, 1) end
		local x, y = relative.y*zoom, relative.z*zoom
		draw.RoundedBox(5, w/2-5+x, h/2-5+y, 10, 10, Color(255, 255, 255))
		local fwd = Vector(1, 0, 0)
		fwd:Rotate(angles)
		local xa, ya = fwd.y*zoom*100, fwd.z*zoom*100
		surface.SetDrawColor(255,255,255,255)
		surface.DrawLine(w/2+x, h/2+y, w/2+x+xa, h/2+y+ya)
	end
	local cc_zoom = cc_render:Add("DVScrollBar")
	cc_zoom:Dock(LEFT)
	cc_zoom:DockMargin(5, 0, 5, 0)
	cc_zoom:SetUp(0.1, 1000)
	cc_zoom:SetScroll(500)
	function cc_render:OnVScroll(off)
		off = math.max(0.01, math.min(1, -off / 1000))
		zoom = off
	end
	local cc_info_view = cc_render:Add("DPanel")
	cc_info_view:Dock(FILL)
	function cc_info_view:Paint() end
	local cc_info_curpos = cc_render:Add("DLabel")
	cc_info_curpos:SetText("Current position: 0.00 0.00 0.00")
	cc_info_curpos:SetFont("Trebuchet18")
	cc_info_curpos:Dock(TOP)
	local cc_info_ctrpos = cc_render:Add("DLabel")
	cc_info_ctrpos:SetText("Center position: 0.00 0.00 0.00")
	cc_info_ctrpos:SetFont("Trebuchet18")
	cc_info_ctrpos:Dock(TOP)
	local cc_info_angles = cc_render:Add("DLabel")
	cc_info_angles:SetText("Current angles: 0.00 0.00 0.00")
	cc_info_angles:SetFont("Trebuchet18")
	cc_info_angles:Dock(TOP)
	local cc_info_info = cc_render:Add("DLabel")
	cc_info_info:SetText("Each line separates 100u chunks.\nScrollbar controls zoom.\nSDT - Section DaTa\n"..
					     "We do not provide any support for\nrecordings corrupted by\nimproper editing.")
	cc_info_info:SetFont("Trebuchet18")
	cc_info_info:SizeToContents()
	cc_info_info:Dock(BOTTOM)

	local cc_fileselect = cc_control:Add("DListView")
	cc_fileselect:SetSize(window:GetWide()/4, window:GetTall())
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

	local cc_frameselect = cc_control:Add("DListView")
	cc_frameselect:SetSize(window:GetWide()/4, window:GetTall())
	cc_frameselect:Dock(RIGHT)
	cc_frameselect:SetMultiSelect(false)
	cc_frameselect:AddColumn("Section ID")
	cc_frameselect:AddColumn("Section Size")
	cc_frameselect:AddColumn("Section Data")

	local cc_dataselect = cc_control:Add("DListView")
	cc_dataselect:SetSize(window:GetWide()/4, window:GetTall())
	cc_dataselect:Dock(RIGHT)
	cc_dataselect:SetMultiSelect(false)
	cc_dataselect:AddColumn("SDT Name")
	cc_dataselect:AddColumn("SDT Value")

	local cc_dataedit = cc_control:Add("DPanel")
	cc_dataedit:SetSize(window:GetWide()/4-10, window:GetTall())
	cc_dataedit:Dock(LEFT)
	function cc_dataedit:Paint() end
	local cc_textentry_name_label = cc_dataedit:Add("DLabel")
	cc_textentry_name_label:SetText("SDT Name")
	cc_textentry_name_label:SetFont("Trebuchet18")
	cc_textentry_name_label:Dock(TOP)
	local cc_textentry_name = cc_dataedit:Add("DTextEntry")
	cc_textentry_name:Dock(TOP)
	cc_textentry_name:DockMargin(0, 5, 0, 0)
	cc_textentry_name:SetPlaceholderText("SDT Name")
	cc_textentry_name:SetEditable(false)
	local cc_textentry_type_label = cc_dataedit:Add("DLabel")
	cc_textentry_type_label:SetText("SDT Type")
	cc_textentry_type_label:SetFont("Trebuchet18")
	cc_textentry_type_label:Dock(TOP)
	local cc_textentry_type = cc_dataedit:Add("DTextEntry")
	cc_textentry_type:Dock(TOP)
	cc_textentry_type:DockMargin(0, 5, 0, 0)
	cc_textentry_type:SetPlaceholderText("SDT Type")
	cc_textentry_type:SetEditable(false)
	local cc_textentry_data_label = cc_dataedit:Add("DLabel")
	cc_textentry_data_label:SetText("SDT Value")
	cc_textentry_data_label:SetFont("Trebuchet18")
	cc_textentry_data_label:Dock(TOP)
	local cc_textentry_data = cc_dataedit:Add("DTextEntry")
	cc_textentry_data:Dock(TOP)
	cc_textentry_data:DockMargin(0, 5, 0, 0)
	cc_textentry_data:SetPlaceholderText("SDT Value")

	local selected_file_panel = nil
	local selected_frame_panel = nil
	local selected_data_panel = nil

	function cc_fileselect:OnRowSelected(index, pnl)
		local rname = pnl:GetColumnText(1)
		if rname == "fetching..." then return end
		selected_file_panel = index
		if not self.restore then
			selected_frame_panel = nil
			selected_data_panel = nil
		end
		for k, line in pairs(cc_frameselect:GetLines()) do
		    cc_frameselect:RemoveLine(line:GetID())
		end
		for k, line in pairs(cc_dataselect:GetLines()) do
		    cc_dataselect:RemoveLine(line:GetID())
		end
		cc_textentry_data:SetValue("")
		cc_textentry_name:SetEditable(true)
		cc_textentry_name:SetValue("")
		cc_textentry_name:SetEditable(false)
		cc_textentry_type:SetEditable(true)
		cc_textentry_type:SetValue("")
		cc_textentry_type:SetEditable(false)
		format.Fetch(rname, function()
			selected = format.FromRAW(file.Read("camcoder/"..rname, "DATA"))
			selected_filename = "camcoder/"..rname
			for n,section in pairs(selected.sections) do
				local id = guihelps.frameids[section.s_id] or "UNK/"..string.format("%2x", section.s_id)
				local dt = string.format("%q", section.s_dt):Replace("\n", "\\n"):sub(2, -2)
				cc_frameselect:AddLine(id, section.s_sz.." B", dt:sub(0,12)..(dt:sub(0,12) ~= dt and "..." or ""))
			end
			selected:SeekSection(1)
			local initl = selected:ReadSection()
			center = initl.data.pos
			curpos = initl.data.pos
			cc_info_curpos:SetText("Current position: "..string.format("%.2f %.2f %.2f", curpos.x, curpos.y, curpos.z))
			cc_info_ctrpos:SetText("Center position: "..string.format("%.2f %.2f %.2f", center.x, center.y, center.z))
			cc_info_angles:SetText("Current angles: "..string.format("%.2f %.2f %.2f", initl.data.angles.x, initl.data.angles.y, initl.data.angles.z))
			if self.restore then
				self.restore = nil
				cc_frameselect.restore = true
				cc_frameselect:SelectItem(cc_frameselect:GetLine(selected_frame_panel))
			end
		end)
	end
	function cc_frameselect:OnRowSelected(index, pnl)
		local frameid = index
		selected_frame_panel = index
		if not self.restore then
			selected_data_panel = nil
		end
		if self.smallupdate then
			self.smallupdate = false
			return
		else
			selected:SeekSection(2)
			for i=2,frameid-1,1 do
				local sect = selected:ReadSection()
				if sect.s_id == 0x04 then
					angles = sect.data.angles
					cc_info_angles:SetText("Current angles: "..string.format("%.2f %.2f %.2f", sect.data.angles.x, sect.data.angles.y, sect.data.angles.z))
				end
				if sect.s_id == 0x07 then
					curpos = center + sect.data.offset
					cc_info_curpos:SetText("Current position: "..string.format("%.2f %.2f %.2f", curpos.x, curpos.y, curpos.z))
				end
			end
		end
		selected:SeekSection(frameid-1)
		local section = selected:ReadSection()
		for k, line in pairs(cc_dataselect:GetLines()) do
		    cc_dataselect:RemoveLine(line:GetID())
		end
		cc_textentry_data:SetValue("")
		cc_textentry_name:SetEditable(true)
		cc_textentry_name:SetValue("")
		cc_textentry_name:SetEditable(false)
		cc_textentry_type:SetEditable(true)
		cc_textentry_type:SetValue("")
		cc_textentry_type:SetEditable(false)
		cc_dataselect:AddLine("RAW", string.format("%q", section.s_dt):Replace("\n", "\\n"):sub(2, -2))
		if not section.data then return end
		local function parse(data, prefix)
			for n,v in pairs(data) do
				if not istable(v) then
					cc_dataselect:AddLine(prefix.."."..n, string.format("%q", tostring(v)):Replace("\n", "\\n"):sub(2, -2))
				else
					parse(v, prefix.."."..n)
				end
			end
		end
		parse(section.data, "root")
		selected_section = section
		if self.restore then
			self.restore = nil
			cc_dataselect:SelectItem(cc_dataselect:GetLine(selected_data_panel))
		end
	end

	function cc_dataselect:OnRowSelected(index, pnl)
		selected_data_panel = index
		local dataid = pnl:GetColumnText(1)
		if dataid == "RAW" then
			cc_textentry_data:SetEditable(true)
			cc_textentry_data:SetValue(string.format("%q", selected_section.s_dt):Replace("\n", "\\n"):sub(2, -2))
			cc_textentry_data:SetEditable(false)
			cc_textentry_name:SetEditable(true)
			cc_textentry_name:SetValue("RAW")
			cc_textentry_name:SetEditable(false)
			cc_textentry_type:SetEditable(true)
			cc_textentry_type:SetValue("RAW")
			cc_textentry_type:SetEditable(false)
			return
		end
		cc_textentry_data:SetEditable(true)
		local data = selected_section.data
		for match in (dataid..'.'):gmatch("(.-)"..'%.') do
			if match == "root" then continue end
			tdata = data[match]
			if tdata == nil then
				tdata = data[tonumber(match)]
			end
			data = tdata
		end
		cc_textentry_data:SetValue(tostring(data))
		cc_textentry_name:SetEditable(true)
		cc_textentry_name:SetValue(dataid)
		cc_textentry_name:SetEditable(false)
		cc_textentry_type:SetEditable(true)
		cc_textentry_type:SetValue(type(data))
		cc_textentry_type:SetEditable(false)
	end

	local cc_togglereplay = cc_dataedit:Add("DButton")
	cc_togglereplay:SetText("Play/Stop")
	utils.style_button(cc_togglereplay)
	cc_togglereplay:Dock(BOTTOM)
	local replaying = false
	local hname = ""
	function cc_togglereplay:DoClick()
		if not selected then return end
		if replaying then
			replaying = false
			hook.Remove("StartCommand", hname)
			return
		end
		replaying = true
		hname = "CamCoder_Player_"..math.random(10000, 99999)
		local laststate = {startpos=center}
		local lastpause = 0
		selected_frame_panel = selected_frame_panel or 1
		hook.Add("StartCommand", hname, function(ply, cmd)
			if ply ~= LocalPlayer() then return end
			if cmd:TickCount() == 0 then return end
			if CurTime() - lastpause <= 0.01 then return end
			lastpause = CurTime()
			cc_frameselect:GetLine(selected_frame_panel):SetSelected(false)
			cc_frameselect.smallupdate = true
			cc_frameselect:SelectItem(cc_frameselect:GetLine(selected_frame_panel+1))
			cc_frameselect.VBar:SetScroll((selected_frame_panel-1)*cc_frameselect:GetDataHeight())
			if selected:TellSection() >= #selected.sections then
				replaying = false
				hook.Remove("StartCommand", hname)
				return
			end
			local sect = selected:ReadSection()
			if sect.s_id == 0x04 then
				angles = sect.data.angles
				cc_info_angles:SetText("Current angles: "..string.format("%.2f %.2f %.2f", sect.data.angles.x, sect.data.angles.y, sect.data.angles.z))
			end
			if sect.s_id == 0x07 then
				curpos = center + sect.data.offset
				cc_info_curpos:SetText("Current position: "..string.format("%.2f %.2f %.2f", curpos.x, curpos.y, curpos.z))
			end
		end)
	end

	local cc_applyedits = cc_dataedit:Add("DButton")
	cc_applyedits:SetText("Apply")
	utils.style_button(cc_applyedits)
	cc_applyedits:Dock(BOTTOM)
	function cc_applyedits:DoClick()
		if cc_textentry_name:GetValue() == "RAW" then return end
		if cc_textentry_name:GetValue() == "" then return end
		local rdata = cc_textentry_data:GetValue()
		local type = cc_textentry_type:GetValue()
		local dataid = cc_textentry_name:GetValue()

		if type == "Vector" then rdata = Vector(rdata) end
		if type == "Angle" then rdata = Angle(rdata) end
		if type == "number" then rdata = tonumber(rdata) end

		local data = selected_section.data
		local last = ""
		for match in (dataid..'.'):gmatch("(.-)"..'%.') do
			if match == "root" then continue end
			if last ~= "" then
				tdata = data[last]
				if tdata == nil then
					tdata = data[tonumber(last)]
				end
				data = tdata
			end
			last = match
		end
		if last ~= "" then
			if data[last] == nil then
				last = tonumber(last)
			end
			data[last] = rdata
		end
		selected:SeekSection(selected:TellSection()-1)
		local succ, varg = pcall(function() selected:WriteSection(selected_section.s_id, selected_section.data) end)
		if not succ then
			notification.AddLegacy("Failed to apply change: "..varg, NOTIFY_ERROR, 5)
			return
		end
		selected:UpdateData()
		file.Write(selected_filename, selected.buf.data)

		if not selected_data_panel then return end

		cc_fileselect.restore = true
		cc_fileselect:SelectItem(cc_fileselect:GetLines()[selected_file_panel])
	end
end

return {menu=rm}