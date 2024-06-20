local utils = include("camcoder/gui/utils.lua")
local preferences = include("camcoder/format/preferences.lua")

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

local function pm(icon, window, main_menu_cb)
	window:ShowCloseButton(false)
	window:SetTitle("Camcoder - Preferences")

	local cc_tomenu = mk_btn(window, "Back to main menu", BOTTOM, function()
		utils.clear_window(window)
		main_menu_cb(icon, window)
	end)

	local cc_recordchat = window:Add("DCheckBoxLabel")
	cc_recordchat:SetValue(preferences.recordchat)
	cc_recordchat:SetText("Record chat")
	cc_recordchat:Dock(TOP)
	function cc_recordchat:OnChange(check)
		preferences.recordchat = check
		preferences:Update()
	end
	local cc_othersrecord = window:Add("DCheckBoxLabel")
	cc_othersrecord:SetValue(preferences.othersrecord)
	cc_othersrecord:SetText("Allow others to record")
	cc_othersrecord:Dock(TOP)
	function cc_othersrecord:OnChange(check)
		preferences.othersrecord = check
		preferences:Update()
	end
	local cc_othersreplay = window:Add("DCheckBoxLabel")
	cc_othersreplay:SetValue(preferences.othersreplay)
	cc_othersreplay:SetText("Allow others to replay")
	cc_othersreplay:Dock(TOP)
	function cc_othersreplay:OnChange(check)
		preferences.othersreplay = check
		preferences:Update()
	end
	local cc_fetchrecords = window:Add("DCheckBoxLabel")
	cc_fetchrecords:SetValue(preferences.fetchrecords)
	cc_fetchrecords:SetText("Allow others to fetch records")
	cc_fetchrecords:Dock(TOP)
	function cc_fetchrecords:OnChange(check)
		preferences.fetchrecords = check
		preferences:Update()
	end
	local cc_pushrecords = window:Add("DCheckBoxLabel")
	cc_pushrecords:SetValue(preferences.pushrecords)
	cc_pushrecords:SetText("Allow others to push records")
	cc_pushrecords:Dock(TOP)
	function cc_pushrecords:OnChange(check)
		preferences.pushrecords = check
		preferences:Update()
	end
	local cc_botcollideply = window:Add("DCheckBoxLabel")
	cc_botcollideply:SetValue(preferences.botcollideply)
	cc_botcollideply:SetText("Camcoder bots collide with players")
	cc_botcollideply:Dock(TOP)
	function cc_botcollideply:OnChange(check)
		preferences.botcollideply = check
		preferences:Update()
	end
	local cc_botcollideall = window:Add("DCheckBoxLabel")
	cc_botcollideall:SetValue(preferences.botcollideall)
	cc_botcollideall:SetText("Camcoder bots collide with anything at all")
	cc_botcollideall:Dock(TOP)
	function cc_botcollideall:OnChange(check)
		preferences.botcollideall = check
		preferences:Update()
	end
end

return {menu=pm}