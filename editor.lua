local inspector = require("inspect")
local inspect
inspect = function(...)
  return print(inspector(...))
end
local binser = require("binser")
local res
local resWidth, resHeight
local font
local gray = { }
local green = { }
local map = { }
local mapWidth = 40
local mapHeight = 18
local mapX = 1
local mapY = 9
local currBlock = nil
local blocks = { }
local filePrefix = love.math.random(100, 999)
local draft = 0
local path
local genPath
genPath = function()
  path = "/home/egorcod/Документы/sad/maps/" .. filePrefix .. "-" .. draft .. ".map"
end
genPath()
local cloneTable
cloneTable = function(t)
  if type(t) == "table" then
    local ret = { }
    for name, value in pairs(t) do
      ret[name] = value
    end
    return ret
  else
    return t
  end
end
love.load = function()
  local ww, wh = love.graphics.getDimensions()
  font = love.graphics.newFont(12)
  love.window.setMode(ww, wh, {
    fullscreen = true
  })
  res = love.graphics.newImage("res/res.png")
  res:setFilter("nearest", "nearest")
  resWidth, resHeight = res:getDimensions()
  for y = 0, 7 do
    for x = 0, 3 do
      table.insert(gray, love.graphics.newQuad(x * 16, y * 16, 16, 16, resWidth, resHeight))
      table.insert(green, love.graphics.newQuad(64 + x * 16, y * 16, 16, 16, resWidth, resHeight))
    end
  end
  gray[2] = nil
  green[2] = nil
end
love.draw = function()
  local ww, wh = love.graphics.getDimensions()
  love.graphics.push()
  local i = 1
  for y = 0, 7 do
    for x = 0, 3 do
      local _continue_0 = false
      repeat
        if gray[i] == nil then
          i = i + 1
          _continue_0 = true
          break
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(res, gray[i], x * 16, y * 16)
        if currBlock and currBlock.id == i then
          love.graphics.setColor(1, 0, 0, 0.3)
          love.graphics.rectangle("fill", x * 16, y * 16, 16, 16)
        end
        i = i + 1
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
  end
  love.graphics.translate(mapX * 16, mapY * 16)
  love.graphics.scale(2)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("fill", 0, 0, mapWidth * 16, mapHeight * 16)
  for _index_0 = 1, #blocks do
    local block = blocks[_index_0]
    love.graphics.draw(res, gray[block.id], block.x * 16, block.y * 16)
  end
  love.graphics.pop()
  return love.graphics.print(path, ww - 10 - font:getWidth(path), 10)
end
love.mousepressed = function(x, y, t)
  local move
  move = function(x, y)
    if y < mapY * 16 then
      local blockX = 1 + math.floor(x / 16)
      local blockY = math.floor(y / 16)
      local id = blockY * 4 + blockX
      currBlock = {
        id = id,
        quad = gray[id]
      }
    else
      if y > mapY * 16 and x > mapX * 16 and y < (mapY + mapHeight * 2) * 16 and x < (mapX + mapWidth * 2) * 16 and currBlock then
        local blockX = math.floor((x - mapX * 16) / (2 * 16))
        local blockY = math.floor((y - mapY * 16) / (2 * 16))
        blocks[blockX] = blocks[blockX] or { }
        if t == 2 then
          return 
        else
          return table.insert(blocks, {
            id = currBlock.id,
            x = blockX,
            y = blockY
          })
        end
      end
    end
  end
  move(x, y)
  love.mousemoved = move
  love.mousereleased = function()
    love.mousemoved = nil
  end
end
love.keypressed = function(k)
  if k == "s" then
    local data = binser.s(blocks)
    genPath()
    local file = io.open(path, "w")
    file:write(data)
    file:close()
    draft = draft + 1
    return genPath()
  end
end
