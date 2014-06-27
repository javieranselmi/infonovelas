require 'lib/arsat_functions'
require 'lib/cComponent'
require 'lib/cList'

------------------------------------------------------------------------
-- Declaración de clase
------------------------------------------------------------------------

ComponentList = {} -- la tabla que representa la clase, que se convertirá luego en la metatabla de la instancia
ComponentList.__index = ComponentList -- las búsquedas fallidas de los métodos de cada instancia deben continuar en la tabla de la clase
setmetatable(ComponentList, {__index = Component}) -- las búsquedas fallidas de los métodos de la clase hija deben continuar en la clase padre

------------------------------------------------------------------------
-- Métodos privados
------------------------------------------------------------------------
local function getComponent(self, nIndex, create)
	if create == nil then create = true end
	local tComponent = self._tComponents:element(nIndex - self._nIndexFirstComponent + 1)

	-- Inicializar componente (pedir al delegado el componente correspondiente)
	if tComponent == nil and create then
		tComponent = self._fComponentFactory(self, nIndex)

		if tComponent ~= nil then
			if nIndex < self._nIndexFirstComponent then
				self._nIndexFirstComponent = nIndex
				self._tComponents:pushBack(tComponent)
			else
				self._tComponents:push(tComponent)
			end
			
			tComponent:parent(self)
		else
			print("WARNING: returned list component is nil.")
		end
	end
	
	return tComponent
end

------------------------------------------------------------------------
local function refreshComponent(self, nIndex)
	local tComponent = self._tComponents:element(nIndex - self._nIndexFirstComponent + 1)

	-- Inicializar componente (pedir al delegado el componente correspondiente)
	if tComponent ~= nil then
		tComponent = self._fComponentFactory(self, nIndex)
		self._tComponents:element(nIndex - self._nIndexFirstComponent + 1, tComponent)
		tComponent:parent(self)
	else
		print("WARNING: tried to replace list component unexistent (index " .. nIndex .. ")")
	end
	
	return tComponent
end

------------------------------------------------------------------------
-- IMPORTANTE: CONSIDERAR QUE removeComponent NO
-- REMUEVE EL UN ELEMENTO DE UN INDICE DE LA LISTA
-- SINO QUE HACE POP DE ATRAS O DE ADELANTE
------------------------------------------------------------------------
local function removeComponent(self, fromBack)
	if fromBack then
		self._tComponents:popBack()
		self._nIndexFirstComponent = self._nIndexFirstComponent + 1
	else
		self._tComponents:pop()
	end
end

