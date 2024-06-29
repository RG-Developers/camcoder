if _G.CAMCODER_INCLUDES.base then return _G.CAMCODER_INCLUDES.base end

local buffer = include("camcoder/format/buffer.lua")

local compress_threshold = 512

local ccr_file = {sections={}}
local ccr_section = {buf=nil}

function ccr_section.Create(sID, sSZ, sDT)
	local this = table.Copy(ccr_section)
	this.s_id = sID
	this.s_sz = sSZ
	this.s_dt = sDT
	this.buf = buffer.New()
	this.buf:WriteRAW(sDT)
	return this
end

function ccr_file.FromRAW(raw)
	local this = table.Copy(ccr_file)
	this.buf = buffer.New()
	this.buf:WriteRAW(raw)
	this.buf:Seek(0)
	while this.buf:Tell() < #this.buf.data do
		local sID = this.buf:ReadUINT8()
		local sSZ = this.buf:ReadUINT16()
		local sDT = this.buf:ReadRAW(sSZ-1)
		this.buf:ReadRAW(1)
		this.sections[#this.sections+1] = ccr_section.Create(sID, sSZ, sDT)
	end
	return this
end

function ccr_file.New()
	local this = table.Copy(ccr_file)
	this.buf = buffer.New()
	return this
end

function ccr_file:UpdateData()
	self.buf = buffer.New()
	for _,s in pairs(self.sections) do
		self.buf:WriteUINT8(s.s_id)
		self.buf:WriteUINT16(s.s_sz)
		self.buf:WriteRAW(s.s_dt)
	end
end

_G.CAMCODER_INCLUDES.base = {file=ccr_file, section=ccr_section}
return _G.CAMCODER_INCLUDES.base