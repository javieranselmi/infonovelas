require 'lib/arsat_functions'

------------------------------------------------------------------------
-- Constantes
------------------------------------------------------------------------

local k_nMainCanvasW, k_nMainCanvasH = canvas:attrSize()

------------------------------------------------------------------------
-- Declaración de la clase
------------------------------------------------------------------------

Component = {} -- la tabla que representa la clase, que se convertirá luego en la metatabla de la instancia
Component.__index = Component -- las búsquedas fallidas de los métodos de cada instancia deben continuar en la tabla de la clase

------------------------------------------------------------------------
-- Métodos públicos
------------------------------------------------------------------------

function Component.new()
	local self = setmetatable({}, Component)

	self._tPos = {x = 0, y = 0}
	self._tSize = {w = 0, h = 0}
	self._tMaxSize = {w = 0, h = 0}
	
	self._tParentComponent = nil
	
	return self
end

------------------------------------------------------------------------
function Component:position(x, y)
	-- SET
	if x and y then
		self._tPos = {x = x, y = y}

	-- GET
	else
		return self._tPos.x, self._tPos.y

	end
end

------------------------------------------------------------------------
function Component:maxSize(width, height)
	-- SET
	if width and height then
		width = math.min(math.floor(width + .5), k_nMainCanvasW)
		height = math.min(math.floor(height + .5), k_nMainCanvasH)
		
		self._tMaxSize = {w = width, h = height}

	-- GET
	else
		return self._tMaxSize.w, self._tMaxSize.h

	end
end

------------------------------------------------------------------------
function Component:size()
	return self._tSize.w, self._tSize.h
end

------------------------------------------------------------------------
function Component:parent(component)
	-- SET
	if component then
		self._tParentComponent = component

	-- GET
	else
		return self._tParentComponent

	end
end

------------------------------------------------------------------------
function Component:draw()
	if self._tParentComponent then
		local nXP, nYP = self._tParentComponent:position()
		local nWP, nHP = self._tParentComponent:maxSize()
		local nX2P = nXP + nWP
		local nY2P = nYP + nHP
		local nX2C = self._tPos.x + self._tMaxSize.w
		local nY2C = self._tPos.y + self._tMaxSize.h
		
		local nX = math.max(nXP, self._tPos.x)
		local nY = math.max(nYP, self._tPos.y)
		local nW = math.min(nX2P, nX2C) - nX
		local nH = math.min(nY2P, nY2C) - nY

		_attrClip( canvas, nX, nY, nW, nH )
		
	else
		_attrClip( canvas, self._tPos.x, self._tPos.y, self._tMaxSize.w, self._tMaxSize.h )

	end
end