------------------------------------------------------------------------
local function prepareComponentsToDraw(self, isGoingForward)
	self._bPrepared = true

	if self._nComponentsCount == 0 then
		return true
	end
	
	local nIndexFirstComponentPrev = self._nIndexFirstComponent

	if self._nSelectedIndex ~= self._nPrevSelectedIndex then
		if getComponent(self, self._nSelectedIndex, false) then
			refreshComponent(self, self._nSelectedIndex)
		end

		if getComponent(self, self._nPrevSelectedIndex, false) then
			refreshComponent(self, self._nPrevSelectedIndex)
		end
	end

	local nHeightAcum = 0
	local nWidthAcum = 0

	local nFirstFitIndex = math.max(self._nSelectedIndex, 1)
	local nLastFitIndex = nFirstFitIndex

	local tFirstComponent = getComponent(self, nFirstFitIndex)
	local nW, nH = tFirstComponent:size()
	nHeightAcum = nHeightAcum + nH
	nWidthAcum = nW
	
	local bFirstComponentFits = nHeightAcum <= self._tMaxSize.h
	
	if not bFirstComponentFits then
		print("WARNING: component height is bigger than the list height.")
	end
	
	local fCheckAndUpdate = function(nIndex)
		if nIndex < 1 or nIndex > self._nComponentsCount then
			return false
		end
		
		local tComponent = getComponent(self, nIndex)
		local nW, nH = tComponent:size()
		nH = nH + self._nInterComponentSpace

		if nHeightAcum + nH <= self._tMaxSize.h and nW <= self._tMaxSize.w then
			nHeightAcum = nHeightAcum + nH
			nWidthAcum = math.max(nW, nWidthAcum)
			return true
		end
		
		return false
	end
	
	local bBackwardsComponentFits = true
	local bForwardsComponentFits = true
	
	if bFirstComponentFits then
		-- Si voy hacia adelante en la lista
		if isGoingForward then
			-- Si existe un elemento siguiente, agrego y acumulo la altura
			bForwardsComponentFits = fCheckAndUpdate(self._nSelectedIndex + 1)
			
			if bForwardsComponentFits then nLastFitIndex = self._nSelectedIndex + 1 end

			-- Si existe un elemento anterior, agrego y acumulo la altura
			bBackwardsComponentFits = fCheckAndUpdate(self._nSelectedIndex - 1)

			if bBackwardsComponentFits then nFirstFitIndex = self._nSelectedIndex - 1 end
	
		-- Si voy hacia atras en la lista
		else
			-- Si existe un elemento anterior, agrego y acumulo la altura
			bBackwardsComponentFits = fCheckAndUpdate(self._nSelectedIndex - 1)
			
			if bBackwardsComponentFits then nFirstFitIndex = self._nSelectedIndex - 1 end

			-- Si existe un elemento siguiente, agrego y acumulo la altura
			bForwardsComponentFits = fCheckAndUpdate(self._nSelectedIndex + 1)

			if bForwardsComponentFits then nLastFitIndex = self._nSelectedIndex + 1 end
		end
	end

	-- Dibujar los anteriores hasta el indice del anterior primero en la ventana
	local i = self._nSelectedIndex - 2
	while bBackwardsComponentFits and i >= nIndexFirstComponentPrev do
		bBackwardsComponentFits = fCheckAndUpdate(i)
		if bBackwardsComponentFits then nFirstFitIndex = i end

		i = i - 1
	end
	
	-- Dibujar los siguientes hasta que no entren mas o hasta el fin de la lista
	i = self._nSelectedIndex + 2
	while bForwardsComponentFits and i <= self._nComponentsCount do
		bForwardsComponentFits = fCheckAndUpdate(i)
		if bForwardsComponentFits then nLastFitIndex = i end

		i = i + 1
	end

	-- Dibujar los anteriores hasta que no entren mas o hasta el inicio de la lista
	local i = nFirstFitIndex - 1
	while bBackwardsComponentFits and i > 0 do
		bBackwardsComponentFits = fCheckAndUpdate(i)
		if bBackwardsComponentFits then nFirstFitIndex = i end

		i = i - 1
	end
	
	-- Eliminamos los componentes sobrantes

	-- Cuando estoy bajando, nIndexFirstComponentPrev <= self._nIndexFirstComponent
	-- Cuando estoy subiendo, nIndexFirstComponentPrev >= self._nIndexFirstComponent
	-- Por eso utilizo el minimo entre los dos para eliminar los sobrantes
	for i = math.min(nIndexFirstComponentPrev, self._nIndexFirstComponent), nFirstFitIndex - 1 do
		if getComponent(self, i, false) then removeComponent(self, true) end
	end

	for i = self._nIndexFirstComponent + self._tComponents:length() - 1, nLastFitIndex + 1, -1 do
		if getComponent(self, i, false) then removeComponent(self, false) end
	end
	
	local newSizeW = 0
	local newSizeH = 0
	for i = nFirstFitIndex, nLastFitIndex do
		local tComponent = getComponent(self, i, false)
		local nW, nH = tComponent:size()
		
		newSizeH = newSizeH + nH
		newSizeW = math.max(newSizeW, nW)
	end
	
	newSizeH = newSizeH + (nLastFitIndex - nFirstFitIndex)*self._nInterComponentSpace
	self._tSize = {w = newSizeW, h = newSizeH}
end

------------------------------------------------------------------------
-- Métodos públicos
------------------------------------------------------------------------

