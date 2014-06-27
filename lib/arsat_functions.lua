require 'lib/utf8'
require 'lib/device_version_management'

------------------------------------------------------------------------

local _fontSet = false
local _nTiresiasLineSpacing = { [14] = 19, [16] = 22, [18] = 24, [20] = 27, [22] = 29, [24] = 32, [30] = 39, [36] = 47 }

------------------------------------------------------------------------
-- _strLen(s)
-- Calcula el largo de una cadena de caracteres UTF-8
-- Parámetros:
-- 	s: cadena de caracteres.
-- Retorno:
-- 	Largo de la cadena 's'.
-- 	
function _strLen(s)
	-- Si el dispositivo utiliza codificación UTF-8
	if _getDeviceStringEncoding() == Encoding.UTF_8 then
		return utf8len(s)
	
	-- Si el dispositivo utiliza codificación Latin1 (o si la codificación es desconocida)
	else
		return #s
	end
end

------------------------------------------------------------------------
-- _strSub(s, startIndex, length)
-- Construye una subcadena de una cadena de strings.
-- Parámetros:
-- 	str: cadena de caracteres.
-- 	startIndex: numérico (opcional). Índice de la cadena 'str' tal que su caracter se corresponderá
-- 						  con el primer carater de la sub-cadena.
-- 	length: numérico (opcional). Largo máximo de la sub-cadena.
-- Retorno:
--	Sub-cadena de la cadena provista, desde el i-ésimo caracter (startIndex) y con largo máximo length
--	
function _strSub(s, startIndex, length)
	startIndex = startIndex or 1
	length = length or _strLen(s)

	-- Si el dispositivo utiliza codificación UTF-8
	if _getDeviceStringEncoding() == Encoding.UTF_8 then
		return utf8sub(s, startIndex, length)
	
	-- Si el dispositivo utiliza codificación Latin1 (o si la codificación es desconocida)
	else
		return string.sub(s, startIndex, startIndex + length - 1)
	end
end

------------------------------------------------------------------------
-- _getDefaultLineSpacing(nFontSize)
-- Calcula el espaciado (por defecto) entre líneas, en pixels.
-- Parámetros:
-- 		nFontSize: numérico.
-- Retorno:
-- 		numérico. Espaciado entre líneas (por defecto) para la font Tiresias.
-- 
function _getDefaultLineSpacing(nFontSize)
	return _nTiresiasLineSpacing[nFontSize]
end

------------------------------------------------------------------------
-- _attrFont(canvas, face, size, style)
-- Esta función reemplaza a canvas:attrFont(face, size, style).
-- Configura la fuente que utilizará el canvas al dibujar texto.
-- Parámetros:
-- 		canvas: de Ginga.
-- 		face: cadena de caracteres. Nombre de la fuente. 
-- 		size: numérico. Tamaño de la fuente. 
-- 		style: cadena de caracteres. Estilo de la fuente (normal, negrita, cursiva, etc).
-- Retorno:
-- 		face, size, style. Mismo retorno que canvas:attrFont() de Ginga.
--
function _attrFont(canvas, face, size, style)
	-- SET
	if face ~= nil and size ~= nil then
		local model = _getAssumedDeviceModel()
		-- UTE 740, KAON y CORADIR tienen problemas con measureText y attrFont
		-- (crashea si se hacen llamadas múltiples a ambas funciones)
		if	model == DeviceModel.STB_UTE_740 or
			model == DeviceModel.STB_KAON_FR9100 or
			model == DeviceModel.STB_CORADIR_3000D then
			if _fontSet then return end
			_fontSet = true
		end
		
		canvas:attrFont(face, size, style)

	-- GET
	else
		
		return canvas:attrFont()
	end
end

