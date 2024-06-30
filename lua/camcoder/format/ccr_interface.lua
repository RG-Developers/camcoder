if _G.CAMCODER_INCLUDES.interface then return _G.CAMCODER_INCLUDES.interface end

local base = include("camcoder/format/ccr_base.lua")
local preferences = include("camcoder/format/preferences.lua")

local versions = {
	[0]=include("camcoder/format/ccr_0000.lua")
}

local latest = versions[0]
local cvt = {
	["\0\0"]=0,
}

local ccr = {}

function ccr.FromRAW(raw)
	local f = base.file.FromRAW(raw)
	if f.sections[1].s_id ~= 0 then
		return error("Invalid sID in header: "..f.sections[1].s_id)
	end
	if f.sections[1].s_dt:sub(0, 4) ~= "CCRF" then
		return error("Invalid sDT start in header: "..f.sections[1].s_dt:sub(0, 4))
	end
	local iVR = f.sections[1].s_dt:sub(5)
	local iVRr = cvt[iVR]
	if not iVRr then
		return error("Unknown CCRF version!")
	end
	return versions[iVRr].FromRAW(raw)
end

function ccr.New()
	return latest.New()
end

function ccr.ReadFromFile(path)
	local data = file.Read("camcoder/recordings/"..path)
	local ccrf = ccr.FromRAW(data)
	return ccrf
end

