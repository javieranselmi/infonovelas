------------------------------------------------------------------------
-- Class declaration
------------------------------------------------------------------------

List = {} -- la tabla que representa la clase, que se convertirá luego en la metatabla de la instancia
List.__index = List -- las búsquedas fallidas de los métodos de cada instancia deben continuar en la tabla de la clase

------------------------------------------------------------------------
-- Métodos públicos
------------------------------------------------------------------------

function List.new()
	local self = setmetatable({}, List)

	self._table = {}
	self._firstElementIndex = 1
	self._lastElementIndex = 0

	return self
end

------------------------------------------------------------------------
function List:push(e)
	self._lastElementIndex = self._lastElementIndex + 1
	self._table[self._lastElementIndex] = e
end

------------------------------------------------------------------------
function List:pushBack(e)
	self._firstElementIndex = self._firstElementIndex - 1
	self._table[self._firstElementIndex] = e
end

------------------------------------------------------------------------
function List:pop(e)
    if self._firstElementIndex > self._lastElementIndex then error("list is empty") end
    
    local value = self._table[self._lastElementIndex]
    self._table[self._lastElementIndex] = nil
    self._lastElementIndex = self._lastElementIndex - 1
    
    return value
end

------------------------------------------------------------------------
function List:popBack(t)
	if self._firstElementIndex > self._lastElementIndex then error("list is empty") end
	
	local value = self._table[self._firstElementIndex]
	self._table[self._firstElementIndex] = nil
	self._firstElementIndex = self._firstElementIndex + 1
	
	return value
end

------------------------------------------------------------------------
function List:element(index, element)
	-- SET
	if element then
		if index <= 0 or index > self._lastElementIndex - self._firstElementIndex + 1 then error("invalid list index") end
		self._table[self._firstElementIndex + index - 1] = element

	-- GET
	else
		return self._table[self._firstElementIndex + index - 1]

	end
end

------------------------------------------------------------------------
function List:length()
	return self._lastElementIndex - self._firstElementIndex + 1
end

------------------------------------------------------------------------
function List:clear()
	self._table = {}
	self._firstElementIndex = 1
	self._lastElementIndex = 0
end