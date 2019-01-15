inspect = require "inspect"
local res, curr

tw = 16
th = 16

rects = {}

love.load = ->
	res = love.graphics.newImage "res/cave.png"

genColor = (seed) ->
	rng = love.math.newRandomGenerator seed
	return { rng\random(0.5), rng\random(0.5), rng\random(0.5), 0.5 }

love.draw = ->
	love.graphics.setColor 1, 1, 1
	love.graphics.draw res

	for num, rect in ipairs rects
		love.graphics.setColor genColor(num)
		love.graphics.rectangle "fill", rect.x * tw, rect.y * th, rect.width * tw, rect.height * th

love.mousepressed = (x, y, t) ->
	print t
	curr = {
		x: math.floor x / tw
		y: math.floor y / th
		width: 1
		height: 1
	}
	table.insert rects, curr

	love.mousemoved = (x, y) ->
		rx = x - curr.x * tw
		ry = y - curr.y * th

		if rx > 0
			curr.width = math.ceil rx / tw
		else
			curr.width = math.floor rx / tw
			-- w = curr.width
			-- curr.x = curr.x - curr.width
			-- curr.width = w

		if ry > 0
			curr.height = math.ceil ry / th
		else
			curr.height = math.floor ry / th
			-- h = curr.height
			-- curr.y = curr.y - curr.height
			-- curr.height = h

	love.mousereleased = -> love.mousemoved = nil
