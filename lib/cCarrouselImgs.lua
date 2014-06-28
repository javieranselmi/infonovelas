
------------------------------------------------------------------------
-- Constantes
------------------------------------------------------------------------

local k_nMainCanvasW, k_nMainCanvasH = canvas:attrSize()

------------------------------------------------------------------------
-- Declaración de la clase
------------------------------------------------------------------------

CarrouselImgs = {} -- la tabla que representa la clase, que se convertirá luego en la metatabla de la instancia
CarrouselImgs.__index = CarrouselImgs -- las búsquedas fallidas de los métodos de cada instancia deben continuar en la tabla de la clase

------------------------------------------------------------------------
-- Métodos públicos
------------------------------------------------------------------------

function CarrouselImgs.new(pImgPaths,pCurrentIndex)
	local self = setmetatable({}, CarrouselImgs)
	self.tImgPaths = pImgPaths
	self.tCurrentIndex = pCurrentIndex
	self.arrowLeft = canvas:new('resources/left54x200.png')
	self.arrowRight = canvas:new('resources/right54x200.png')
    self.offsetImgs = 168
	print('#####INFO##### Objeto CarrouselImgs instaciado correctamente' )
	
	return self
end

------------------------------------------------------------------------
function CarrouselImgs:currentIndex(value)
	-- SET
	if value then
		self.tCurrentIndex = value
	-- GET
	else
		return self.tCurrentIndex
	end
end

------------------------------------------------------------------------
function CarrouselImgs:reDraw()

	for i=0, 2 do
		image = canvas:new(self.tImgPaths[self.tCurrentIndex - 1 + i ])
		canvas:compose( 126 + i*self.offsetImgs , 320, image)
	end
	canvas:compose( 54 , 320, self.arrowLeft)
	canvas:compose( 630 , 320, self.arrowRight)

	print('#####INFO##### Se ha redibujado un objeto CarrouselImgs.')

end
------------------------------------------------------------------------