local w, h = canvas:attrSize()
local imgPaths = {'resources/javier150x200.jpg', 'resources/pablo150x200.jpg','resources/manuel150x200.jpg','resources/javier150x200.jpg', 'resources/pablo150x200.jpg','resources/manuel150x200.jpg'}
local offsetImgs = 168
local arrowLeft	 = canvas:new('resources/left54x200.png')
local arrowRight = canvas:new('resources/right54x200.png')
local currentIndex = 3



function draw(pImgPaths,pCurrentIndex)

	for i=0, 2 do
		image = canvas:new(pImgPaths[pCurrentIndex - 1 + i ])
		canvas:compose( 126 + i*offsetImgs , 320, image)
	end
	canvas:compose( 54 , 320, arrowLeft)
	canvas:compose( 630 , 320, arrowRight)

end






function handler(evt)
	if evt.class == 'key' and evt.type == 'press' then

		
		canvas:flush()
	end
end



canvas:attrColor('navy')
canvas:clear()
draw(imgPaths,currentIndex)
canvas:flush()