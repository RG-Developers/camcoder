if _G.CAMCODER_INCLUDES.preferences then return _G.CAMCODER_INCLUDES.preferences end

if SERVER then util.AddNetworkString("camcoder_preferences") end

local prefs = {}

if SERVER then
	net.Receive("camcoder_preferences", function(_, ply)
		if not ply:IsSuperAdmin() then return end
		local p_raw = net.ReadString()
		local p = util.JSONToTable(p_raw)
		prefs.recordchat = p.recordchat
		prefs.othersrecord = p.othersrecord
		prefs.othersreplay = p.othersreplay
		prefs.fetchrecords = p.fetchrecords
		prefs.pushrecords = p.pushrecords
		prefs.botcollideply = p.botcollideply
		prefs.botcollideall = p.botcollideall
		prefs:Update()
	end)
else
	net.Receive("camcoder_preferences", function()
		local p_raw = net.ReadString()
		local p = util.JSONToTable(p_raw)
		prefs.recordchat = p.recordchat
		prefs.othersrecord = p.othersrecord
		prefs.othersreplay = p.othersreplay
		prefs.fetchrecords = p.fetchrecords
		prefs.pushrecords = p.pushrecords
		prefs.botcollideply = p.botcollideply
		prefs.botcollideall = p.botcollideall
	end)
end

function prefs:Update()
	if CLIENT and not IsValid(LocalPlayer()) then return end
	if CLIENT and not LocalPlayer():IsSuperAdmin() then return end
	local p_raw = util.TableToJSON({
		recordchat=self.recordchat,
		othersrecord=self.othersrecord,
		othersreplay=self.othersreplay,
		fetchrecords=self.fetchrecords,
		pushrecords=self.pushrecords,
		botcollideply=self.botcollideply,
		botcollideall=self.botcollideall,
	})
	if SERVER then
		file.Write("camcoder_preferences.txt", p_raw)
	end
	net.Start("camcoder_preferences")
		net.WriteString(p_raw)
	if CLIENT then net.SendToServer() else net.Broadcast() end
end
function prefs:Read()
	local p_raw = file.Read("camcoder_preferences.txt") or "{}"
	local p = util.JSONToTable(p_raw) or {}
	if p.recordchat == nil then p.recordchat = true end
	if p.othersrecord == nil then p.othersrecord = false end
	if p.othersreplay == nil then p.othersreplay = false end
	if p.fetchrecords == nil then p.fetchrecords = false end
	if p.pushrecords == nil then p.pushrecords = false end
	if p.botcollideply == nil then p.botcollideply = true end
	if p.botcollideall == nil then p.botcollideall = true end
	self.recordchat = p.recordchat
	self.othersrecord = p.othersrecord
	self.othersreplay = p.othersreplay
	self.fetchrecords = p.fetchrecords
	self.pushrecords = p.pushrecords
	self.botcollideply = p.botcollideply
	self.botcollideall = p.botcollideall
end

prefs:Read()
prefs:Update()

timer.Create("PeriodicalSyncSettings", 10, -1, function()
	prefs:Update()
end)

_G.CAMCODER_INCLUDES.preferences = prefs

return prefs