------------------------------------------------------------------------
-- _drawText(canvas, x, y, text, lineSpacing)
-- Esta función reemplaza a canvas:drawText(x, y, text).
-- Dibuja el texto en varias líneas, procesando los caracteres de nueva línea '\n'. 
-- Parámetros:
-- 		canvas: de Ginga.
--		x, y: numérico. Posición relativa (x, y) en píxeles en el canvas.
--		text: cadena de caracteres. La cadena a dibujar en el canvas.
--		lineSpacing: numérico. Espacio (pixels) entre líneas.
--
function _drawText(canvas, x, y, text, lineSpacing)
	if lineSpacing == nil then
		local fontFace, fontSize, fontStyle = _attrFont(canvas)
		lineSpacing = _getDefaultLineSpacing(fontSize)
	end

	local line = 0
	for s in string.gmatch(text, "[^\n]+") do
		-- Se le suma 1 a la posición 'y' donde se dibuja ya que en los STB Newtronic
		-- algunos caracteres que tienen tildes ('É', 'Í') de la font Tiresias se dibujan
		-- un pixel por encima del valor provisto para esta coordenada.
		canvas:drawText(x, y + lineSpacing*line + 1, s)
		line = line + 1
	end
end

------------------------------------------------------------------------
-- _buildTextMultiline(canvas, width, height, text, textCanvasLimitReached, lineSpacing)
-- Construye texto dividiéndolo en líneas y asegurando que no superará los límites provistos.
-- Parámetros:
-- 		canvas: de Ginga.
--		width, height: numérico. Ancho y alto límites totales requeridos.
--		text: cadena de caracteres. La cadena a dibujar en el canvas.
--		textCanvasLimitReached: cadena de caracteres. La cadena a dibujar en caso que
--								los límites de ancho y alto sean alcanzados. Esta cadena
--								será agregada al final, justo antes de encontrar los límites
--								requeridos.
--		lineSpacing: numérico. Diferencia de posición vertical entre dos líneas sucesivas del texto.
-- Retorno:
-- 		lista de numéricos. Índices relativos al texto provisto como parámetro.
-- 							El i-ésimo índice de la lista se corresponde con el último
-- 							caracter de la i-ésima línea dibujada. 
-- 
function _buildTextMultiline(canvas, maxWidth, maxHeight, text, textCanvasLimitReached, lineSpacing)

	local fontFace, fontSize, fontStyle = _attrFont(canvas)
	local measureY = _getDefaultLineSpacing(fontSize)
	local measureX = 0
	
	if( measureY > maxHeight ) then
		return nil, -1, -1, {}
	end

	lineSpacing = lineSpacing or measureY
	textCanvasLimitReached = textCanvasLimitReached or ""

	local textAcum = ""
	local measureXAcum = 0
	local measureYAcum = 0
	local spaceMeasure = canvas:measureText(" ")
	local textCLRMeasure = canvas:measureText(textCanvasLimitReached)

	local textLines = {}
	
	local totalTextLength = 0
	
	local retTable = {}

	-- Dividimos el texto por caracteres de nueva línea '\n'
	for textLine in string.gmatch(text, "[^\n]+") do

		-- Iteramos sobre la cadena, separándola por sus caracteres de espacio ' '
		for s in string.gmatch(textLine, "[^ ]+") do
			measureX = canvas:measureText(s)
			
			if( textAcum ~= "" ) then
				measureX = measureX + spaceMeasure
			end
	
			-- Si el ancho límite aún no será excedido,
			-- agregamos la cadena a la línea a dibujar
			if( measureXAcum + measureX <= maxWidth ) then
				if( textAcum == "" ) then
					textAcum = s
				else
					textAcum = textAcum .. " " .. s
					measureX = measureX
				end
	
				measureXAcum = measureXAcum + measureX
	
			-- Si el ancho límite aún no será excedido,
			-- comenzamos una nueva línea
			else
				-- Agregamos la línea a dibujar
				totalTextLength = totalTextLength + _strLen(textAcum) + 1 -- +1 para el espacio entre líneas
				textLines[#textLines + 1] = {width = measureXAcum, text = textAcum}
				retTable[#retTable + 1] = totalTextLength
				
				-- Reiniciamos las variables
				measureXAcum = measureX
				measureYAcum = measureYAcum + lineSpacing
				textAcum = s

				-- Si no caben más líneas en los límites de ancho y alto, terminamos
				if( measureYAcum + measureY > maxHeight ) then
					break
				end
			end
		end
		
		-- Si no caben más líneas en los límites de ancho y alto, terminamos
		if measureYAcum + measureY > maxHeight then
			break
		end
		
		-- Agregamos la línea a dibujar
		totalTextLength = totalTextLength + _strLen(textAcum) + 1 -- +1 para el espacio entre líneas
		textLines[#textLines + 1] = {width = measureXAcum, text = textAcum}
		retTable[#retTable + 1] = totalTextLength

		-- Reiniciamos las variables
		measureYAcum = measureYAcum + lineSpacing
		measureXAcum = 0
		measureX = 0
		textAcum = ""
	end

	-- Si la altura límite fue alcanzada, y aún quedan caracteres por dibujar, 
	-- quitamos palabras del final del texto a dibujar hasta que entre
	-- la cadena que debemos agregar en este caso (parámetro textCanvasLimitReached)
	if totalTextLength < _strLen(text) and textCanvasLimitReached ~= "" then
		local auxIndex = 0
		local line = textLines[#textLines]

		while line.width + textCLRMeasure > maxWidth do
			auxIndex = string.find(line.text:reverse(), " ")
			
			if auxIndex == nil then
				line.text = ""
				line.width = 0
				break
			end
			
			if auxIndex ~= nil then
				totalTextLength = totalTextLength - auxIndex
				auxIndex = #line.text - auxIndex
				line.text = string.sub(line.text, 1, auxIndex)
				line.width = canvas:measureText(line.text)
			end
		end
		
		retTable[#retTable] = totalTextLength
		line.text = line.text .. textCanvasLimitReached
	end
	
	local retText = ""
	local width = 0
	local height = lineSpacing*#textLines

	if #textLines > 0 then
		for i = 1, #textLines do
			local line = textLines[i]

			if i > 1 then
				retText = retText .. '\n'
			end

			retText = retText .. line.text
			width = math.max(width, line.width)
		end
	end

	return retText, width, height, retTable
end

------------------------------------------------------------------------
-- _clear(canvas, x, y, width, height)
-- Esta función reemplaza a canvas:clear(x, y, width, height).
-- Pinta el canvas provisto con el valor de color configurado
-- con la función canvas:attrColor, pero solamente dentro de la
-- región de origen (x, y) y ancho width y alto height relativos
-- al canvas en el que se pintará.
-- Parámetros:
-- 		canvas: de Ginga.
--		x, y: numérico. Origen (punto superior izquierdo) de la región a pintar.
--		width, height: numérico. Dimensiones de la región a pintar.
--
function _clear(canvas, x, y, width, height)
	if(x == nil or y == nil or width == nil or height == nil) then
		canvas:clear()
	else
		if( _getGingaVersion() == GingaVersion.UNKNOWN ) then
			canvas:drawRect('fill', x, y, width, height)
		else
			canvas:clear(x, y, width, height)
		end
	end
end

------------------------------------------------------------------------
-- _attrClip(canvas, x, y, width, height)
-- Esta función reemplaza a canvas:attrClip.
-- Limita el área donde se podrá dibujar en el canvas.
-- Lo que quede por fuera de la región delimitada se cortará, asegurando
-- así que se dibuja solamente dentro de la misma.
-- Parámetros:
-- 		canvas: de Ginga.
--		x, y: numérico. Origen (punto superior izquierdo) de la región a pintar.
--		width, height: numérico. Dimensiones de la región.
--
function _attrClip(canvas, x, y, width, height)
	-- SET
	if x and y and width and height then
		local model = _getAssumedDeviceModel()

		-- Estos dispositivos interpretan los parámetros
		-- del mismo modo que las versiones
		-- de Ginga.ar 2.0 o posteriores
		if( _getGingaVersion() ~= GingaVersion.UNKNOWN or
			model == DeviceModel.STB_KAON_FR9100 or
			model == DeviceModel.STB_CORADIR_1000D ) then

			canvas:attrClip(x, y, width, height)
		else

			canvas:attrClip(x, y, x + width, y + height)
		end
	
	-- GET
	else
		local clipX, clipY, clipW, clipH = canvas:attrClip()
		local model = _getAssumedDeviceModel()

		-- Estos dispositivos interpretan los parámetros
		-- del mismo modo que las versiones
		-- de Ginga.ar 2.0 o posteriores
		if( _getGingaVersion() ~= GingaVersion.UNKNOWN or
			model == DeviceModel.STB_KAON_FR9100 or
			model == DeviceModel.STB_CORADIR_1000D ) then

			return clipX, clipY, clipW, clipH
		else

			return clipX, clipY, clipW - clipX, clipH - clipY
		end
	end
end