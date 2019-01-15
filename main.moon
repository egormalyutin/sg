-- TODO: Update deps script
-- TODO: scale filters

inspector = require "inspect"
inspect = (...) -> print inspector ...

Camera = require "camera"

local res
local resWidth, resHeight
local font
local canvas, linesCanvas
local inventoryBatch
local inventoryHeight

gameWidth  = 400
gameHeight = 300

objects = {}

cell = 16

inventory = {
	{ id: 1, x: 0,  y: 0 }
	{ id: 3, x: 16, y: 0 }
	{ id: 4, x: 32, y: 0 }
	{ id: 33, x: 0, y: 16 }
}

currentItem = nil

fieldWidth  = 400
fieldHeight = 300

offsetX = 0
offsetY = 0
scrollCells = 2

statusHeight = nil

scaleX = 2
scaleY = 2
mapScale = 1

toYesNo = (b) ->
	return if b then "yes" else "no"

layers = {}
currentLayer = nil
currentLayerI = 1

drawLines = ->
	ww, wh = love.graphics.getDimensions!

	love.graphics.push!
	love.graphics.setCanvas linesCanvas
	love.graphics.clear!

	step = cell * mapScale
	love.graphics.setColor 0, 0, 0, 0.3
	x = 0
	while x < ww
		love.graphics.line x, 0, x, wh - statusHeight
		x += step * scaleX

	y = 0
	while y < wh - statusHeight
		love.graphics.line 0, y, ww, y
		y += step * scaleY
	
	love.graphics.setCanvas!
	love.graphics.pop!

drawLayer = (i) ->
	layer = layers[i]
	layer.batch\clear!
	for object in *layer.map
		layer.batch\add objects[object.id].quad, object.x, object.y
	layer.batch\flush!
	
print "wasd/arrows - move" -- +
print "left click - build/edit" -- -+
print "right click - remove" -- -
print "=-/scroll - scale" -- +
print "1..9 - layers" -- -
print "0 - jump to x: 0, y: 0" -- +
print "u - undo" -- -
print "r - redo" -- -
print "n - switch anchor" -- -
print "m - switch mode to edit/build" -- -
print "f - toggle free move" -- -
print "v - view mode" -- -
print "s - save" -- -

aabb = (a, b) ->
	return (
		(b.x + b.width  > a.x and
		 b.y + b.height > a.y and
		 a.x + a.width  > b.x and
		 a.y + a.height > b.y) or

		(b.x + b.width  <= a.x + a.width  and
		 b.x            >= a.x            and
		 b.y            >= a.y            and
		 b.y + b.height <= a.y + a.height) or

		(a.x + a.width  <= b.x + b.width  and
		 a.x            >= b.x            and
		 a.y            >= b.y            and
		 a.y + a.height <= b.y + b.height)
	)

createObject = (id, x, y, w, h) ->
	return {
		id: id

		x: x
		y: y
		width: w
		height: h

		quad: love.graphics.newQuad(
			x, y, w, h
			resWidth, resHeight
		)
	}

love.load = ->
	-- GRAPHICS SETTINGS
	love.graphics.setDefaultFilter "nearest", "nearest"

	-- camera = Camera fieldWidth / 2, (fieldHeight - inventoryHeight) / 2, fieldWidth, fieldHeight - inventoryHeight
	-- camera\setFollowStyle "PLATFORMER"

	canvas = love.graphics.newCanvas fieldWidth, fieldHeight
	linesCanvas = love.graphics.newCanvas fieldWidth * scaleX, fieldHeight * scaleY

	-- RESOURCES

	-- fonts
	font = love.graphics.newFont 12
	statusHeight = font\getHeight! / scaleY

	-- tiles
	res = love.graphics.newImage "res/res.png"
	res\setFilter "nearest", "nearest"
	resWidth, resHeight = res\getDimensions!

	x = 0
	y = 0
	for id = 1, 4*8
		if x == 4
			y += 1
			x = 0

		vx = x * cell
		vy = y * cell
		vw = cell
		vh = cell

		table.insert objects, createObject id, vx, vy, vw, vh

		id += 1
		x  += 1

	objID = #objects + 1
	objects[objID] = createObject objID, 131, 20, 60, 52

	-- BATCH

	for i = 0, 9
		batch = love.graphics.newSpriteBatch res
		layers[i] = { batch: batch, map: {} }

	currentLayer = layers[1]

	inventoryBatch = love.graphics.newSpriteBatch res, nil, "static"
	inventoryBatch\clear!
	inventoryHeight = 0

	for x, item in ipairs inventory
		orig = item
		inventory[x] = objects[item.id]
		item = inventory[x]

		item.inventoryX = orig.x
		item.inventoryY = orig.y

		inventoryBatch\add item.quad, item.inventoryX, item.inventoryY

		down = item.y + item.height
		if down > inventoryHeight
			inventoryHeight = down

	inventoryBatch\flush!
	drawLines!

