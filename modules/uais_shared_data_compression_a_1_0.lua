
-- Pending: Must check 6-bit integer com << >> decom, decom probably not working, and Base85ToNumber...

module_table = {}

local char_table = { -- NOTE: Unicode character set (Available: 32 <-> 126 [All] & 160 <-> 255 [confirmed: 160 <-> 176])
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
	"k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
	"u", "v", "w", "x", "y", "z", "A", "B", "C", "D",
	"E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
	"O", "P", "Q", "R", "S", "T", "U", "V", "W", "X",
	"Y", "Z", "!", "+", "#", "$", "%", "&", "~", "(",
	")", "=", ",", "*", ".", ":", "-", "_", "<", ">",
	"{", "}", "[", "]", "?"
}

local nums_table = {} -- TESTING: Filled manually...

-- Functions

function LoadCharValuesTable() -- NOTE: OnScriptLoad (SAPP) / OnGameStart (Chimera)
	if #nums_table == 0 then
		for k, v in pairs(char_table) do
			nums_table[v] = k - 1
		end
	end
end

-- Compression functions

function Integer6ToPrintableChar(Value, Table) -- 0 <= Value <= 63 / NOTE: Can accept either a number or a 6 bit (0/1) table.
	--[[ Used for:
		- 6-bit bitmasks (Big endian)
		- Positive integers smaller than 64
	--]]
	local char
	if Table then
		char = string.format("%c", tonumber(table.concat(Table), 2) + 32)
	else -- Added
		char = string.char(Value + 32)
	end
	return char
end

function Word16ToHex(Value) -- 0 <= Value <= 65535
	--[[ Used for:
		- Object indexes
		- Animation IDs 
	--]]
	local raw_hex = string.format("%x", Value)
	local hex = string.sub("0000"..raw_hex, -4, -1)
	return hex
end

function Dword32ToBase85(Value) -- NOTE: Testing, compress long number to a 5 char string...
	local q = Value
	local e = 0
	local d = 0
	local c = 0
	local b = 0
	local a = 0
	local base85 = nil
	while q > (51586500 + 606900 + 7140 + 84) do -- Tens of thousands
		q = q - 52200625
		e = e + 1
	end
	while q > (606900 + 7140 + 84) do -- Thousands
		q = q - 614125
		d = d + 1
	end
	while q > (7140 + 84) do -- Hundreds
		q = q - 7225
		c = c + 1
	end
	while q > 84 do -- Tens
		q = q - 85
		b = b + 1
	end
	a = q -- Units
	e = char_table[(e + 1)]
	d = char_table[(d + 1)]
	c = char_table[(c + 1)]
	b = char_table[(b + 1)]
	a = char_table[(a + 1)]
	base85 = e..d..c..b..a -- NOTE: Could be improved, using a table and performing "concat" instead of individual variables
	return base85
end

-- Decompression functions

function PrintableCharToInteger6(String, IsTable) -- NOTE: If "IsTable" is true, then returns a 6 bit (0/1) bitmask.
	local num = string.byte(String) - 32
	if IsTable then
		local bitmask = {0, 0, 0, 0, 0 ,0} -- NOTE: Big endian. Decimal to binary conversion.
		local bit_index = 0
		local q = num
		local m
		while q > 0 do
			m = q % 2
			q = math.floor(q/2)
			bitmask[6 - bit_index] = m
			bit_index = bit_index + 1
		end
		return bitmask
	end
	return num
end

function HexToNumber(String)
	local num = tonumber(String, 16)
	return num
end

function Base85ToNumber(String)
	local num = 0
	local e = nums_table[string.sub(String, 1, 1)]
	local d = nums_table[string.sub(String, 2, 2)]
	local c = nums_table[string.sub(String, 3, 3)]
	local b = nums_table[string.sub(String, 4, 4)]
	local a = nums_table[string.sub(String, 5, 5)]

	num = e * 52200625 + d * 614125 + c * 7225 + b * 85 + a
	return num
end

-- Math functions

function Dword32ToFloat(Value)
	local binary = {0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0} -- NOTE: Stored in big endian.
	local bit_index = 0
	local q = Value
	local m
	while q > 0 do
		m = q % 2
		q = math.floor(q/2)
		binary[32 - bit_index] = m
		bit_index = bit_index + 1
	end
	local b_sign = binary[1]
	local b_exponent = -127
	local b_mantissa = 1
	for i = 1, 8 do -- Calculate exponent.
		local bit_value = 2 ^ (8 - i)
		if binary[i + 1] == 1 then
			b_exponent = b_exponent + bit_value
		end
	end
	for i = 1, 23 do -- Calculate mantissa.
		local bit_value = 2 ^ (-i)
		if binary[i + 9] == 1 then
			b_mantissa = b_mantissa + bit_value
		end
	end
	local float = (-1) ^ b_sign * 2 ^ b_exponent * b_mantissa
	return float
end

-- Module setup

module_table.LoadCharValuesTable = LoadCharValuesTable

module_table.Integer6ToPrintableChar = Integer6ToPrintableChar
module_table.Word16ToHex = Word16ToHex
module_table.Dword32ToBase85 = Dword32ToBase85

module_table.PrintableCharToInteger6 = PrintableCharToInteger6
module_table.HexToNumber = HexToNumber
module_table.Base85ToNumber = Base85ToNumber

module_table.Dword32ToFloat = Dword32ToFloat

return module_table