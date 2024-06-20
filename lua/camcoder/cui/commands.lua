local preferences = include("camcoder/format/preferences.lua")
local format = include("camcoder/format/ccr_interface.lua")

concommand.Add("camcoder_startrecord", function(ply, cmd, args)
    if not LocalPlayer():IsSuperAdmin() and not preferences.othersrecord then
        print("Server owner disabled ability for others to record")
        return
    end
    print("Requesting record start...")
    format.StartRecord(function()
        print("Now recording...")
    end, function(err)
        print("ERROR: "..err[1])
    end)
end)

concommand.Add("camcoder_stoprecord", function(ply, cmd, args)
    if not LocalPlayer():IsSuperAdmin() and not preferences.othersrecord then
        print("Server owner disabled ability for others to record")
        return
    end
    print("Requesting record stop...")
    format.StopRecord(function()
        print("Stopped recording")
    end, function(err)
        print("ERROR: "..err[1])
    end)
end)

concommand.Add("camcoder_saverecord", function(ply, cmd, args, argsstr)
    if not LocalPlayer():IsSuperAdmin() and not preferences.othersrecord then
        print("Server owner disabled ability for others to record")
        return
    end
    print("Requesting save...")
    format.Save(argsstr, function()
        print("Saved.")
    end, function(err)
        print("ERROR: "..err[1])
    end)
end)

concommand.Add("camcoder_listrecords", function(ply, cmd, args)
    print("Requesting records list...")
    format.ListRecords(function(list)
        for _,file in pairs(list) do
            print(" - [".._.."] "..file)
        end
    end)
end)

concommand.Add("camcoder_downloadrecord", function(ply, cmd, args)
    if LocalPlayer():IsSuperAdmin() then
        print("You do not need this command! It's only used to download records from you.")
        return
    end
    if not preferences.fetchrecords then
        print("Records fetching disabled by server host.")
        return
    end
    print("Fetching record...")
    format.Fetch(rname, function()
        print(rname.." successfully downloaded!")
    end)
end)