love.update = ->

love.mousepressed = (mx, my, t) ->
	mx /= scaleX
	my /= scaleY

	if my <= inventoryHeight
		for item in *inventory
			if mx >= item.inventoryX and my >= item.inventoryY and mx <= item.inventoryX + item.width and my <= item.inventoryY + item.height
				currentItem = item
				return
		return


	if currentItem and currentItem.id and t == 1
		onmove = (mx, my) ->
			if my <= inventoryHeight
				-- love.mousemoved = nil
				-- love.mousereleased = nil
				return

			mx /= mapScale
			my /= mapScale

			mx -= offsetX / mapScale
			my -= offsetY / mapScale

			my -= inventoryHeight / mapScale

			x = cell * math.floor mx / cell
			y = cell * math.floor my / cell

			-- TODO: visible map checking

			newMap = {}
			for object in *currentLayer.map
				unless aabb({ x: x, y: y, width: currentItem.width, height: currentItem.height }
					{ x: object.x, y: object.y, width: objects[object.id].width, height: objects[object.id].height })
					table.insert newMap, object
			currentLayer.map = newMap
				
			-- for i, object in ipairs map
				-- if aabb({ x: x, y: y, width: currentItem.width, height: currentItem.height }
					-- { x: object.x, y: object.y, width: objects[currentItem.id].width, height: objects[currentItem.id].height })
					-- table.remove map, i

			table.insert currentLayer.map, { id: currentItem.id, x: x, y: y }
			
			drawLayer currentLayerI


		onmove mx, my

		love.mousemoved = (mx, my) -> onmove mx / 2, my / 2
		love.mousereleased = ->
			love.mousemoved = nil
			love.mousereleased = nil
	
	-- else if t == 2
		-- onmove = (mx, my) ->
			-- if my <= inventoryHeight
				-- -- love.mousemoved = nil
				-- -- love.mousereleased = nil
				-- return

			-- my -= inventoryHeight
			-- x = mx / cell
			-- y = my / cell

			-- -- TODO: visible map checking

			-- for i, object in ipairs map
				-- if (
					-- x >= object.x and
					-- y >= object.y and
					-- x < object.x + objects[object.id].width / cell and
					-- y < object.y + objects[object.id].height / cell
				-- )
					-- table.remove map, i

		-- onmove mx, my

		-- love.mousemoved = (mx, my) -> onmove mx / 2, my / 2
		-- love.mousereleased = ->
			-- love.mousemoved = nil
			-- love.mousereleased = nil

