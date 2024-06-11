local ccr = {}
local base = include("ccr_base.lua")
local buffer = include("buffer.lua")
local ccr_table = {}

print("reloaded")

--===========================================================================--

function ccr_table:WriteInitialiser(player)
	local initialiser = base.section.New(0x01)
	initialiser:WriteBSTRING(player:GetModel())
	initialiser:WriteVECTOR(player:GetPlayerColor())
	initialiser:WriteVECTOR(player:GetWeaponColor())
	local weapons = player:GetWeapons()
	initialiser:WriteUINT16(#weapons)
	for _,wep in ipairs(weapons) do
		initialiser:WriteINT8(wep:GetPrimaryAmmoType())
		if wep:GetPrimaryAmmoType() == -1 then
			initialiser:WriteUINT16(0)
		else
			initialiser:WriteUINT16(player:GetAmmoCount(wep:GetPrimaryAmmoType()))
		end
		initialiser:WriteINT8(wep:GetSecondaryAmmoType())
		if wep:GetSecondaryAmmoType() == -1 then
			initialiser:WriteUINT16(0)
		else
			initialiser:WriteUINT16(player:GetAmmoCount(wep:GetSecondaryAmmoType()))
		end
		initialiser:WriteINT16(wep:Clip1())
		initialiser:WriteINT16(wep:Clip2())
		initialiser:WriteBSTRING(wep:GetClass())
	end
	initialiser:WriteBSTRING(player:GetActiveWeapon():GetClass())
	initialiser:WriteVECTOR(player:GetPos())
	initialiser:WriteANGLE(player:EyeAngles())
	self:WriteSection(initialiser)
end
function ccr_table:ReadInitialiser(player)
	local section = self:ReadSection()
	assert(section.s_id == 0x01, "Unexpected sID!")
	player:SetModel(section:ReadBSTRING())
	player:SetPlayerColor(section:ReadVECTOR())
	player:SetWeaponColor(section:ReadVECTOR())
	player:KillSilent()
	player:Spawn()
	player:StripWeapons()
	player:StripAmmo()
	local ammos = {}
	for i=1,section:ReadUINT16() do
		local ammotype1 = section:ReadINT8()
		if ammotype1 == -1 then
			section:ReadUINT16()
		else
			ammos[tostring(ammotype1)] = section:ReadUINT16()
		end
		local ammotype2 = section:ReadINT8()
		if ammotype2 == -1 then
			section:ReadUINT16()
		else
			ammos[tostring(ammotype2)] = section:ReadUINT16()
		end
		local clip1 = section:ReadINT16()
		local clip2 = section:ReadINT16()
		player:Give(section:ReadBSTRING())
	end
	player:StripAmmo()
	for type,amount in pairs(ammos) do
		player:GiveAmmo(type, amount)
	end
	player:SelectWeapon(section:ReadBSTRING())
	player:SetPos(section:ReadVECTOR())
	player:SetEyeAngles(section:ReadANGLE())
end

local read = {
	["V"]=buffer.ReadVECTOR,
	["A"]=buffer.ReadANGLE,
	["u"]=buffer.ReadUINT8,
	["U"]=buffer.ReadUINT16,
	["i"]=buffer.ReadINT8,
	["I"]=buffer.ReadINT16,
	["f"]=buffer.ReadFLOAT32,
	["F"]=buffer.ReadFLOAT64,
}
local write = {
	["V"] = buffer.WriteVECTOR,
	["A"] = buffer.WriteANGLE,
	["u"] = buffer.WriteUINT8,
	["U"] = buffer.WriteUINT16,
	["i"] = buffer.WriteINT8,
	["I"] = buffer.WriteINT16,
	["f"] = buffer.WriteFLOAT32,
	["F"] = buffer.WriteFLOAT64,
}
local frame_types = {
	[0x00]={},
	[0x01]={"V", "V", "A"},
	[0x02]={"U", "U"}
}
local names = {
	[0x00]="delim",
	[0x01]="move",
	[0x02]="buttons"
}
local ids = {
	delim=0x00,
	move=0x01,
	buttons=0x02
}

function ccr_table:ReadFrame()
	local raw = self:ReadSection()
	print(raw)
	local frametype = frame_types[raw.s_id]
	if frametype == nil then
		return error("Encountered unknown fID \""..raw.s_id.."\"")
	end
	local data = {}
	for _, dtype in ipairs(frametype) do
		data[#data+1] = read[dtype](self)
	end
	return names[raw.s_id], data
end
function ccr_table:WriteFrame(fID, fDT)
	local frametype = frame_types[ids[fID]]
	if frametype == nil then
		return error("Encountered unknown fID \""..fID.."\"")
	end
	local frame = base.section.New(0x02)
	local raw = base.section.New(ids[fID])
	for _, dtype in ipairs(frametype) do
		write[dtype](raw, fDT[_])
	end
	frame:WriteSection(raw)
	self:WriteSection(frame)
end

function ccr_table:Play()
	if not SERVER then
		return error("RECORD:Play() should be called on SERVER!")
	end
	if game.SinglePlayer() then
		return error("RECORD:Play() should be called in MULTIPLAYER!")
	end
	self:Seek(0)
	self:ReadSection()

	local name = "Camcoder bot "..math.random(10000,99999)
	local bot = player.CreateNextBot(name)
	if not bot then
		return error("RECORD:Play() has failed to create a bot!")
	end

	self.bot = bot
	self.bot.name = name
	self.replaying = true

	self:ReadInitialiser(bot)

	local function fail(message)
		bot:Kick("Runtime error")
		hook.Remove("SetupMove", "CamCoder_Player_"..name)
		return error(message)
	end

	hook.Add("SetupMove", "CamCoder_Player_"..name, function(ply, move, cmd)
		if ply ~= bot then return end

		if self:Tell() >= #self.data then
			bot:Kick("Recording ended.")
			hook.Remove("SetupMove", "CamCoder_Player_"..name)
			return
		end

		--local section = self:ReadSection()
		--if section.s_id ~= 0x02 then
		--	return fail("Encountered unknown sID \""..section.s_id.."\"")
		--end

		local done = false
		while not done do
			local success, name, data = pcall(function() return self:ReadFrame() end)
			if not success then
				return fail(name)
			end

			if name == "delim" then
				done = true
			end
			if name == "move" then
				move:SetForwardSpeed(data[1].x)
				move:SetSideSpeed(data[1].y)
				move:SetUpSpeed(data[1].z)
				bot:SetAngles(data[3])
			end
		end
	end)
end
function ccr_table:Stop()
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
		hook.Remove("SetupMove", "CamCoder_Player_"..self.bot.name)
		self.bot:Kick("Early stop")
		self.bot = nil
		self.replaying = false
		return
	end

	hook.Remove("SetupMove", "CamCoder_Recorder_"..self.ply:Name())
	self.ply = nil
	self.recording = false
end
function ccr_table:Record(ply_to_rec)
	if not SERVER then
		return error("RECORD:Record() should be called on SERVER!")
	end
	if game.SinglePlayer() then
		return error("RECORD:Record() should be called in MULTIPLAYER!")
	end
	self:Seek(0)
	self:ReadSection()

	self.recording = true
	self.ply = ply_to_rec

	self:WriteInitialiser(ply_to_rec)

	hook.Add("SetupMove", "CamCoder_Recorder_"..ply_to_rec:Name(), function(ply, move, cmd)
		if ply ~= ply_to_rec then return end
		if move:GetForwardSpeed() ~= 0 or move:GetSideSpeed() ~= 0 or move:GetUpSpeed() ~= 0 then
			self:WriteFrame("move", {Vector(move:GetForwardSpeed(), move:GetSideSpeed(), move:GetUpSpeed()), ply:GetPos(), ply:EyeAngles()})
		end
		self:WriteFrame("delim", {})
	end)
end

--===========================================================================--

function ccr.CreateHandler(data, docheck)
	local ccrh = base.CreateBaseHandler(data)
	if docheck then
		local section = ccrh:ReadSection()
		assert(section.s_id == 0x00,                    "invalid starting section id - expected 0, got "..section.s_id)
		assert(section.s_sz == 6,                       "invalid starting section size - expected 6, got "..section.s_sz)
		assert(string.StartsWith(section.s_dt, "CCRF"), "invalid starting section header")
		local iVR = table.Pack(string.byte(string.sub(section.s_dt, 5, 6), 1, 2))
		assert(iVR[1] == 0 and iVR[2] == 0, "unknown CCRF version")
	end
	ccrh:Seek(0)
	local ccrh = table.Inherit(ccrh, ccr_table)
	ccrh.BaseClass = nil
	ccrh = table.Inherit(ccrh, buffer)
	ccrh.BaseClass = nil
	return ccrh
end
function ccr.CreateNew()
	return ccr.CreateHandler("\x00\x00\x06CCRF\x00\x00")
end

--===========================================================================--

ccr.base = base
ccr.section = base.section

if SERVER then
	util.AddNetworkString("ccr_protocol")
	function ccr.Reply(who, req, data)
		net.Start("ccr_protocol")
			net.WriteString(req)
			net.WriteTable(data)
		net.Send(who)
	end
	net.Receive("ccr_protocol", function(_, ply)
		if not ply:IsListenServerHost() then return end
		local req = net.ReadString()
		if req == "record" then
			local succ, varg = pcall(function()
				local handle = ccr.CreateNew()
				handle:Record(ply)
				return handle
			end)
			if succ then
				ply.handle = varg
				return ccr.Reply(ply, "record", {"ok"})
			end
			return ccr.Reply(ply, "record", {"fail", varg})
		end
		if req == "stop" then
			local succ, varg = pcall(function()
				ply.handle:Stop()
			end)
			if succ then
				return ccr.Reply(ply, "stop", {"ok"})
			end
			return ccr.Reply(ply, "stop", {"fail", varg})
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
		for k,v in pairs(requests) do
			if v[1] == req then
				v[3](v[1], v[2], net.ReadTable())
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
end

return ccr