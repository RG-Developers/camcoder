local buffer = include("buffer.lua")

local ccr			= {}
local ccr_table	= {data="", pointer=0}
local ccr_section = {s_id=0, s_sz=0, s_dt="", s_pt=0, s_bf=nil}

--===========================================================================--

local function expect(arg, typ)
	assert(type(arg)==typ, "expected "..typ..", got "..type(arg))
end

--===========================================================================--

function ccr_section.Initialise(sID, sSZ, sDT)
	local ccrs = setmetatable(table.Copy(ccr_section), ccr_section)
	ccrs.s_id = sID
	ccrs.s_sz = sSZ
	ccrs.s_dt = sDT
	ccrs.s_bf = buffer.New()
	ccrs:PrepBuf()
	table.Inherit(ccrs, buffer)
	ccrs.BaseClass = nil
	return ccrs
end

function ccr_section.New(sID)
	expect(sID, "number")

	return ccr_section.Initialise(sID, 0, "")
end

function ccr_section:PrepBuf()
	self.s_bf.WriteRAW = self.WriteRAW
	self.s_bf.ReadRAW = self.ReadRAW
	self.s_bf.Seek = self.Seek
	self.s_bf.Tell = self.Tell
end

function ccr_section:WriteRAW(data)
	expect(data, "string")

	self.s_dt = self.s_dt..data
	self.s_sz = self.s_sz+#data
	self.s_pt = self.s_sz
end

function ccr_section:ReadRAW(amount)
	expect(amount, "number")

	local data = string.sub(self.s_dt, self.s_pt+1, self.s_pt + amount+1)
	self.s_pt = self.s_pt + amount
	return data
end

function ccr_section:Seek(seek_to)
	expect(seek_to, "number")

	self.s_pt = seek_to % #self.s_dt
end

function ccr_section:Tell()
	return self.s_pt
end

function ccr_section:WriteSection(section)
	local sID, sSZ, sDT = section.s_id, section.s_sz, section.s_dt
	local data = string.char(sID) 
	data = data .. string.char((math.floor(sSZ / 256) % 256), (sSZ % 256))
	data = data .. sDT
	self:WriteRAW(data)
end

function ccr_section:ReadSection()
	local sID  = string.byte(self:ReadRAW(1))
	local sSZs = self:ReadRAW(2)
	local sSZb = table.Pack(string.byte(sSZs, 1, #sSZs))
	local sSZ  = sSZb[1] * 256 + sSZb[2]
	local sDT  = self:ReadRAW(sSZ)
	return ccr_section.Initialise(sID, sSZ, sDT)
end

function ccr_section:__tostring()
	return "SECTION(sID="..self.s_id..", sSZ="..self.s_sz..", sDT="..string.format("%q", self.s_dt)..", real_size="..#self.s_dt..")"
end

--===========================================================================--

function ccr_table:WriteRAW(data)
	expect(data, "string")

	self.data = self.data..data
	self.pointer = #self.data
end

function ccr_table:Seek(seek_to)
	expect(seek_to, "number")

	self.pointer = seek_to % #self.data
end

function ccr_table:Tell()
	return self.pointer
end

function ccr_table:ReadRAW(amount)
	expect(amount, "number")

	local data = string.sub(self.data, self.pointer+1, self.pointer + amount+1)
	self.pointer = self.pointer + amount
	return data
end

function ccr_table:ReadSection()
	return ccr_section.ReadSection(self)
end

function ccr_table:WriteSection(section)
	return ccr_section.WriteSection(self, section)
end

function ccr_table.Initialise(data)
	expect(data, "string")

	local ccrh = table.Copy(ccr_table)
	ccrh:WriteRAW(data)
	ccrh:Seek(0)
	return ccrh
end

--===========================================================================--

function ccr.CreateBaseHandler(data)
	expect(data, "string")
	local ccrh = ccr_table.Initialise(data)
	return ccrh
end

ccr.__ccr_table__ = ccr_table
ccr.section = ccr_section

return ccr