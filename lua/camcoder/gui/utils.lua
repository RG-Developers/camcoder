local function style_button(button)
	button:SetFont("Trebuchet18")
	button:DockMargin(5, 5, 5, 5)
	button:Dock(TOP)
	function button:Paint(w, h)
		if not self:IsEnabled() then
			self:SetTextColor(Color(127, 127, 127))
			draw.RoundedBox(5, 0, 0, w, h, Color(0, 0, 0, 255))
			return
		end
		if self:IsDown() then
			self:SetTextColor(Color(0, 127, 255))
		elseif self:IsHovered() then
			self:SetTextColor(Color(127, 190, 255))
		else
			self:SetTextColor(Color(255, 255, 255))
		end
		draw.RoundedBox(5, 0, 0, w, h, Color(0, 0, 0, 255))
	end
end

local function clear_window(window)
	for _, v in ipairs(window:GetChildren()) do
		local skip = false
		for __,v_ in ipairs(window.OldChildren) do
			if v_ == v then skip = true break end
		end
		if not skip then v:Remove() end
	end
end

local function FormattedTime(seconds)
	local ftime = string.FormattedTime(seconds)
	return string.format("%02i:%02i:%02i.%02i", ftime.h, ftime.m, ftime.s, math.floor(ftime.ms))
end

return {
	FormattedTime=FormattedTime,
	clear_window=clear_window,
	style_button=style_button,
}