local buffer = {data="", size=0, pointer=0}

local function expect(arg, typ)
	if type(arg)~=typ then debug.Trace() end
	assert(type(arg)==typ, "expected "..typ..", got "..type(arg))
end

local function grab_byte(v)
		return math.floor(v / 256), string.char(math.floor(v) % 256)
end

function buffer.New()
	return table.Copy(buffer)
end

function buffer:WriteRAW(data)
	expect(data, "string")

	self.data = self.data..data
	self.size = self.size+#data
	self.pointer = self.size
end

function buffer:ReadRAW(amount)
	expect(amount, "number")

	local data = string.sub(self.data, self.pointer+1, self.pointer + amount+1)
	self.pointer = self.pointer + amount
	return data
end

function buffer:Seek(seek_to)
	expect(seek_to, "number")

	self.pointer = seek_to % #self.data
end

function buffer:Tell()
	return self.pointer
end

function buffer:WriteUINT8(num)
	expect(num, "number")
	assert(num >= 0 and num < 256 and math.floor(num) == num, num.." is not a valid UINT8")

	self:WriteRAW(string.char(num))
end

function buffer:ReadUINT8()
	local bytes = self:ReadRAW(1)
	return string.byte(bytes)
end

function buffer:WriteUINT16(num)
	expect(num, "number")
	assert(num >= 0 and num < 65536 and math.floor(num) == num, num.." is not a valid UINT16")

	self:WriteRAW(string.char(math.floor(num / 256))..string.char(num % 256))
end

function buffer:ReadUINT16()
	local bytes = self:ReadRAW(2)
	local num = table.Pack(string.byte(bytes, 1, 2))
	return num[1]*256+num[2]
end

function buffer:WriteINT8(num)
	expect(num, "number")
	assert(num >= -128 and num < 128 and math.floor(num) == num, num.." is not a valid INT8")

	num = num + 128
	self:WriteUINT8(num)
end

function buffer:ReadINT8()
	return self:ReadUINT8() - 128
end

function buffer:WriteINT16(num)
	expect(num, "number")
	assert(num >= -32768 and num < 32768 and math.floor(num) == num, num.." is not a valid INT16")

	num = num + 32768
	self:WriteUINT16(num)
end

function buffer:ReadINT16()
	return self:ReadUINT16() - 32768
end

function buffer:WriteSSTRING(str)
	expect(str, "string")
	assert(#str < 256, "string is too long (>=256 chars)")

	self:WriteUINT8(#str)
	self:WriteRAW(str)
end

function buffer:ReadSSTRING()
	local len = self:ReadUINT8()
	local str = self:ReadRAW(len)
	return string.sub(str, 0, len)
end

function buffer:WriteBSTRING(str)
	expect(str, "string")
	assert(#str < 65536, "string is too long (>=65536 chars)")

	self:WriteUINT16(#str)
	self:WriteRAW(str)
end

function buffer:ReadBSTRING()
	local len = self:ReadUINT16()
	local str = self:ReadRAW(len)
	return string.sub(str, 0, len)
end

function buffer:WriteFLOAT32(x)
	expect(x, "number")
	local sign = 0
	if x < 0 then
 		sign = 1;
		x = -x
	end
	local mantissa, exponent = math.frexp(x)
	if x == 0 then
		mantissa = 0;
		exponent = 0
	else
		mantissa = (mantissa * 2 - 1) * 8388608
		exponent = exponent + 126
	end
	local v, byte = ""
	x, byte = grab_byte(mantissa); v = v..byte
	x, byte = grab_byte(x); v = v..byte
	x, byte = grab_byte(exponent * 128 + x); v = v..byte
	x, byte = grab_byte(sign * 128 + x); v = v..byte
	self:WriteRAW(v)
end

function buffer:ReadFLOAT32()
	local x = self:ReadRAW(4)

	local sign = 1
	local mantissa = string.byte(x, 3) % 128
	for i=2, 1, -1 do
		mantissa = mantissa * 256 + string.byte(x, i)
	end
	if string.byte(x, 4) > 127 then
		sign = -1
	end
	local exponent = (string.byte(x, 4) % 128) * 2 + math.floor(string.byte(x, 3) / 128)
	if exponent == 0 then
		return 0
	end
	mantissa = (math.ldexp(mantissa, -23) + 1) * sign
	return math.ldexp(mantissa, exponent - 127)
end

function buffer:WriteFLOAT64(x)
	expect(x, "number")

	local sign = 0
	if x < 0 then 
		sign = 1; 
		x = -x 
	end
	local mantissa, exponent = math.frexp(x)
	if x == 0 then -- zero
		mantissa, exponent = 0, 0
	else
		mantissa = (mantissa * 2 - 1) * 4503599627370496 
		exponent = exponent + 1022
	end
	local v, byte = "" 
	x = mantissa
	for i = 1,6 do
		x, byte = grab_byte(x); v = v..byte
	end
	x, byte = grab_byte(exponent * 16 + x); v = v..byte
	x, byte = grab_byte(sign * 128 + x); v = v..byte

	self:WriteRAW(v)
end

function buffer:ReadFLOAT64()
	local x = self:ReadRAW(8)

	local sign = 1
	local mantissa = string.byte(x, 7) % 16
	for i = 6, 1, -1 do 
		mantissa = mantissa * 256 + string.byte(x, i)
	end
	if string.byte(x, 8) > 127 then
		sign = -1
	end
	local exponent = (string.byte(x, 8) % 128) * 16 + math.floor(string.byte(x, 7) / 16)
	if exponent == 0 then 
		return 0 
	end
	mantissa = (math.ldexp(mantissa, -52) + 1) * sign
	return math.ldexp(mantissa, exponent - 1023)
end

function buffer:WriteVECTOR(vec)
	expect(vec, "Vector")

	self:WriteFLOAT32(vec.x)
	self:WriteFLOAT32(vec.y)
	self:WriteFLOAT32(vec.z)
end

function buffer:ReadVECTOR()
	return Vector(self:ReadFLOAT32(), self:ReadFLOAT32(), self:ReadFLOAT32())
end

function buffer:WriteANGLE(ang)
	expect(ang, "Angle")

	self:WriteFLOAT32(ang.p)
	self:WriteFLOAT32(ang.y)
	self:WriteFLOAT32(ang.r)
end

function buffer:ReadANGLE()
	return Angle(self:ReadFLOAT32(), self:ReadFLOAT32(), self:ReadFLOAT32())
end

function buffer:WriteCOLOR4(clr)
	assert(IsColor(clr), "expected Color, got "..type(clr))
	self:WriteUINT8(clr.r)
	self:WriteUINT8(clr.g)
	self:WriteUINT8(clr.b)
	self:WriteUINT8(clr.a)
end

function buffer:ReadCOLOR4()
	return Color(self:ReadUINT8(), self:ReadUINT8(), self:ReadUINT8(), self:ReadUINT8())
end

function buffer:WriteCOLOR3(clr)
	assert(IsColor(clr), "expected Color, got "..type(clr))
	self:WriteUINT8(clr.r)
	self:WriteUINT8(clr.g)
	self:WriteUINT8(clr.b)
end

function buffer:ReadCOLOR3()
	return Color(self:ReadUINT8(), self:ReadUINT8(), self:ReadUINT8())
end

return buffer