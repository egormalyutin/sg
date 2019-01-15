local inspect = require("inspect")
local res, curr
local tw = 16
local th = 16
local rects = { }
love.load = function()
  res = love.graphics.newImage("res/cave.png")
end
local genColor
genColor = function(seed)
  local rng = love.math.newRandomGenerator(seed)
  return {
    rng:random(0.5),
    rng:random(0.5),
    rng:random(0.5),
    0.5
  }
end
love.draw = function()
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(res)
  for num, rect in ipairs(rects) do
    love.graphics.setColor(genColor(num))
    love.graphics.rectangle("fill", rect.x * tw, rect.y * th, rect.width * tw, rect.height * th)
  end
end
love.mousepressed = function(x, y, t)
  print(t)
  curr = {
    x = math.floor(x / tw),
    y = math.floor(y / th),
    width = 1,
    height = 1
  }
  table.insert(rects, curr)
  love.mousemoved = function(x, y)
    local rx = x - curr.x * tw
    local ry = y - curr.y * th
    if rx > 0 then
      curr.width = math.ceil(rx / tw)
    else
      curr.width = math.floor(rx / tw)
    end
    if ry > 0 then
      curr.height = math.ceil(ry / th)
    else
      curr.height = math.floor(ry / th)
    end
  end
  love.mousereleased = function()
    love.mousemoved = nil
  end
end
