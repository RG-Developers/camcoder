local attempts = 0

local dt = {
	title		= "Camcoder",
	icon		= "camcoder/gui/icon.png",
	width		= ScrW()/3,
	height		= ScrH()/2,
	onewindow	= false,
	init		= function(icon, window)
		if game.SinglePlayer() and attempts < 13 then
			attempts = attempts + 1
			
			if attempts > 8 then
				LocalPlayer():ChatPrint("Just "..(14-attempts).." more times!")
			else
				LocalPlayer():ChatPrint("CamCoder is not available in single player sessions!")
			end
			if attempts == 5 then
				LocalPlayer():ChatPrint("You can, hovewer, keep trying...")
			end
			return window:Close()
		end
		if game.SinglePlayer() and attempts == 13 then
			attempts = attempts + 1
			LocalPlayer():ChatPrint("Warranty void! Support is NOT provided for single player session use!!")
		end
		window:SetTitle("Camcoder")
		window:SetSizable(false)
		window:SetPos(ScrW()-window:GetWide(), 0)

		function window:Paint(w, h)
			draw.RoundedBox(5, 0, 0, w, h, Color(0, 0, 0, 250))
			draw.RoundedBox(5, 0, 0, w, 25, Color(0, 0, 0, 255))
		end

		local cc_label = window:Add("DLabel")
		cc_label:SetText("CamCoder")
		cc_label:SetFont("Trebuchet24")
		cc_label:Dock(TOP)

		window.OldChildren = window:GetChildren()

		include("camcoder/gui/menu_main.lua").main_menu(icon, window)
	end
}

list.Set("DesktopWindows", "Camcoder", dt)

concommand.Add("camcoder_gui", function(ply, cmd, args)
    local dframe = vgui.Create("DFrame")
    dframe:SetSize(dt.width, dt.height)
    dframe:MakePopup()
    dt.init(nil, dframe)
end)

surface.CreateFont("camcoder_bigfont", {
	font = "Arial",
	extended = false,
	size = 50,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})