if SERVER then
	hook.Add("ShouldCollide", "camcoder_no_bot_collisions", function(ent1, ent2)
		if preferences.botcollideply and preferences.botcollideall then return end
		if ent1:IsPlayer() and ent2:IsPlayer() and (ent1.camcoder_bot or ent2.camcoder_bot) then return false end
		if preferences.botcollideall then return end
		if (ent1:IsPlayer() and ent1.camcoder_bot) or (ent2:IsPlayer() and ent2.camcoder_bot) then return false end
	end)

	util.AddNetworkString("ccr_protocol")
	util.AddNetworkString("ccr_protocol_u")
	function ccr.Reply(who, req, data)
		net.Start("ccr_protocol")
			net.WriteString(req)
			local d = util.Compress(util.TableToJSON(data))
			net.WriteUInt(#d, 16)
			net.WriteData(d)
		net.Send(who)
	end
	net.Receive("ccr_protocol", function(_, ply)
		--if not ply:IsSuperAdmin() then return end
		local req = net.ReadString()
		local data = util.JSONToTable(util.Decompress(net.ReadData(net.ReadUInt(16))))
		if req == "record" then
			if not preferences.othersrecord and not ply:IsSuperAdmin() then return ccr.Reply(ply, "record", {"fail", "not allowed"}) end
			local succ, varg = pcall(function()
				local handle = ccr.New()
				ply.camcoder_voicepath = data[1]
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
			if not preferences.othersreplay and not ply:IsSuperAdmin() then return ccr.Reply(ply, "play", {"fail", "not allowed"}) end
			ply.ccr_records = ply.ccr_records or {}
			for _,v in pairs(ply.ccr_records) do pcall(function() v:Stop() end) end
			ply.ccr_records = {}
			local succ, varg = pcall(function()
				for _,f in pairs(data) do
					ply.ccr_records[#ply.ccr_records+1] = ccr.ReadFromFile(f)
				end
				for _,v in pairs(ply.ccr_records) do v:Play() end
			end)
			if succ then
				return ccr.Reply(ply, "play", {"ok"})
			end
			return ccr.Reply(ply, "play", {"fail", varg})
		end
		if req == "stop_replay" then
			if not preferences.othersreplay and not ply:IsSuperAdmin() and not ply.ccr_records then return ccr.Reply(ply, "stop_replay", {"fail", "not allowed"}) end
			local succ, varg = pcall(function()
				for k,v in pairs(ply.ccr_records) do
					pcall(function() v:Stop() end)
				end
			end)
			if succ then
				return ccr.Reply(ply, "stop_replay", {"ok"})
			end
			return ccr.Reply(ply, "stop_replay", {"fail", varg})
		end
		if req == "stop_record" then
			if not preferences.othersrecord and not ply:IsSuperAdmin() and not ply.ccr_handle.recording then return ccr.Reply(ply, "record", {"fail", "not allowed"}) end
			local succ, varg = pcall(function()
				ply.ccr_handle:Stop()
			end)
			if succ then
				return ccr.Reply(ply, "stop_record", {"ok"})
			end
			return ccr.Reply(ply, "stop_record", {"fail", varg})
		end
		if req == "save" then
			if not preferences.othersreplay and not ply:IsSuperAdmin() then return ccr.Reply(ply, "save", {"fail", "not allowed"}) end
			local succ, varg = pcall(function()
				if not ply.ccr_handle then error("nothing was recorded") end
				if ply.ccr_handle.recording or ply.ccr_handle.replaying then error("recording is being used") end
				file.CreateDir("camcoder")
				local spname = ply:Name()
				local valid = true
				for i = 1, #spname do
					local c = spname:sub(i,i)
					if bit.band(c:byte(), 128) ~= 0 then
						valid = false
						break
					end
				end
				if not valid and not ply:IsFullyAuthenticated() then
					return error("Could not generate valid filename: "..
						"player name contains non-ASCII and is not authenticated with steam.")
				end
				if not valid then
					spname = ply:SteamID()
				end
				spname = spname:gsub('[\\\'></:%*%?"|]', '_')
				ply.ccr_handle:WriteToFile(spname.."_"..data[1]..".txt")
				return spname.."_"..data[1]..".txt"
			end)
			if succ then
				return ccr.Reply(ply, "save", {"ok", varg})
			end
			return ccr.Reply(ply, "save", {"fail", varg})
		end
		if req == "records" then
			local files,_ = file.Find("camcoder/recordings/*", "DATA")
			return ccr.Reply(ply, "records", files)
		end
		if req == "hash" then
			return ccr.Reply(ply, "hash", {util.CRC(file.Read("camcoder/"..data[1]))})
		end
		if req == "delete" then
			if not preferences.pushrecords and not ply:IsSuperAdmin() then return ccr.Reply(ply, "delete", {}) end
			file.Delete("camcoder/"..data[1])
			return ccr.Reply(ply, "delete", {})
		end
		if req == "fetch" then
			if not preferences.fetchrecords and not ply:IsSuperAdmin() then return ccr.Reply(ply, "fetch", {data[1], 0}) end
			ply.ccr_fetch_cnt = ply.ccr_fetch_cnt or {}
			ply.ccr_fetch_cnt[data[1]] = ccr.ReadFromFile(data[1])
			ply.ccr_fetch_cnt[data[1]].buf:Seek(0)
			return ccr.Reply(ply, "fetch", {data[1], ply.ccr_fetch_cnt[data[1]].buf.size})
		end
		if req == "fetch_c" then
			if not preferences.fetchrecords and not ply:IsSuperAdmin() then return ccr.Reply(ply, "fetch_c", {"end", "", data[1]}) end
			if ply.ccr_fetch_cnt[data[1]].buf:Tell() >= ply.ccr_fetch_cnt[data[1]].buf.size then
				return ccr.Reply(ply, "fetch_c", {"end", "", data[1]})
			end
			local d = ply.ccr_fetch_cnt[data[1]].buf:ReadRAW(1024)
			ply.ccr_fetch_cnt[data[1]].buf:ReadRAW(1)
			return ccr.Reply(ply, "fetch_c", {"", d, data[1]})
		end
		if req == "push" then
			if not preferences.pushrecords and not ply:IsSuperAdmin() then return ccr.Reply(ply, "push", {data[1]}) end
			ply.ccr_push_cnt = ply.ccr_push_cnt or {}
			ply.ccr_push_cnt[data[1]] = ccr.New()
			ply.ccr_push_cnt[data[1]].buf.data = ""
			ply.ccr_push_cnt[data[1]].buf:Seek(0)
			return ccr.Reply(ply, "push", {data[1]})
		end
		if req == "push_c" then
			if not preferences.pushrecords and not ply:IsSuperAdmin() then return ccr.Reply(ply, "push_c", {data[1]}) end
			if data[3] == "end" then
				print("Fetched recording "..data[1].." from "..ply:Name().." with size of "..#ply.ccr_push_cnt[data[1]].buf.data.." bytes...")
				ply.ccr_push_cnt[data[1]]:WriteToFile(data[1])
				return ccr.Reply(ply, "push_c", {data[1]})
			end
			ply.ccr_push_cnt[data[1]].buf:WriteRAW(data[2])
			return ccr.Reply(ply, "push_c", {data[1]})
		end

		if req == "fetch_file" then
			if not preferences.fetchfiles and not ply:IsSuperAdmin() then return ccr.Reply(ply, "fetch_file", {data[1], 0}) end
			ply.ccr_fetch_file_cnt = ply.ccr_fetch_file_cnt or {}
			ply.ccr_fetch_file_cnt[data[1]] = buffer.New()
			ply.ccr_fetch_file_cnt[data[1]]:WriteRAW(file.Read("camcoder/"..data[1]))
			ply.ccr_fetch_file_cnt[data[1]]:Seek(0)
			return ccr.Reply(ply, "fetch_file", {data[1], ply.ccr_fetch_file_cnt[data[1]].size})
		end
		if req == "fetch_file_c" then
			if not preferences.fetchfiles and not ply:IsSuperAdmin() then return ccr.Reply(ply, "fetch_file_c", {"end", "", data[1]}) end
			if ply.ccr_fetch_file_cnt[data[1]]:Tell() >= ply.ccr_fetch_file_cnt[data[1]].size then
				return ccr.Reply(ply, "fetch_file_c", {"end", "", data[1]})
			end
			local d = ply.ccr_fetch_file_cnt[data[1]]:ReadRAW(1024)
			ply.ccr_fetch_file_cnt[data[1]]:ReadRAW(1)
			return ccr.Reply(ply, "fetch_file_c", {"", d, data[1]})
		end
		if req == "push_file" then
			if not preferences.pushfiles and not ply:IsSuperAdmin() then return ccr.Reply(ply, "push_file", {data[1]}) end
			ply.ccr_push_file_cnt = ply.ccr_push_file_cnt or {}
			ply.ccr_push_file_cnt[data[1]] = buffer.New()
			ply.ccr_push_file_cnt[data[1]].data = ""
			ply.ccr_push_file_cnt[data[1]]:Seek(0)
			return ccr.Reply(ply, "push_file", {data[1]})
		end
		if req == "push_file_c" then
			if not preferences.pushfiles and not ply:IsSuperAdmin() then return ccr.Reply(ply, "push_file_c", {data[1]}) end
			if data[3] == "end" then
				print("Fetched file "..data[1].." from "..ply:Name().." with size of "..#ply.ccr_push_file_cnt[data[1]].data.." bytes...")
				file.Write("camcoder/"..data[1], ply.ccr_push_file_cnt[data[1]].data)
				return ccr.Reply(ply, "push_file_c", {data[1]})
			end
			ply.ccr_push_file_cnt[data[1]]:WriteRAW(data[2])
			return ccr.Reply(ply, "push_file_c", {data[1]})
		end
	end)
end

if CLIENT then
	surface.CreateFont("Camcoder_PlayerPreviewFont_Large", {
		font = "Arial",
		size = 72,
	})
	surface.CreateFont("Camcoder_PlayerPreviewFont_Medium", {
		font = "Arial",
		size = 56,
	})
	local requests = {}
	function ccr.Request(req, data, cb)
		requests[#requests+1] = {
			req, data, cb
		}
		net.Start("ccr_protocol")
			net.WriteString(req)
			local d = util.Compress(util.TableToJSON(data))
			net.WriteUInt(#d, 16)
			net.WriteData(d)
		net.SendToServer()
	end
	net.Receive("ccr_protocol_u", function()
		local req = net.ReadString()
		if req == "chat" then
			local ply = net.ReadEntity()
			local msg = net.ReadString()
			chat.AddText(Color(255, 255, 0), ply:Nick():sub(0, #ply:Nick()-3)..": ", Color(255, 255, 255), msg)
		end
		if req == "voiceinit" then
			local ply = net.ReadEntity()
			local path = net.ReadString()
			local start = RealTime()
			ccr.FetchFile(path, function()
				sound.PlayFile("data/camcoder/"..path, "noplay noblock 3d", function(station, errCode, errStr)
					if IsValid(station) then
						station:Play()
						station:Set3DEnabled(true)
						station:SetTime(RealTime() - start)
						station:SetPos(ply:EyePos())
						station:SetVolume(1)
						ply.camcoder_voicechan = station
						hook.Add("Think", tostring(ply.camcoder_voicechan), function()
							if not IsValid(ply) then
								hook.Remove("Think", tostring(station))
								hook.Remove("PostPlayerDraw", tostring(station))
								station:Stop()
								return
							end
							station:SetPos(ply:EyePos())
						end)
						local icon = Material("icon32/unmuted.png")
						hook.Add("PostPlayerDraw", tostring(ply.camcoder_voicechan), function(dply)
							if dply ~= ply then return end
							if ply:GetPos():Distance(EyePos()) > 512 then return end
							local pos = ply:GetPos() + ply:GetUp() * (ply:OBBMaxs().z + 5)
							--pos = pos + Vector( 0, 0, math.cos( CurTime() / 2 ) )
							local angle = (pos - EyePos()):GetNormalized():Angle()
							angle = Angle(0, angle.y, 0)
							--angle.y = angle.y + math.sin(CurTime()) * 10
							angle:RotateAroundAxis(angle:Up(), -90)
							angle:RotateAroundAxis(angle:Forward(), 90)
							local w, h = 64, 64
							cam.Start3D2D(pos, angle, 0.1)
								local l, r = ply.camcoder_voicechan:GetLevel()
								local tot = math.min(1, (l+r))
								surface.SetDrawColor(0, tot*255, 0, 255)
								surface.DrawRect(-w/2, -h/2, w, h)
								surface.SetDrawColor(255, 255, 255, 255)
								surface.SetMaterial(icon)
								surface.DrawTexturedRect(-w/2, -h/2, w, h)
							cam.End3D2D()
						end)
					else
						print("[CAMCODER] Error playing bot voice!", errCode, errStr)
					end
				end)
			end)
		end
		if req == "voicestop" then
			local ply = net.ReadEntity()
			if not ply.camcoder_voicechan then return end
			hook.Remove("Think", tostring(ply.camcoder_voicechan))
			hook.Remove("PostPlayerDraw", tostring(ply.camcoder_voicechan))
			ply.camcoder_voicechan:Stop()
			ply.camcoder_voicechan = nil
		end
	end)
	net.Receive("ccr_protocol", function()
		local req = net.ReadString()
		local ndata = util.JSONToTable(util.Decompress(net.ReadData(net.ReadUInt(16))))
		for k,v in pairs(table.Copy(requests)) do
			if v[1] == req then
				if v[3](v[1], v[2], ndata) ~= false then
					requests[k] = nil
				end
			end
		end
	end)
	function ccr.StartRecord(voicepath, ok_cb, fl_cb)
		ccr.Request("record", {voicepath}, function(req, _, reply)
			if reply[1] == "ok" then
				return ok_cb(reply)
			end
			return fl_cb(reply)
		end)
	end
	function ccr.StopRecord(ok_cb, fl_cb)
		ccr.Request("stop_record", {}, function(req, _, reply)
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
	function ccr.Stop(ok_cb, fl_cb)
		ccr.Request("stop_replay", {}, function(req, _, reply)
			if reply[1] == "ok" then
				return ok_cb(reply)
			end
			return fl_cb(reply)
		end)
	end
	function ccr.ListRecords(cb)
		ccr.Request("records", {}, function(req, _, reply)
			cb(reply)
		end)
	end
	function ccr.Hash(f, cb)
		ccr.Request("hash", {f}, function(req, _, reply)
			cb(reply)
		end)
	end
	function ccr.Delete(fname)
		ccr.Request("delete", {fname}, function(req, _, reply) end)
	end
	function ccr.Push(f, callback)
		local function _push()
			local fil = ccr.ReadFromFile(f)
			notification.AddProgress("UploadRecord_"..f, "Uploading recording "..f.."... 0B done")
			ccr.Request("push", {f}, function(req, _, reply)
				if reply[1] ~= f then return false end
				local done = 0
				local function cb(req, _, reply)
					if reply[1] ~= f then return false end
					if reply[1] == "end" then notification.Kill("UploadRecord_"..f) return callback() end
					local d = fil.buf:ReadRAW(1024)
					fil.buf:ReadRAW(1)
					if fil.buf:Tell() >= #fil.buf.data then
						callback()
						return ccr.Request("push_c", {f, "", "end"}, cb)
					end
					done = done + #d
					ccr.Request("push_c", {f, d, ""}, cb)
				    local done_fmt = done
				    local u = ""
				    for _,unit in pairs({"", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi"}) do
				    	u = unit
				    	if math.abs(done_fmt) < 1024.0 then
				    		break
				    	end
				    	done_fmt = done_fmt / 1024.0
				    end
				    done_fmt = string.format("%.2f", done_fmt)
				    done_fmt = done_fmt..u.."B"
					notification.AddProgress("UploadRecord_"..f, "Uploading recording "..f.."... "..done_fmt.." done", done/size)
				end
				local d = fil.buf:ReadRAW(1024)
				fil.buf:ReadRAW(1)
				done = done + #d
				notification.AddProgress("UploadRecord_"..f, "Uploading recording "..f.."... "..done_fmt.." done", done/size)
				ccr.Request("push_c", {f}, cb)
			end)
		end
		ccr.Hash("recordings/"..f, function(reply)
			if util.CRC(file.Read("camcoder/recordings/"..f)) == reply[1] then
				callback()
				return
			end
			_push()
			return
		end)
	end
	function ccr.Fetch(f, callback)
		local function _fetch()
			notification.AddProgress("DownloadRecord_"..f, "Downloading recording "..f.."... 0B done")
			ccr.Request("fetch", {f}, function(req, _, reply)
				if reply[1] ~= f then return false end
				local size = reply[2]
				local done = 0
				file.Write("camcoder/"..f, "")
				local function cb(req, _, reply)
					if reply[3] ~= f then return false end
					if reply[1] == "end" then notification.Kill("DownloadRecord_"..f) return callback() end
					file.Append("camcoder/recordings/"..f, reply[2])
					done = done + #reply[2]
					ccr.Request("fetch_c", {f}, cb)
				    local done_fmt = done
				    local u = ""
				    for _,unit in pairs({"", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi"}) do
				    	u = unit
				    	if math.abs(done_fmt) < 1024.0 then
				    		break
				    	end
				    	done_fmt = done_fmt / 1024.0
				    end
				    done_fmt = string.format("%.2f", done_fmt)
				    done_fmt = done_fmt..u.."B"
					notification.AddProgress("DownloadRecord_"..f, "Downloading recording "..f.."... "..done_fmt.." done", done/size)
				end
				ccr.Request("fetch_c", {f}, cb)
			end)
		end
		if file.Exists("camcoder/recordings/"..f, "DATA") then
			ccr.Hash("recordings/"..f, function(reply)
				if util.CRC(file.Read("camcoder/recordings/"..f)) == reply[1] then
					callback()
					return
				end
				_fetch()
				return
			end)
			return
		end
		_fetch()
	end
	function ccr.PushFile(f, callback)
		local function _push()
			local fil = buffer.New()
			fil:WriteRAW(file.Read("camcoder/"..f))
			fil:Seek(0)
			notification.AddProgress("UploadFile_"..f, "Uploading file "..f.."... 0B done")
			ccr.Request("push_file", {f}, function(req, _, reply)
				if reply[1] ~= f then return false end
				local done = 0
				local function cb(req, _, reply)
					if reply[1] ~= f then return false end
					if reply[1] == "end" then notification.Kill("UploadFile_"..f) return callback() end
					local d = fil:ReadRAW(1024)
					fil:ReadRAW(1)
					if fil:Tell() >= #fil.data then
						callback()
						return ccr.Request("push_file_c", {f, "", "end"}, cb)
					end
					done = done + #d
					ccr.Request("push_file_c", {f, d, ""}, cb)
				    local done_fmt = done
				    local u = ""
				    for _,unit in pairs({"", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi"}) do
				    	u = unit
				    	if math.abs(done_fmt) < 1024.0 then
				    		break
				    	end
				    	done_fmt = done_fmt / 1024.0
				    end
				    done_fmt = string.format("%.2f", done_fmt)
				    done_fmt = done_fmt..u.."B"
					notification.AddProgress("UploadFile_"..f, "Uploading file "..f.."... "..done_fmt.." done", done/size)
				end
				local d = fil:ReadRAW(1024)
				fil:ReadRAW(1)
				done = done + #d
				notification.AddProgress("UploadRecord_"..f, "Uploading file "..f.."... "..done_fmt.." done", done/size)
				ccr.Request("push_c", {f}, cb)
			end)
		end
		ccr.Hash(f, function(reply)
			if util.CRC(file.Read("camcoder/"..f)) == reply[1] then
				callback()
				return
			end
			_push()
			return
		end)
	end
	function ccr.FetchFile(f, callback)
		local function _fetch()
			notification.AddProgress("DownloadFile_"..f, "Downloading recording "..f.."... 0B done")
			ccr.Request("fetch_file", {f}, function(req, _, reply)
				if reply[1] ~= f then return false end
				local size = reply[2]
				local done = 0
				file.Write("camcoder/"..f, "")
				local function cb(req, _, reply)
					if reply[3] ~= f then return false end
					if reply[1] == "end" then notification.Kill("DownloadFile_"..f) return callback() end
					file.Append("camcoder/"..f, reply[2])
					done = done + #reply[2]
					ccr.Request("fetch_file_c", {f}, cb)
				    local done_fmt = done
				    local u = ""
				    for _,unit in pairs({"", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi"}) do
				    	u = unit
				    	if math.abs(done_fmt) < 1024.0 then
				    		break
				    	end
				    	done_fmt = done_fmt / 1024.0
				    end
				    done_fmt = string.format("%.2f", done_fmt)
				    done_fmt = done_fmt..u.."B"
					notification.AddProgress("DownloadFile_"..f, "Downloading file "..f.."... "..done_fmt.." done", done/size)
				end
				ccr.Request("fetch_file_c", {f}, cb)
			end)
		end
		if file.Exists("camcoder/"..f, "DATA") then
			ccr.Hash(f, function(reply)
				if util.CRC(file.Read("camcoder/"..f)) == reply[1] then
					callback()
					return
				end
				_fetch()
				return
			end)
			return
		end
		_fetch()
	end
end

_G.CAMCODER_INCLUDES.interface = ccr

return ccr