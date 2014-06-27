------------------------------------------------------------------------
Encoding = {
["ISO_8859_1"] = "ISO-8859-1";
["UTF_8"] = "UTF-8";
}

------------------------------------------------------------------------
-- UTF-8:
-- 0xxxxxxx - 1 byte UTF-8 (caracter ASCII)
-- 110yyyxx - Primer byte de un caracter UTF-8 de 2 bytes
-- 1110yyyy - Primer byte de un caracter UTF-8 de 3 bytes
-- 11110zzz - Primer byte de un caracter UTF-8 de 4 bytes
-- 10xxxxxx - Byte interno de un caracter UTF-8 de múltiples bytes
--
local function charLen(byte)
	if 		byte > 240 	then	return 4
	elseif 	byte > 225 	then	return 3
	elseif 	byte > 192 	then 	return 2
	else						return 1
    end
end

------------------------------------------------------------------------
local function charUTF8ToLatin1(char)
	local latin1Char = nil
	local byte = string.byte(char)

	if byte < 0x80 then
		latin1Char = char
	else
		local byte1 = byte
		local byte2 = string.byte(char, 2)

		-- Si tiene conversión a latin1
		if (byte1 == 0xC2 and 0xA0 <= byte2 and byte2 <= 0xBF)
		or (byte1 == 0xC3 and 0x80 <= byte2 and byte2 <= 0xBF) then 

			byte1 = byte1 - 0xC0
			byte2 = byte2 - 0x80
			
			local result = byte1*64 + byte2
			latin1Char = string.char(result)
		end
	end
	
	return latin1Char
end

------------------------------------------------------------------------
local function charUTF8FromLatin1(char)
	local utf8Char = nil
	local byte = string.byte(char)
	
	if byte < 0x80 then
		utf8Char = char
	else
		if byte > 0xBF then
			utf8Char = string.char(0xC3, byte - 0x40) -- 0x40 = (0xBF - 0x80) + 1
		else
			utf8Char = string.char(0xC2, byte)
		end
		
	end
	
	return utf8Char
end

------------------------------------------------------------------------
-- utf8len(s)
-- Calcula el largo de una cadena de caracteres UTF-8
-- Parámetros:
-- 	s: cadena de caracteres.
-- Retorno:
-- 	Largo de la cadena 's'.
-- 	
function utf8len(s)
	local sLen = 0
	local byteIndex = 1
	
	while s and byteIndex <= #s do
		local char = string.byte(s, byteIndex)

	    byteIndex = byteIndex + charLen(char)
	    sLen = sLen + 1
	end
    
    return sLen
end
 
------------------------------------------------------------------------
-- utf8sub(str, startIndex, length)
-- Construye una subcadena de una cadena de strings.
-- Parámetros:
-- 	str: cadena de caracteres.
-- 	startIndex: numérico. Índice de la cadena 'str' tal que su caracter se corresponderá
-- 						  con el primer carater de la sub-cadena.
-- 	length: numérico. Largo máximo de la sub-cadena.
-- Retorno:
--	Sub-cadena de la cadena provista, desde el i-ésimo caracter (startIndex) y con largo máximo length
--	
function utf8sub(str, startIndex, length)
	local strUTF8Len = utf8len(str)

	startIndex = startIndex or 1
	length = length or strUTF8Len

	if startIndex > strUTF8Len then print('///////////// parámetro incorrecto ///////////////') end

	local firstIndex = 1
	local index = 1
	
	while index < startIndex  do
		local char = string.byte(str, firstIndex)
		firstIndex = firstIndex + charLen(char)
		index = index + 1
	end

	local secondIndex = firstIndex
	while length > 0 and index <= strUTF8Len do
		local char = string.byte(str, secondIndex)
		secondIndex = secondIndex + charLen(char)
		index = index + 1
		length = length - 1
	end
	
	return str:sub(firstIndex, secondIndex - 1)
end

------------------------------------------------------------------------
-- utf8ToLatin1(char)
-- Convierte una cadena de caracteres codificados en UTF-8 a codificación Latin1
-- Parámetros:
-- 	s: cadena de caracteres en UTF-8
-- Retorno:
-- 	Cadena codificada en Latin1

function utf8ToLatin1(s)
	if s == nil then
		return nil
	end
	
	local str = ""
	local byteIndex = 1
	
	while byteIndex <= #s do
		local char = string.byte(s, byteIndex)
		local charLen = charLen(char)
		
		local utf8Char = s.sub(byteIndex, byteIndex + charLen)
		str = str .. charUTF8ToLatin1(utf8Char)
		
	    byteIndex = byteIndex + charLen
	end
	
	return str
end

------------------------------------------------------------------------
-- utf8FromLatin1(char)
-- Convierte una cadena de caracteres codificados en Latin1 a codificación UTF-8
-- Parámetros:
-- 	s: cadena de caracteres en Latin1
-- Retorno:
-- 	Cadena codificada en UTF-8

function utf8FromLatin1(s)
	if s == nil then
		return nil
	end
	
	local str = ""
	s:gsub(".", function(c)
		str = str .. charUTF8FromLatin1(c)
	end)
	
	return str
end

------------------------------------------------------------------------
