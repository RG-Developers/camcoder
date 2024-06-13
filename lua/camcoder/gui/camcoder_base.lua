list.Set("DesktopWindows", "Camcoder", {
	title		= "Camcoder",
	icon		= "camcoder/gui/icon.png",
	width		= ScrW()/3,
	height		= ScrH(),
	onewindow	= true,
	init		= function(icon, window)
		if game.SinglePlayer() then
			LocalPlayer():ChatPrint("CamCoder is not available in single player sessions!")
			return window:Close()
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
})