love.keypressed = (key) ->
	if key == "a" or key == "left"
		offsetX += scrollCells * cell
	else if key == "d" or key == "right"
		offsetX -= scrollCells * cell
	else if key == "w" or key == "up"
		offsetY += scrollCells * cell
	else if key == "s" or key == "down"
		offsetY -= scrollCells * cell

	else if key == "="
		return if mapScale >= 5 or mapScale * 1.5 > 5
		mapScale *= 1.5
		drawLines!
	else if key == "-"
		return if mapScale <= 0.5 or mapScale / 1.5 < 0.5
		mapScale /= 1.5
		drawLines!

	else if key == "0"
		offsetX = 0
		offsetY = 0

	-- wtf
	else if key == "1"
		currentLayerI = 1
		currentLayer = layers[1]
	
	else if key == "2"
		currentLayerI = 2
		currentLayer = layers[2]

	else if key == "3"
		currentLayerI = 3
		currentLayer = layers[3]

	else if key == "4"
		currentLayerI = 4
		currentLayer = layers[4]

	else if key == "5"
		currentLayerI = 5
		currentLayer = layers[5]

	else if key == "6"
		currentLayerI = 6
		currentLayer = layers[6]

	else if key == "7"
		currentLayerI = 7
		currentLayer = layers[7]

	else if key == "8"
		currentLayerI = 8
		currentLayer = layers[8]

	else if key == "9"
		currentLayerI = 9
		currentLayer = layers[9]

love.draw = ->
	ww, wh = love.graphics.getDimensions!
	pww, pwh = ww / 2, wh / 2

	love.graphics.push!
	love.graphics.setCanvas canvas
	love.graphics.clear!
	love.graphics.push!

	-- DRAW INVENTORY

	-- TODO: batch it

	-- for y, row in ipairs inventory
		-- for x, item in ipairs row
			-- ax = (x - 1) * cell
			-- ay = (y - 1) * cell
			-- inventoryBatch\add objects[item.id].quad, ax, ay

			-- print "batched"

			-- if currentItem == item
				-- drawCurrent = ->
					-- love.graphics.setcolor 0, 1, 0, 0.5
					-- love.graphics.rectangle "line", ax, ay, cell, cell

	love.graphics.setColor 1, 1, 1, 1
	love.graphics.draw inventoryBatch
	if currentItem
		love.graphics.setColor 0, 1, 0, 0.5
		love.graphics.rectangle "line", currentItem.inventoryX, currentItem.inventoryY, currentItem.width, currentItem.height

	-- DRAW FIELD

	love.graphics.translate 0, inventoryHeight

	love.graphics.setColor 1, 1, 1, 1
	love.graphics.rectangle "fill", 0, 0, pww, pwh - inventoryHeight - statusHeight

	-- DRAW MAP

	love.graphics.push!
	
	love.graphics.setScissor 0, inventoryHeight, ww, pwh - inventoryHeight - statusHeight

	love.graphics.translate offsetX, offsetY
	love.graphics.scale mapScale, mapScale

	love.graphics.setColor 1, 0, 0, 1
	love.graphics.circle "fill", 0, 0, 3 -- zero point

	love.graphics.setColor 1, 1, 1, 1

	for i, layer in ipairs layers
		if i == currentLayerI
			love.graphics.setColor 1, 1, 1, 1
		else
			love.graphics.setColor 1, 1, 1, 0.5

		love.graphics.draw layer.batch

	love.graphics.setScissor!

	love.graphics.pop!

	-- DRAW SCALED WINDOW

	love.graphics.pop!
	love.graphics.setCanvas!
	love.graphics.setColor 1, 1, 1, 1
	love.graphics.setBlendMode "alpha", "premultiplied"
	love.graphics.draw canvas, 0, 0, 0, scaleX, scaleY
	love.graphics.setBlendMode "alpha"
	love.graphics.pop!

	-- DRAW LINES ON FIELD
	love.graphics.push!
	love.graphics.translate 0, inventoryHeight * scaleY
	love.graphics.setColor 1, 1, 1, 1
	love.graphics.setBlendMode "alpha", "premultiplied"
	love.graphics.draw linesCanvas, 0, 0
	love.graphics.setBlendMode "alpha"
	love.graphics.pop!

	-- DRAW STATUS

	love.graphics.setColor 1, 1, 1, 1
	status = ""

	if offsetX == 0
		status ..= "x: 0"
	else
		status ..= "x: " .. -offsetX
	status ..= ", "

	if offsetY == 0
		status ..= "y: 0"
	else
		status ..= "y: " .. -offsetY
	status ..= ", "

	status ..= "layer: " .. currentLayerI

	love.graphics.print status, 0, wh - statusHeight * scaleY