function ComponentList.new()
	local self = setmetatable(Component.new(), ComponentList)

	self._bPrepared = false

	self._tBgColor = {r = 0, g = 0, b = 0, a = 0}

	self._nInterComponentSpace = 0

	self._nSelectedIndex = 0
	self._nPrevSelectedIndex = 0

	self._fComponentFactory = nil
	self._fComponentCount = nil

	self._nComponentsCount = 0

	self._tComponents = List.new()
	self._nIndexFirstComponent = 1
	
	self._bIsGoingForward = false
	
	self._bCiclicSelection = false
	
	self._uArrowUpCanvas = nil
	self._uArrowDownCanvas = nil
	self._nArrowUpCanvasW = nil
	self._nArrowUpCanvasH = nil
	self._nArrowDownCanvasH = nil
	self._nArrowDownCanvasW = nil

	return self
end

------------------------------------------------------------------------
function ComponentList:draw()
	Component.draw(self)
	
	if not self._bPrepared then
		self._nComponentsCount = self._fComponentCount(self)
		prepareComponentsToDraw(self)
	end

	canvas:attrColor(self._tBgColor.r, self._tBgColor.g, self._tBgColor.b, self._tBgColor.a)
	_clear(canvas)

	local nHeightAcum = 0
	local tSelectedComponent = nil
	local nSelectedComponentW, nSelectedComponentH
	
	for nCompIndex = 1, self._tComponents:length() do
		local nIndex = self._nIndexFirstComponent + nCompIndex - 1
		local tComponent = getComponent(self, nIndex, false)
		local nW, nH = tComponent:size()

		-- Posicionar componente y dibujar
		tComponent:position(self._tPos.x, self._tPos.y + nHeightAcum)
		tComponent:draw()
		
		nHeightAcum = nHeightAcum + nH + self._nInterComponentSpace
		
		if nIndex == self._nSelectedIndex and self._uArrowUpCanvas and self._uArrowDownCanvas then
			tSelectedComponent = tComponent
			nSelectedComponentW = nW
			nSelectedComponentH = nH
		end
	end
	
	if tSelectedComponent and self._uArrowUpCanvas and self._uArrowDownCanvas then
		local nX, nY = tSelectedComponent:position()
		
		local nArrowUpX = nX + nSelectedComponentW - self._nArrowUpCanvasW*2
		local nArrowUpY = nY - self._nArrowUpCanvasH - 4

		local nArrowDownX = nArrowUpX
		local nArrowDownY = nY + nSelectedComponentH + 4
		
		if self._nSelectedIndex > 1 then
			_attrClip( canvas, nArrowUpX, nArrowUpY, self._nArrowUpCanvasW, self._nArrowUpCanvasH )
			canvas:compose(nArrowUpX, nArrowUpY, self._uArrowUpCanvas)
		end
		
		if self._nSelectedIndex < self._nComponentsCount then
			_attrClip( canvas, nArrowDownX, nArrowDownY, self._nArrowDownCanvasW, self._nArrowDownCanvasH )
			canvas:compose(nArrowDownX, nArrowDownY, self._uArrowDownCanvas)
		end
	end
end

------------------------------------------------------------------------
function ComponentList:setComponentFactoryFunction( f )
	self._fComponentFactory = f
end

------------------------------------------------------------------------
function ComponentList:setComponentCountFunction( f )
	self._fComponentCount = f
end

------------------------------------------------------------------------
function ComponentList:interComponentSpace(nPixels)
	-- SET
	if nPixels then
		self._nInterComponentSpace = nPixels

	-- GET
	else
		return self._nInterComponentSpace

	end
end

------------------------------------------------------------------------
function ComponentList:backgroundColor( r, g, b, a )
	-- SET
	if r and g and b and a then
		self._tBgColor = {r = r, g = g, b = b, a = a}

	-- GET
	else
		return self._tBgColor.r, self._tBgColor.g, self._tBgColor.b, self._tBgColor.a

	end
end

------------------------------------------------------------------------
function ComponentList:moveNext(redraw)
	if redraw == nil then redraw = true end

	self._nComponentsCount = self._fComponentCount(self)

	if self._nSelectedIndex < self._nComponentsCount then
		self._nPrevSelectedIndex = self._nSelectedIndex 
		self._nSelectedIndex = self._nSelectedIndex + 1

		self._bIsGoingForward = true
		prepareComponentsToDraw(self)

		if redraw then self:draw() end
		
		return true

	elseif self._bCiclicSelection then
		self._bIsGoingForward = false

		self._nPrevSelectedIndex = self._nSelectedIndex 
		self._nSelectedIndex = 1

		self._tComponents:clear()
		self._nIndexFirstComponent = self._nSelectedIndex

		prepareComponentsToDraw(self)

		if redraw then self:draw() end
		
		return true
	end
	
	return false
