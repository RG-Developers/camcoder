if _G.CAMCODER_INCLUDES.ccr_0000 then return _G.CAMCODER_INCLUDES.ccr_0000 end

local base = include("camcoder/format/ccr_base.lua")
local buffer = include("camcoder/format/buffer.lua")
local preferences = include("camcoder/format/preferences.lua")

local ccr = {sections={}}
local ccr_file = {s_ptr=0}

local function try(what, default)
	local succ, vararg = pcall(function()
		local res = what()
		assert(res ~= nil)
		return res
	end)
	if not succ then return default end
	return vararg
end

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

function ccr_file:WriteToFile(path)
	self:UpdateData()
	local data = self.buf.data
	file.Write("camcoder/recordings/"..path, data)
end

function ccr_file:ReadSection()
	self.s_ptr = self.s_ptr + 1
	local sec = self.sections[self.s_ptr]
	sec.buf:Seek(0)
	if ccr.sections[sec.s_id] and ccr.sections[sec.s_id]["read"] then sec = ccr.sections[sec.s_id]["read"](sec) end
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
ccr.sections[0x00] = {}
ccr.sections[0x00].read = function(section)
	section.data = {}
	section.buf:ReadRAW(4)
	section.data.version = section.buf:ReadUINT16()
	return section
end
ccr.sections[0x01] = {}
ccr.sections[0x01].read = function(section)
	section.data = {}
	section.data.model = try(function() return section.buf:ReadBSTRING() end, "error")
	section.data.pcolor = try(function() return section.buf:ReadVECTOR() end, Vector())
	section.data.wcolor = try(function() return section.buf:ReadVECTOR() end, Vector())
	section.data.weapons = {}
	for i=1, try(function() return section.buf:ReadUINT16() end, 0) do
		section.data.weapons[#section.data.weapons+1] = {}
		local wtable = section.data.weapons[#section.data.weapons]
		wtable["ammo"] = {}
		wtable["ammo"]["t1"] = {try(function() return section.buf:ReadINT8() end, -1), try(function() return section.buf:ReadUINT16() end, -1)}
		wtable["ammo"]["t2"] = {try(function() return section.buf:ReadINT8() end, -1), try(function() return section.buf:ReadUINT16() end, -1)}
		local clip1 = try(function() return section.buf:ReadINT16() end, 0)
		local clip2 = try(function() return section.buf:ReadINT16() end, 0)
		local weapon = try(function() return section.buf:ReadBSTRING() end, "weapon_crowbar")
		wtable["weapon"] = {weapon, clip1, clip2}
	end
	section.data.curweapon = try(function() return section.buf:ReadBSTRING() end, "weapon_crowbar")
	section.data.pos = try(function() return section.buf:ReadVECTOR() end, Vector())
	section.data.angles = try(function() return section.buf:ReadANGLE() end, Angle())
	section.data.name = try(function() return section.buf:ReadBSTRING() end, "error!")
	section.data.groups = try(function() return section.buf:ReadSSTRING() end, "")
	section.data.skin = try(function() return section.buf:ReadUINT8() end, 0)
	section.data.map = try(function() return section.buf:ReadSSTRING() end, game.GetMap())
	section.data.voicepath = try(function() return section.buf:ReadSSTRING() end, "")
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
		section.buf:WriteUINT16(wtable["ammo"]["t1"][2])
		section.buf:WriteINT8(wtable["ammo"]["t2"][1])
		section.buf:WriteUINT16(wtable["ammo"]["t2"][2])
		section.buf:WriteINT16(wtable["weapon"][2])
		section.buf:WriteINT16(wtable["weapon"][3])
		section.buf:WriteBSTRING(wtable["weapon"][1])
	end
	section.buf:WriteBSTRING(section.data.curweapon)
	section.buf:WriteVECTOR(section.data.pos)
	section.buf:WriteANGLE(section.data.angles)
	section.buf:WriteBSTRING(section.data.name)
	section.buf:WriteSSTRING(section.data.groups)
	section.buf:WriteUINT8(section.data.skin)
	section.buf:WriteSSTRING(section.data.map)
	section.buf:WriteSSTRING(section.data.voicepath)
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
	section.data.move = try(function() return section.buf:ReadVECTOR() end, Vector())
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
	section.data.angles = try(function() return section.buf:ReadANGLE() end, Angle())
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
	section.data.buttons = try(function() return section.buf:ReadUINT16() end, 0) + try(function() return bit.lshift(section.buf:ReadUINT16(), 16) end, 0)
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
	section.data.impulse = try(function() return section.buf:ReadUINT8() end, 0)
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
	section.data.offset = try(function() return section.buf:ReadVECTOR() end, Vector())
	return section
end
ccr.sections[0x07].write = function(section)
	section.data = section.s_dt
	section.buf:WriteVECTOR(section.data.offset)
	section.s_dt = section.buf.data
	section.s_sz = #section.buf.data
	return section
end
ccr.sections[0x08] = {}
ccr.sections[0x08].read = function(section)
	section.data = {}
	section.data.weapon = try(function() return section.buf:ReadBSTRING() end, "")
	return section
end
ccr.sections[0x08].write = function(section)
	section.data = section.s_dt
	section.buf:WriteBSTRING(section.data.weapon)
	section.s_dt = section.buf.data
	section.s_sz = #section.buf.data
	return section
end
ccr.sections[0x09] = {}
ccr.sections[0x09].read = function(section)
	section.data = {}
	section.data.text = try(function() return section.buf:ReadBSTRING() end, "")
	return section
end
ccr.sections[0x09].write = function(section)
	section.data = section.s_dt
	section.buf:WriteBSTRING(section.data.text)
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
		net.Start("ccr_protocol_u")
			net.WriteString("voicestop")
			net.WriteEntity(self.bot)
		net.Broadcast()
		self.bot = nil
		self.replaying = false
		return
	end

	hook.Remove("StartCommand", "CamCoder_Recorder_"..self.ply:Name())
	hook.Remove("PlayerSay", "CamCoder_Recorder_"..self.ply:Name())
	net.Start("ccr_protocol_u")
		net.WriteString("voicestop")
		net.WriteEntity(self.ply)
	net.Broadcast()
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

	local broups = ""
	local function basen(n,b)
	    n = math.floor(n)
	    if not b or b == 10 then return tostring(n) end
	    local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	    local t = {}
	    local sign = ""
	    if n < 0 then
	        sign = "-"
	    n = -n
	    end
	    repeat
	        local d = (n % b) + 1
	        n = math.floor(n / b)
	        table.insert(t, 1, digits:sub(d,d))
	    until n == 0
	    return sign .. table.concat(t,"")
	end
	local groups = ""
	for i=0,#self.ply:GetBodyGroups() do
		groups = groups .. basen(self.ply:GetBodygroup(i), 35)
	end

	self:WriteSection(0x01, {
		model = self.ply:GetModel(),
		pcolor = self.ply:GetPlayerColor(),
		wcolor = self.ply:GetWeaponColor(),
		weapons = weps,
		curweapon = self.ply:GetActiveWeapon():GetClass(),
		pos = self.ply:GetPos(),
		angles = self.ply:EyeAngles(),
		name = self.ply:Nick(),
		groups = groups,
		skin = self.ply:GetSkin(),
		map = game.GetMap(),
		voicepath = ply_to_rec.camcoder_voicepath or ""
	})

	timer.Simple(0.5, function()
		net.Start("ccr_protocol_u")
			net.WriteString("voiceinit")
			net.WriteEntity(ply_to_rec)
			net.WriteString(ply_to_rec.camcoder_voicepath or "")
		net.Broadcast()
	end)

	local laststate = {
		lastpos = self.ply:GetPos(),
		move = Vector(),
		angles = self.ply:EyeAngles(),
		buttons = 0,
		impulse = 0,
		offset = Vector(),
		weapon = self.ply:GetActiveWeapon():GetClass()
	}
	hook.Add("StartCommand", "CamCoder_Recorder_"..ply_to_rec:Name(), function(ply, cmd)
		if ply ~= ply_to_rec then return end
		if not IsValid(ply_to_rec) then return end
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
		if laststate.lastpos ~= ply:GetPos() then
			self:WriteSection(0x07, {
				offset = ply:GetPos() - laststate.lastpos
			})
			laststate.lastpos = ply:GetPos()
		end
		if IsValid(ply:GetActiveWeapon()) and laststate.weapon ~= ply:GetActiveWeapon():GetClass() then
			laststate.weapon = ply:GetActiveWeapon():GetClass()
			self:WriteSection(0x08, {
				weapon = laststate.weapon
			})
		end
		self:WriteSection(0x02, {})
	end)
	hook.Add("PlayerSay", "CamCoder_Recorder_"..ply_to_rec:Name(), function(ply, text)
		if ply ~= ply_to_rec then return end
		if not IsValid(ply_to_rec) then return end
		if not preferences.recordchat then return end
		self:WriteSection(0x09, {
			text = text
		})
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

	local initialiser = self:ReadSection()

	local bot = player.CreateNextBot(initialiser.data.name.."ㅤ")
	if not bot then
		return error("RECORD:Play() has failed to create a bot!")
	end

	self.bot = bot
	self.bot.name = name
	self.bot.camcoder_bot = true
	self.bot.camcoder_voicepath = initialiser.data.voicepath
	self.replaying = true

	self.bot:SetModel(initialiser.data.model)
	self.bot:SetSkin(initialiser.data.skin)
	self.bot:SetBodyGroups(initialiser.data.groups)
	self.bot:SetPlayerColor(initialiser.data.pcolor)
	self.bot:SetWeaponColor(initialiser.data.wcolor)
	self.bot:SetPos(initialiser.data.pos)
	self.bot:SetEyeAngles(initialiser.data.angles)

	self.bot:StripAmmo()
	self.bot:StripWeapons()
	self.bot:SetCustomCollisionCheck(true)
	local ed = EffectData()
		ed:SetOrigin(self.bot:GetPos())
		ed:SetEntity(self.bot)
	util.Effect("propspawn", ed, true, true)

	for _,wtable in pairs(initialiser.data.weapons) do
		if wtable["ammo"]["t1"][1] ~= -1 then
			self.bot:SetAmmo(wtable["ammo"]["t1"][1], wtable["ammo"]["t1"][2])
		end
		if wtable["ammo"]["t2"][1] ~= -1 then
			self.bot:SetAmmo(wtable["ammo"]["t2"][1], wtable["ammo"]["t2"][2])
		end
		local wep = self.bot:Give(wtable["weapon"][1])
		if wep then
			if wep.SetClip1 then wep:SetClip1(wtable["weapon"][2]) end
			if wep.SetClip2 then wep:SetClip2(wtable["weapon"][3]) end
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

	local laststate = {startpos=self.bot:GetPos(), started=false}
	hook.Add("StartCommand", "CamCoder_Player_"..name, function(ply, cmd)
		if ply ~= bot then return end
		if not IsValid(bot) then return end
		if not laststate.started then
			laststate.started = true
			if initialiser.data.map ~= game.GetMap() then
				timer.Simple(0.5, function()
					net.Start("ccr_protocol_u")
						net.WriteString("chat")
						net.WriteEntity(self.bot)
						net.WriteString("This file was recorded on "..initialiser.data.map..", instead playing on "..game.GetMap())
					net.Broadcast()
				end)
			end
			if self.bot.camcoder_voicepath ~= "" then
				timer.Simple(0.5, function()
					net.Start("ccr_protocol_u")
						net.WriteString("voiceinit")
						net.WriteEntity(self.bot)
						net.WriteString(self.bot.camcoder_voicepath)
					net.Broadcast()
				end)
			end
		end

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
			if section.s_id == 0x07 then
				-- unused, can be used for syncronisation
			end
			if section.s_id == 0x08 then
				laststate.weapon = section.data.weapon
				if IsValid(ply:GetWeapon(laststate.weapon)) then
					cmd:SelectWeapon(ply:GetWeapon(laststate.weapon))
				end
			end
			if section.s_id == 0x09 then
				net.Start("ccr_protocol_u")
					net.WriteString("chat")
					net.WriteEntity(ply)
					net.WriteString(section.data.text)
				net.Broadcast()
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

if CLIENT then
	function ccr_file:PlayPreview(stop_on_end)
		if game.SinglePlayer() then
			return error("RECORD:PlayPreview() should be called in MULTIPLAYER!")
		end
		self:SeekSection(1)

		local hname = "CamCoder_Player_"..math.random(10000, 99999)

		self.bot = ClientsideModel("models/editor/playerstart.mdl", RENDERGROUP_TRANSLUCENT)
		self.bot:Spawn()
		self.bot:SetRenderMode(RENDERMODE_TRANSCOLOR)
		self.bot.messages = {}
		self.bot.head = ClientsideModel("models/editor/camera.mdl", RENDERGROUP_TRANSLUCENT)
		self.bot.head:Spawn()
		self.bot.head:SetRenderMode(RENDERMODE_TRANSCOLOR)

		self.replaying = true

		local initialiser = self:ReadSection()

		self.bot.head:SetPos(initialiser.data.pos+Vector(0, 0, 67))
		self.bot:SetPos(initialiser.data.pos)
		self.bot.head:SetAngles(initialiser.data.angles)
		self.bot:SetAngles(Angle(0, self.bot.head:GetAngles().y, 0))

		local name = initialiser.data.name

		local laststate = {startpos=initialiser.data.pos}
		local lastpause = 0
		hook.Add("StartCommand", hname, function(ply, cmd)
			if ply ~= LocalPlayer() then return end
			if cmd:TickCount() == 0 then return end
			if CurTime() - lastpause <= 0.01 then return end
			lastpause = CurTime()
			self.bot:SetColor(Color(255, 255, 255, math.random(200, 255)))
			self.bot.head:SetColor(Color(255, 255, 255, math.random(200, 255)))

			if self:TellSection() >= #self.sections then
				if stop_on_end then
					if not IsValid(self.bot) then return end
					self.replaying = true
					hook.Remove("StartCommand", hname)
					hook.Remove("PostDrawTranslucentRenderables", hname)
					self.bot:Remove()
					self.bot.head:Remove()
					return
				end
				self:SeekSection(1)
				local initialiser = self:ReadSection()

				self.bot.head:SetPos(initialiser.data.pos+Vector(0, 0, 67))
				self.bot:SetPos(initialiser.data.pos)
				self.bot.head:SetAngles(initialiser.data.angles)
				self.bot:SetAngles(Angle(0, self.bot.head:GetAngles().y, 0))
				self.bot.messages = {}
				laststate = {startpos=initialiser.data.pos}
				return
			end

			local done = false
			while not done do
				local section = self:ReadSection()

				if section.s_id == 0x02 then
					done = true
				end
				if section.s_id == 0x04 then
					laststate.angles = section.data.angles
					self.bot:SetAngles(Angle(0, laststate.angles.y, 0))
					self.bot.head:SetAngles(laststate.angles)
				end
				if section.s_id == 0x07 then
					self.bot:SetPos(self.bot:GetPos() + section.data.offset)
					self.bot.head:SetPos(self.bot:GetPos() + section.data.offset+Vector(0, 0, 67))
				end
				if section.s_id == 0x09 then
					self.bot.messages[#self.bot.messages+1] = section.data.text
				end
			end
		end)
		hook.Add("PostDrawTranslucentRenderables", hname, function()
			if self.bot:GetPos():Distance(EyePos()) > 1024 then return end
			local pos = self.bot:GetPos() + self.bot:GetUp() * 85
			local angle = (pos - EyePos()):GetNormalized():Angle()
			angle = Angle(0, angle.y, 0)
			angle:RotateAroundAxis(angle:Up(), -90)
			angle:RotateAroundAxis(angle:Forward(), 90)
			cam.Start3D2D(pos, angle, 0.05 * self.bot:GetPos():Distance(EyePos()) / 128)
				surface.SetFont("Camcoder_PlayerPreviewFont_Large")
				local tW, tH = surface.GetTextSize(name)
				local padX = 20
				local padY = 5
				surface.SetDrawColor(0, 0, 0, 200)
				surface.DrawRect(-tW / 2 - padX, -padY, tW + padX * 2, tH + padY * 2)
				draw.SimpleText(name, "Camcoder_PlayerPreviewFont_Large", -tW / 2, 0, color_white)
				for k,v in pairs(table.Reverse(self.bot.messages)) do
					if k > 5 then break end
					surface.SetFont("Camcoder_PlayerPreviewFont_Medium")
					local tW, tH = surface.GetTextSize(v)
					local padX = 20
					local padY = 5
					surface.SetDrawColor(0, 0, 0, math.max(0, 200 - 51*k))
					surface.DrawRect(300 + -tW / 2 - padX, -padY + tH*(k*2+2), tW + padX * 2, tH + padY * 2)
					draw.SimpleText(v, "Camcoder_PlayerPreviewFont_Medium", 300 + -tW / 2, tH*(k*2+2), Color(255, 255, 255, math.max(0, 255 - 51*k)))
				end
			cam.End3D2D()
		end)
		return function()
			if not IsValid(self.bot) then return end
			self.replaying = false
			hook.Remove("StartCommand", hname)
			hook.Remove("PostDrawTranslucentRenderables", hname)
			self.bot:Remove()
			self.bot.head:Remove()
		end
	end
end

--====================================================--

_G.CAMCODER_INCLUDES.ccr_0000 = ccr

return ccr