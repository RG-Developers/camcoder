local base = include("camcoder/format/ccr_base.lua")

local versions = {
	[0]=include("camcoder/format/ccr_0000.lua")
}

local latest = versions[0]
local cvt = {
	["\0\0"]=0
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

if SERVER then
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
		--if not ply:IsListenServerHost() then return end
		local req = net.ReadString()
		local data = util.JSONToTable(util.Decompress(net.ReadData(net.ReadUInt(16))))
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
			ply.ccr_records = ply.ccr_records or {}
			for _,v in pairs(ply.ccr_records) do pcall(function() v:Stop() end) end
			ply.ccr_records = {}
			local succ, varg = pcall(function()
				for _,f in pairs(data) do
					ply.ccr_records[#ply.ccr_records+1] = ccr.FromRAW(file.Read("camcoder/"..f, "DATA"))
				end
				for _,v in pairs(ply.ccr_records) do v:Play() end
			end)
			if succ then
				return ccr.Reply(ply, "play", {"ok"})
			end
			return ccr.Reply(ply, "play", {"fail", varg})
		end
		if req == "stop_replay" then
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
			local succ, varg = pcall(function()
				ply.ccr_handle:Stop()
			end)
			if succ then
				return ccr.Reply(ply, "stop_record", {"ok"})
			end
			return ccr.Reply(ply, "stop_record", {"fail", varg})
		end
		if req == "save" then
			local succ, varg = pcall(function()
				if not ply.ccr_handle then error("nothing was recorded") end
				if ply.ccr_handle.recording or ply.ccr_handle.replaying then error("recording is being used") end
				file.CreateDir("camcoder")
				file.Write("camcoder/"..ply:Name().."_"..data[1]..".txt", ply.ccr_handle.buf.data)
			end)
			if succ then
				return ccr.Reply(ply, "save", {"ok"})
			end
			return ccr.Reply(ply, "save", {"fail", varg})
		end
		if req == "records" then
			local files,_ = file.Find("camcoder/*", "DATA")
			return ccr.Reply(ply, "records", files)
		end
		if req == "hash" then
			return ccr.Reply(ply, "hash", {util.CRC(file.Read("camcoder/"..data[1]))})
		end
		if req == "fetch" then
			ply.ccr_fetch_cnt = ply.ccr_fetch_cnt or {}
			ply.ccr_fetch_cnt[data[1]] = ccr.FromRAW(file.Read("camcoder/"..data[1]))
			ply.ccr_fetch_cnt[data[1]].buf:Seek(0)
			return ccr.Reply(ply, "fetch", {data[1], ply.ccr_fetch_cnt[data[1]].buf.size})
		end
		if req == "fetch_c" then
			if ply.ccr_fetch_cnt[data[1]].buf:Tell() >= ply.ccr_fetch_cnt[data[1]].buf.size then
				return ccr.Reply(ply, "fetch_c", {"end", "", data[1]})
			end
			local d = ply.ccr_fetch_cnt[data[1]].buf:ReadRAW(1024/4)
			ply.ccr_fetch_cnt[data[1]].buf:ReadRAW(1)
			return ccr.Reply(ply, "fetch_c", {"", d, data[1]})
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
	function ccr.StartRecord(ok_cb, fl_cb)
		ccr.Request("record", {}, function(req, _, reply)
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
					file.Append("camcoder/"..f, reply[2])
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
		if file.Exists("camcoder/"..f, "DATA") then
			ccr.Request("hash", {f}, function(req, _, reply)
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

return ccr