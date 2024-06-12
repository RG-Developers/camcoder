local base = include("camcoder/format/ccr_base.lua")
local buffer = include("camcoder/format/buffer.lua")

local ccr = {sections={}}
local ccr_file = {s_ptr=0}

--====================================================--

function ccr.FromRAW(raw)
	local f = base.file.FromRAW(raw)
	if f.sections[1].s_id ~= 0 then
		return error("Invalid sID in header: "..f.sections[1].s_id)
	end
	if f.sections[1].s_dt ~= "CCRF\0\0" then
		return error("Invalid sDT in header: "..string.format("%q", f.sections[1].s_dt))
	end
	f = table.Inherit(f, ccr_file)
	f.BaseClass = nil
	return f
end

function ccr.New()
	return ccr.FromRAW("\0\0\6CCRF\0\0")
end

--====================================================--

function ccr_file:ReadSection()
	self.s_ptr = self.s_ptr + 1
	local sec = self.sections[self.s_ptr]
	sec.buf:Seek(0)
	if ccr.sections[sec.s_id]["read"] then sec = ccr.sections[sec.s_id]["read"](sec) end
	sec.buf:Seek(0)
	return sec
end

function ccr_file:WriteSection(sID, sDT)
	self.s_ptr = self.s_ptr + 1
	local sec = {s_id=sID, s_sz=#sDT, s_dt=sDT, buf=buffer.New()}
	if ccr.sections[sec.s_id]["write"] then sec = ccr.sections[sec.s_id]["write"](sec) end
	self.sections[self.s_ptr] = base.section.Create(sec.s_id, sec.s_sz, sec.s_dt)
end

function ccr_file:SeekSection(p)
	self.s_ptr = p
end

function ccr_file:TellSection()
	return self.s_ptr
end

--====================================================--

ccr.sections[0x01] = {}
ccr.sections[0x01].read = function(section)
	section.data = {}
	section.data.model = section.buf:ReadBSTRING()
	section.data.pcolor = section.buf:ReadVECTOR()
	section.data.wcolor = section.buf:ReadVECTOR()
	section.data.weapons = {}
	for i=1,section.buf:ReadUINT16() do
		section.data.weapons[#section.data.weapons+1] = {}
		local wtable = section.data.weapons[#section.data.weapons]
		wtable["ammo"] = {}
		wtable["ammo"]["t1"] = {section.buf:ReadINT8(), section.buf:ReadUINT16()}
		wtable["ammo"]["t2"] = {section.buf:ReadINT8(), section.buf:ReadUINT16()}
		local clip1 = section.buf:ReadINT16()
		local clip2 = section.buf:ReadINT16()
		local weapon = section.buf:ReadBSTRING()
		wtable["weapon"] = {weapon, clip1, clip2}
	end
	section.data.curweapon = section.buf:ReadBSTRING()
	section.data.pos = section.buf:ReadVECTOR()
	section.data.angles = section.buf:ReadANGLE()
	return section
end
ccr.sections[0x01].write = function(section)
	section.data = section.s_dt
	section.buf:WriteBSTRING(section.data.model)
	section.buf:WriteVECTOR(section.data.pcolor)
	section.buf:WriteVECTOR(section.data.wcolor)
	section.buf:WriteUINT16(#section.data.weapons)
	for i=1, #section.data.weapons do
		local wtable = section.data.weapons[i]
		section.buf:WriteINT8(wtable["ammo"]["t1"][1])
		section.buf:WriteINT16(wtable["ammo"]["t1"][2])
		section.buf:WriteINT8(wtable["ammo"]["t2"][1])
		section.buf:WriteINT16(wtable["ammo"]["t2"][2])
		section.buf:WriteINT16(wtable["weapon"][2])
		section.buf:WriteINT16(wtable["weapon"][3])
		section.buf:WriteBSTRING(wtable["weapon"][1])
	end
	section.buf:WriteBSTRING(section.data.curweapon)
	section.buf:WriteVECTOR(section.data.pos)
	section.buf:WriteANGLE(section.data.angles)
	section.s_dt = section.buf.data
	section.s_sz = #section.buf.data
	return section
end
ccr.sections[0x02] = {}
ccr.sections[0x02].read = function(s) s.s_dt = "" s.s_sz = 0 return s end
ccr.sections[0x02].write = function(s) s.s_dt = "" s.s_sz = 0 return s end
ccr.sections[0x03] = {}
ccr.sections[0x03].read = function(section)
	section.data = {}
	section.data.move = section.buf:ReadVECTOR()
	return section
end
ccr.sections[0x03].write = function(section)
	section.data = section.s_dt
	section.buf:WriteVECTOR(section.data.move)
	section.s_dt = section.buf.data
	section.s_sz = #section.buf.data
	return section
end
ccr.sections[0x04] = {}
ccr.sections[0x04].read = function(section)
	section.data = {}
	section.data.angles = section.buf:ReadANGLE()
	return section
end
ccr.sections[0x04].write = function(section)
	section.data = section.s_dt
	section.buf:WriteANGLE(section.data.angles)
	section.s_dt = section.buf.data
	section.s_sz = #section.buf.data
	return section
end
ccr.sections[0x05] = {}
ccr.sections[0x05].read = function(section)
	section.data = {}
	section.data.buttons = section.buf:ReadUINT16() + bit.lshift(section.buf:ReadUINT16(), 16)
	return section
end
ccr.sections[0x05].write = function(section)
	section.data = section.s_dt
	section.buf:WriteUINT16(bit.band(section.data.buttons, 65535))
	section.buf:WriteUINT16(bit.band(bit.rshift(section.data.buttons, 16), 65535))
	section.s_dt = section.buf.data
	section.s_sz = #section.buf.data
	return section
end
ccr.sections[0x06] = {}
ccr.sections[0x06].read = function(section)
	section.data = {}
	section.data.impulse = section.buf:ReadUINT8()
	return section
end
ccr.sections[0x06].write = function(section)
	section.data = section.s_dt
	section.buf:WriteUINT8(section.data.impulse)
	section.s_dt = section.buf.data
	section.s_sz = #section.buf.data
	return section
end
ccr.sections[0x07] = {}
ccr.sections[0x07].read = function(section)
	section.data = {}
	section.data.pos = section.buf:ReadVECTOR()
	return section
end
ccr.sections[0x07].write = function(section)
	section.data = section.s_dt
	section.buf:WriteVECTOR(section.data.pos)
	section.s_dt = section.buf.data
	section.s_sz = #section.buf.data
	return section
end
--[[
ccr.sections[sID] = {}
ccr.sections[sID].read = function(section)
	section.data = {}
	-- read
	return section
end
ccr.sections[sID].write = function(section)
	section.data = section.s_dt
	-- write
	section.s_dt = section.buf.data
	section.s_sz = #section.buf.data
	return section
end
]]

--====================================================--

function ccr_file:Stop()
	if not SERVER then
		return error("RECORD:Stop() should be called on SERVER!")
	end
	if game.SinglePlayer() then
		return error("RECORD:Stop() should be called in MULTIPLAYER!")
	end
	if not (self.replaying or self.recording) then
		return error("RECORD:Stop() should be called after RECORD:Play() or RECORD:Record()!")
	end

	if self.replaying then
		hook.Remove("StartCommand", "CamCoder_Player_"..self.bot.name)
		self.bot:Kick("Early stop")
		self.bot = nil
		self.replaying = false
		return
	end

	hook.Remove("StartCommand", "CamCoder_Recorder_"..self.ply:Name())
	self.ply = nil
	self.recording = false
	self:UpdateData()
end

function ccr_file:Record(ply_to_rec)
	if not SERVER then
		return error("RECORD:Record() should be called on SERVER!")
	end
	if game.SinglePlayer() then
		return error("RECORD:Record() should be called in MULTIPLAYER!")
	end
	self:SeekSection(1)

	self.recording = true
	self.ply = ply_to_rec

	local weps = {}
	for _,wep in pairs(self.ply:GetWeapons()) do
		weps[#weps+1] = {}
		local wtable = weps[#weps]
		wtable["ammo"] = {}
		wtable["ammo"]["t1"] = {wep:GetPrimaryAmmoType(), self.ply:GetAmmo(wep:GetPrimaryAmmoType()).Value or 0}
		wtable["ammo"]["t2"] = {wep:GetSecondaryAmmoType(), self.ply:GetAmmo(wep:GetSecondaryAmmoType()).Value or 0}
		wtable["weapon"] = {wep:GetClass(), wep:Clip1(), wep:Clip2()}
	end

	self:WriteSection(0x01, {
		model = self.ply:GetModel(),
		pcolor = self.ply:GetPlayerColor(),
		wcolor = self.ply:GetWeaponColor(),
		weapons = weps,
		curweapon = self.ply:GetActiveWeapon():GetClass(),
		pos = self.ply:GetPos(),
		angles = self.ply:EyeAngles()
	})

	local laststate = {}
	hook.Add("StartCommand", "CamCoder_Recorder_"..ply_to_rec:Name(), function(ply, cmd)
		if ply ~= ply_to_rec then return end
		if laststate.pos ~= ply:GetPos() then
			laststate.pos = ply:GetPos()
			self:WriteSection(0x07, {
				pos = laststate.pos
			})
		end
		if Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove()) ~= laststate.move then
			laststate.move = Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove())
			self:WriteSection(0x03, {
				move = laststate.move
			})
		end
		if ply:EyeAngles() ~= laststate.angles then
			laststate.angles = ply:EyeAngles()
			self:WriteSection(0x04, {
				angles = laststate.angles
			})
		end
		if cmd:GetButtons() ~= laststate.buttons then
			laststate.buttons = cmd:GetButtons()
			self:WriteSection(0x05, {
				buttons = laststate.buttons
			})
		end
		if cmd:GetImpulse() ~= laststate.impulse then
			laststate.impulse = cmd:GetImpulse()
			self:WriteSection(0x06, {
				impulse = laststate.impulse
			})
		end
		self:WriteSection(0x02, {})
	end)
end

function ccr_file:Play()
	if not SERVER then
		return error("RECORD:Play() should be called on SERVER!")
	end
	if game.SinglePlayer() then
		return error("RECORD:Play() should be called in MULTIPLAYER!")
	end
	self:SeekSection(1)

	local name = "Camcoder bot "..math.random(10000,99999)
	local bot = player.CreateNextBot(name)
	if not bot then
		return error("RECORD:Play() has failed to create a bot!")
	end

	self.bot = bot
	self.bot.name = name
	self.replaying = true

	local initialiser = self:ReadSection()

	self.bot:SetModel(initialiser.data.model)
	self.bot:SetPlayerColor(initialiser.data.pcolor)
	self.bot:SetWeaponColor(initialiser.data.wcolor)
	self.bot:SetPos(initialiser.data.pos)
	self.bot:SetEyeAngles(initialiser.data.angles)
	self.bot:StripAmmo()
	self.bot:StripWeapons()
	for _,wtable in pairs(initialiser.data.weapons) do
		if wtable["ammo"]["t1"][1] ~= -1 then
			self.bot:SetAmmo(wtable["ammo"]["t1"][1], wtable["ammo"]["t1"][2])
		end
		if wtable["ammo"]["t2"][1] ~= -1 then
			self.bot:SetAmmo(wtable["ammo"]["t2"][1], wtable["ammo"]["t2"][2])
		end
		local wep = self.bot:Give(wtable["weapon"][1])
		if wep then
			wep:SetClip1(wtable["weapon"][2])
			wep:SetClip2(wtable["weapon"][3])
		end
	end
	self.bot:SelectWeapon(initialiser.data.curweapon)

	local function fail(message)
		bot:Kick("Runtime error")
		self.bot = nil
		self.replaying = false
		hook.Remove("StartCommand", "CamCoder_Player_"..name)
		return error(message)
	end

	local laststate = {}
	hook.Add("StartCommand", "CamCoder_Player_"..name, function(ply, cmd)
		if ply ~= bot then return end

		if self:TellSection() >= #self.sections then
			bot:Kick("Recording ended.")
			hook.Remove("StartCommand", "CamCoder_Player_"..name)
			self.bot = nil
			self.replaying = false
			return
		end

		cmd:ClearButtons()
		cmd:ClearMovement()

		local done = false
		while not done do
			local section = self:ReadSection()

			if section.s_id == 0x02 then
				done = true
			end
			if section.s_id == 0x03 then
				laststate.move = section.data.move
			end
			if section.s_id == 0x04 then
				laststate.angles = section.data.angles
				ply:SetEyeAngles(laststate.angles)
			end
			if section.s_id == 0x05 then
				laststate.buttons = section.data.buttons
			end
			if section.s_id == 0x06 then
				laststate.impulse = section.data.impulse
				cmd:SetImpulse(laststate.impulse)
			end
		end
		if laststate.move then
			cmd:SetForwardMove(laststate.move.x)
			cmd:SetSideMove(laststate.move.y)
			cmd:SetUpMove(laststate.move.z)
		end
		if laststate.buttons then
			cmd:SetButtons(laststate.buttons)
		end
	end)
end

--====================================================--

if SERVER then
	util.AddNetworkString("ccr_protocol")
	local records = {}
	function ccr.Reply(who, req, data)
		net.Start("ccr_protocol")
			net.WriteString(req)
			net.WriteTable(data)
		net.Send(who)
	end
	net.Receive("ccr_protocol", function(_, ply)
		if not ply:IsListenServerHost() then return end
		local req = net.ReadString()
		local data = net.ReadTable()
		if req == "record" then
			local succ, varg = pcall(function()
				local handle = ccr.New()
				handle:Record(ply)
				return handle
			end)
			if succ then
				ply.ccr_handle = varg
				return ccr.Reply(ply, "record", {"ok"})
			end
			return ccr.Reply(ply, "record", {"fail", varg})
		end
		if req == "play" then
			for _,v in pairs(records) do v:Stop() end
			records = {}
			local succ, varg = pcall(function()
				for _,f in pairs(data) do
					records[#records+1] = ccr.FromRAW(file.Read("camcoder/"..f, "DATA"))
				end
				for _,v in pairs(records) do v:Play() end
			end)
			if succ then
				return ccr.Reply(ply, "play", {"ok"})
			end
			return ccr.Reply(ply, "play", {"fail", varg})
		end
		if req == "stop" then
			local succ, varg = pcall(function()
				if ply.ccr_handle then pcall(function() ply.ccr_handle:Stop() end) end
				for k,v in pairs(records) do
					pcall(function() v:Stop() end)
				end
			end)
			if succ then
				return ccr.Reply(ply, "stop", {"ok"})
			end
			return ccr.Reply(ply, "stop", {"fail", varg})
		end
		if req == "save" then
			local succ, varg = pcall(function()
				if not ply.ccr_handle then error("nothing was recorded") end
				if ply.ccr_handle.recording or ply.ccr_handle.replaying then error("recording is being used") end
				file.CreateDir("camcoder")
				file.Write("camcoder/"..data[1]..".txt", ply.ccr_handle.buf.data)
			end)
			if succ then
				return ccr.Reply(ply, "save", {"ok"})
			end
			return ccr.Reply(ply, "save", {"fail", varg})
		end
	end)
end

if CLIENT then
	local requests = {}
	function ccr.Request(req, data, cb)
		requests[#requests+1] = {
			req, data, cb
		}
		net.Start("ccr_protocol")
			net.WriteString(req)
			net.WriteTable(data)
		net.SendToServer()
	end
	net.Receive("ccr_protocol", function()
		local req = net.ReadString()
		local ndata = net.ReadTable()
		for k,v in pairs(requests) do
			if v[1] == req then
				v[3](v[1], v[2], ndata)
				requests[k] = nil
			end
		end
	end)
	function ccr.StartRecord(ok_cb, fl_cb)
		ccr.Request("record", {}, function(req, _, reply)
			if reply[1] == "ok" then
				return ok_cb(reply)
			end
			return fl_cb(reply)
		end)
	end
	function ccr.Stop(ok_cb, fl_cb)
		ccr.Request("stop", {}, function(req, _, reply)
			if reply[1] == "ok" then
				return ok_cb(reply)
			end
			return fl_cb(reply)
		end)
	end
	function ccr.Save(fname, ok_cb, fl_cb)
		ccr.Request("save", {fname}, function(req, _, reply)
			if reply[1] == "ok" then
				return ok_cb(reply)
			end
			return fl_cb(reply)
		end)
	end
	function ccr.Play(recs, ok_cb, fl_cb)
		ccr.Request("play", recs, function(req, _, reply)
			if reply[1] == "ok" then
				return ok_cb(reply)
			end
			return fl_cb(reply)
		end)
	end


	function ccr_file:PlayPreview(stop_on_end)
		if game.SinglePlayer() then
			return error("RECORD:PlayPreview() should be called in MULTIPLAYER!")
		end
		self:SeekSection(1)

		local hname = "CamCoder_Player_"..math.random(10000, 99999)

		self.bot = ClientsideModel("models/editor/playerstart.mdl", RENDERGROUP_TRANSLUCENT)
		self.bot:Spawn()
		self.bot:SetRenderMode(RENDERMODE_TRANSCOLOR)

		self.replaying = true

		local initialiser = self:ReadSection()

		self.bot:SetPos(initialiser.data.pos)
		self.bot:SetAngles(initialiser.data.angles)

		local function fail(message)
			hook.Remove("StartCommand", hname)
			return error(message)
		end

		local laststate = {}
		local last = 0
		hook.Add("StartCommand", hname, function(ply, cmd)
			if ply ~= LocalPlayer() then return end
			if CurTime() - last < 0.015 then return end
			last = CurTime()
			self.bot:SetColor(Color(255, 255, 255, math.random(200, 255)))

			if self:TellSection() >= #self.sections then
				if stop_on_end then
					if not IsValid(self.bot) then return end
					self.replaying = true
					hook.Remove("StartCommand", hname)
					self.bot:Remove()
					return
				end
				self:SeekSection(1)
				local initialiser = self:ReadSection()

				self.bot:SetPos(initialiser.data.pos)
				self.bot:SetAngles(initialiser.data.angles)
				return
			end

			local done = false
			while not done do
				local section = self:ReadSection()

				if section.s_id == 0x02 then
					done = true
				end
				if section.s_id == 0x03 then
					laststate.move = section.data.move
				end
				if section.s_id == 0x04 then
					laststate.angles = section.data.angles
					self.bot:SetAngles(laststate.angles)
				end
				if section.s_id == 0x05 then
					laststate.buttons = section.data.buttons
				end
				if section.s_id == 0x06 then
					laststate.impulse = section.data.impulse
				end
				if section.s_id == 0x07 then
					laststate.pos = section.data.pos
					self.bot:SetPos(laststate.pos)
				end
			end
		end)
		return function()
			if not IsValid(self.bot) then return end
			self.replaying = true
			hook.Remove("StartCommand", hname)
			self.bot:Remove()
		end
	end
end

return ccr