end

------------------------------------------------------------------------
function ComponentList:moveBack(redraw)
	if redraw == nil then redraw = true end

	self._nComponentsCount = self._fComponentCount(self)
	
	if self._nSelectedIndex > 1 then
		self._nPrevSelectedIndex = self._nSelectedIndex 
		self._nSelectedIndex = self._nSelectedIndex - 1

		self._bIsGoingForward = false
		prepareComponentsToDraw(self)

		if redraw then self:draw() end
		
		return true

	elseif self._bCiclicSelection then
		self._bIsGoingForward = true

		self._nPrevSelectedIndex = self._nSelectedIndex 
		self._nSelectedIndex = self._nComponentsCount

		self._tComponents:clear()
		self._nIndexFirstComponent = self._nSelectedIndex

		prepareComponentsToDraw(self)

		if redraw then self:draw() end
		
		return true
	end
	
	return false
end

------------------------------------------------------------------------
function ComponentList:goto(nIndex, redraw)
	if redraw == nil then redraw = true end

	if nIndex then
		self._nComponentsCount = self._fComponentCount(self)

		if 0 <= nIndex and nIndex <= self._nComponentsCount then
			self._bIsGoingForward = nIndex > self._nSelectedIndex

			self._nPrevSelectedIndex = self._nSelectedIndex 
			self._nSelectedIndex = nIndex

			self._tComponents:clear()
			self._nIndexFirstComponent = self._nSelectedIndex

			prepareComponentsToDraw(self)

			if redraw then self:draw() end
			
			return true
		else
			print("WARNING: component list goto method recieved a wrong index (" .. nIndex .. ")")
		end
	else
		print("WARNING: component list goto method recieved a wrong index (nil)")
	end
	
	return false
end

------------------------------------------------------------------------
function ComponentList:refresh(redraw)
	if redraw == nil then redraw = true end

	self._nComponentsCount = self._fComponentCount(self)

	self._tComponents:clear()
	self._nIndexFirstComponent = self._nSelectedIndex

	prepareComponentsToDraw(self)

	if redraw then self:draw() end
end

------------------------------------------------------------------------
function ComponentList:size()
	if not self._bPrepared then
		self._nComponentsCount = self._fComponentCount(self)
		prepareComponentsToDraw(self)
	end

	return Component.size(self)
end

------------------------------------------------------------------------
function ComponentList:ciclicSelection(bCiclicSelection)
	-- SET
	if bCiclicSelection ~= nil then
		self._bCiclicSelection = bCiclicSelection

	-- GET
	else
		return self._bCiclicSelection

	end
end

------------------------------------------------------------------------
function ComponentList:getComponentCount()
	return self._fComponentCount(self)
end

------------------------------------------------------------------------
function ComponentList:getSelectedIndex()
	return self._nSelectedIndex
end

------------------------------------------------------------------------
function ComponentList:setArrowsCanvas(	uArrowUpCanvas, uArrowDownCanvas, nArrowUpCanvasW, nArrowUpCanvasH, nArrowDownCanvasW, nArrowDownCanvasH )
	-- Flecha arriba
	self._uArrowUpCanvas = uArrowUpCanvas
	
	if nArrowUpCanvasW and nArrowUpCanvasH then
		self._nArrowUpCanvasW, self._nArrowUpCanvasH = nArrowUpCanvasW, nArrowUpCanvasH
	else
		self._nArrowUpCanvasW, self._nArrowUpCanvasH = uArrowUpCanvas:attrSize()
	end
	
	-- Flecha abajo
	self._uArrowDownCanvas = uArrowDownCanvas

	if nArrowDownCanvasW and nArrowDownCanvasH then
		self._nArrowDownCanvasW, self._nArrowDownCanvasH = nArrowDownCanvasW, nArrowDownCanvasH
	else
		self._nArrowDownCanvasW, self._nArrowDownCanvasH = uArrowDownCanvas:attrSize()
	end
end
