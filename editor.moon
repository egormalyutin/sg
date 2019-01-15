-- TODO: Update deps script

inspector = require "inspect"
inspect = (...) -> print inspector ...

binser = require "binser"

local res
local resWidth, resHeight

local font

gray =  {}
green = {}

map = {}

mapWidth = 40
mapHeight = 18

mapX = 1
mapY = 9

currBlock = nil
blocks = {}

filePrefix = love.math.random(100, 999)
draft = 0
local path
genPath = -> path = "/home/egorcod/Документы/sad/maps/" .. filePrefix .. "-" .. draft .. ".map"
genPath!

cloneTable = (t) ->
	if type(t) == "table"
		ret = {}
		for name, value in pairs t
			ret[name] = value
		return ret
	else
		return t
		

love.load = ->
	ww, wh = love.graphics.getDimensions!

	font = love.graphics.newFont 12

	love.window.setMode ww, wh, { fullscreen: true }
	res = love.graphics.newImage "res/res.png"
	res\setFilter "nearest", "nearest"
	resWidth, resHeight = res\getDimensions!

	for y = 0, 7
		for x = 0, 3
			table.insert gray, love.graphics.newQuad(
				x * 16
				y * 16
				16, 16
				resWidth, resHeight
			)

			table.insert green, love.graphics.newQuad(
				64 + x * 16
				y * 16
				16, 16
				resWidth, resHeight
			)
	
	gray[2] = nil
	green[2] = nil
	
love.draw = ->
	ww, wh = love.graphics.getDimensions!

	love.graphics.push!
	i = 1
	for y = 0, 7
		for x = 0, 3
			if gray[i] == nil
				i += 1
				continue

			love.graphics.setColor 1, 1, 1
			love.graphics.draw res, gray[i], x * 16, y * 16
			if currBlock and currBlock.id == i
				love.graphics.setColor 1, 0, 0, 0.3
				love.graphics.rectangle "fill", x * 16, y * 16, 16, 16
			i += 1

	love.graphics.translate mapX * 16, mapY * 16
	love.graphics.scale 2
	love.graphics.setColor 1, 1, 1
	love.graphics.rectangle "fill", 0, 0, mapWidth * 16, mapHeight * 16
	
	for block in *blocks
		love.graphics.draw res, gray[block.id], block.x * 16, block.y * 16
	
	love.graphics.pop!

	love.graphics.print path, ww - 10 - font\getWidth(path), 10

love.mousepressed = (x, y, t) ->
	move = (x, y) ->
		if y < mapY * 16
			blockX = 1 + math.floor x / 16
			blockY = math.floor y / 16
			id = blockY * 4 + blockX
			currBlock = {
				id: id
				quad: gray[id]
			}

		else if y > mapY * 16 and x > mapX * 16 and y < (mapY + mapHeight * 2) * 16 and x < (mapX + mapWidth * 2) * 16 and currBlock
			blockX = math.floor (x - mapX * 16) / (2 * 16)
			blockY = math.floor (y - mapY * 16) / (2 * 16)
			blocks[blockX] or= {}
			if t == 2
				-- blocks[blockX][blockY = nil
				return
			else
				table.insert blocks, { id: currBlock.id, x: blockX, y: blockY }
	
	move x, y
	love.mousemoved = move
	love.mousereleased = ->
		love.mousemoved = nil


love.keypressed = (k) ->
	if k == "s"
		data = binser.s blocks
		genPath!

		file = io.open path, "w"
		file\write data
		file\close!

		draft += 1
		genPath!

