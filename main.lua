require 'lib/cCarrouselImgs'


local w, h = canvas:attrSize()
local imgPaths = {'resources/javier150x200.jpg', 'resources/pablo150x200.jpg','resources/manuel150x200.jpg','resources/javier150x200.jpg', 'resources/pablo150x200.jpg','resources/manuel150x200.jpg'}
local currentIndex = 2
local idx = currentIndex


carrousel = CarrouselImgs.new(imgPaths,currentIndex)
carrousel:currentIndex(5)
print("CURRENT INDEX DEL OBJETO CREADOOOOOOOOOOOOOOOOO:" .. carrousel:currentIndex())

canvas:attrColor('navy')
canvas:clear()

function redibujar()

	idx = idx + 1
	carrousel:currentIndex(idx)
	carrousel:reDraw()
	canvas:flush()
	event.timer(1000,redibujar)

end

redibujar()
canvas:flush()