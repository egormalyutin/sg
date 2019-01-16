local inspector = require("inspect")
local inspect
inspect = function(...)
  return print(inspector(...))
end
local Camera = require("camera")
local res
local resWidth, resHeight
local font
local canvas, linesCanvas
local inventoryBatch, inventoryCanvas
local inventoryHeight
local gameWidth = 400
local gameHeight = 300
local objects = { }
local cell = 16
local inventory = {
  {
    id = 1,
    x = 0,
    y = 0
  },
  {
    id = 3,
    x = 16,
    y = 0
  },
  {
    id = 4,
    x = 32,
    y = 0
  },
  {
    id = 33,
    x = 0,
    y = 16
  }
}
local currentItem = nil
local fieldWidth = 400
local fieldHeight = 300
local offsetX = 0
local offsetY = 0
local scrollCells = 2
local statusHeight = nil
local scaleX = 2
local scaleY = 2
local mapScale = 1
local toYesNo
toYesNo = function(b)
  if b then
    return "yes"
  else
    return "no"
  end
end
local layers = { }
local currentLayer = nil
local currentLayerI = 1
local mode = "build"
local lastMode = "build"
local drawLines
drawLines = function()
  local ww, wh = love.graphics.getDimensions()
  love.graphics.push()
  love.graphics.setCanvas(linesCanvas)
  love.graphics.clear()
  local step = cell * mapScale
  love.graphics.setColor(0, 0, 0, 0.3)
  local x = 0
  while x < ww do
    love.graphics.line(x, 0, x, wh - statusHeight)
    x = x + (step * scaleX)
  end
  local y = 0
  while y < wh - statusHeight do
    love.graphics.line(0, y, ww, y)
    y = y + (step * scaleY)
  end
  love.graphics.setCanvas()
  return love.graphics.pop()
end
local drawLayer
drawLayer = function(i)
  local layer = layers[i]
  layer.batch:clear()
  local _list_0 = layer.map
  for _index_0 = 1, #_list_0 do
    local object = _list_0[_index_0]
    layer.batch:add(objects[object.id].quad, object.x, object.y)
  end
  return layer.batch:flush()
end
local drawInventory
drawInventory = function()
  love.graphics.push()
  love.graphics.setCanvas(inventoryCanvas)
  love.graphics.clear()
  love.graphics.draw(inventoryBatch)
  if currentItem then
    love.graphics.setColor(0, 1, 0, 0.5)
    love.graphics.rectangle("line", currentItem.inventoryX, currentItem.inventoryY, currentItem.width, currentItem.height)
  end
  love.graphics.setCanvas()
  return love.graphics.pop()
end
print("wasd/arrows - move")
print("left click - build/edit")
print("right click - remove")
print("=-/scroll - scale")
print("1..9 - layers")
print("0 - jump to x: 0, y: 0")
print("u - undo")
print("r - redo")
print("n - switch anchor")
print("m - switch mode to edit/build")
print("ctrl - move by y in edit mode")
print("y - copy in edit mode")
print("shift - move by x in edit mode")
print("p - paste in edit mode")
print("f - toggle free move")
print("v - view mode")
print("s - save")
local aabb
aabb = function(a, b)
  return ((b.x + b.width > a.x and b.y + b.height > a.y and a.x + a.width > b.x and a.y + a.height > b.y) or (b.x + b.width <= a.x + a.width and b.x >= a.x and b.y >= a.y and b.y + b.height <= a.y + a.height) or (a.x + a.width <= b.x + b.width and a.x >= b.x and a.y >= b.y and a.y + a.height <= b.y + b.height))
end
local createObject
createObject = function(id, x, y, w, h)
  return {
    id = id,
    x = x,
    y = y,
    width = w,
    height = h,
    quad = love.graphics.newQuad(x, y, w, h, resWidth, resHeight)
  }
end
love.load = function()
  local ww, wh = love.graphics.getDimensions()
  love.graphics.setDefaultFilter("nearest", "nearest")
  canvas = love.graphics.newCanvas(fieldWidth, fieldHeight)
  linesCanvas = love.graphics.newCanvas(fieldWidth * scaleX, fieldHeight * scaleY)
  font = love.graphics.newFont(12)
  statusHeight = font:getHeight() / scaleY
  res = love.graphics.newImage("res/res.png")
  res:setFilter("nearest", "nearest")
  resWidth, resHeight = res:getDimensions()
  local x = 0
  local y = 0
  for id = 1, 4 * 8 do
    if x == 4 then
      y = y + 1
      x = 0
    end
    local vx = x * cell
    local vy = y * cell
    local vw = cell
    local vh = cell
    table.insert(objects, createObject(id, vx, vy, vw, vh))
    id = id + 1
    x = x + 1
  end
  local objID = #objects + 1
  objects[objID] = createObject(objID, 131, 20, 60, 52)
  for i = 0, 9 do
    local batch = love.graphics.newSpriteBatch(res)
    layers[i] = {
      batch = batch,
      map = { }
    }
  end
  currentLayer = layers[1]
  inventoryBatch = love.graphics.newSpriteBatch(res, nil, "static")
  inventoryBatch:clear()
  inventoryHeight = 0
  for x, item in ipairs(inventory) do
    local orig = item
    inventory[x] = objects[item.id]
    item = inventory[x]
    item.inventoryX = orig.x
    item.inventoryY = orig.y
    inventoryBatch:add(item.quad, item.inventoryX, item.inventoryY)
    local down = item.y + item.height
    if down > inventoryHeight then
      inventoryHeight = down
    end
  end
  inventoryBatch:flush()
  inventoryCanvas = love.graphics.newCanvas(ww, inventoryHeight)
  love.graphics.setCanvas(inventoryCanvas)
  love.graphics.draw(inventoryBatch)
  love.graphics.setCanvas()
  return drawLines()
end
love.update = function() end
love.mousepressed = function(mx, my, t)
  mx = mx / scaleX
  my = my / scaleY
  if my <= inventoryHeight then
    for _index_0 = 1, #inventory do
      local item = inventory[_index_0]
      if mx >= item.inventoryX and my >= item.inventoryY and mx <= item.inventoryX + item.width and my <= item.inventoryY + item.height then
        currentItem = item
        drawInventory()
        return 
      end
    end
    drawInventory()
    return 
  end
  if currentItem and currentItem.id and t == 1 then
    local onmove
    onmove = function(mx, my)
      if my <= inventoryHeight then
        return 
      end
      mx = mx / mapScale
      my = my / mapScale
      mx = mx - math.floor(offsetX / mapScale)
      my = my - math.floor(offsetY / mapScale)
      my = my - (inventoryHeight / mapScale)
      local x = cell * math.floor(mx / cell)
      local y = cell * math.floor(my / cell)
      local newMap = { }
      local _list_0 = currentLayer.map
      for _index_0 = 1, #_list_0 do
        local object = _list_0[_index_0]
        if not (aabb({
          x = x,
          y = y,
          width = currentItem.width,
          height = currentItem.height
        }, {
          x = object.x,
          y = object.y,
          width = objects[object.id].width,
          height = objects[object.id].height
        })) then
          table.insert(newMap, object)
        end
      end
      currentLayer.map = newMap
      table.insert(currentLayer.map, {
        id = currentItem.id,
        x = x,
        y = y
      })
      return drawLayer(currentLayerI)
    end
    onmove(mx, my)
    love.mousemoved = function(mx, my)
      return onmove(mx / scaleX, my / scaleY)
    end
    love.mousereleased = function()
      love.mousemoved = nil
      love.mousereleased = nil
    end
    return 
  end
  if currentItem and currentItem.id and t == 2 then
    local onmove
    onmove = function(mx, my)
      if my <= inventoryHeight then
        return 
      end
      mx = mx / mapScale
      my = my / mapScale
      mx = mx - math.floor(offsetX / mapScale)
      my = my - math.floor(offsetY / mapScale)
      my = my - (inventoryHeight / mapScale)
      local x = cell * math.floor(mx / cell)
      local y = cell * math.floor(my / cell)
      local newMap = { }
      local _list_0 = currentLayer.map
      for _index_0 = 1, #_list_0 do
        local object = _list_0[_index_0]
        if not (aabb({
          x = x,
          y = y,
          width = 1,
          height = 1
        }, {
          x = object.x,
          y = object.y,
          width = objects[object.id].width,
          height = objects[object.id].height
        })) then
          table.insert(newMap, object)
        end
      end
      currentLayer.map = newMap
      return drawLayer(currentLayerI)
    end
    onmove(mx, my)
    love.mousemoved = function(mx, my)
      return onmove(mx / scaleX, my / scaleY)
    end
    love.mousereleased = function()
      love.mousemoved = nil
      love.mousereleased = nil
    end
    return 
  end
end
love.keypressed = function(key)
  if key == "a" or key == "left" then
    offsetX = offsetX + (mapScale * scrollCells * cell)
  else
    if key == "d" or key == "right" then
      offsetX = offsetX - (mapScale * scrollCells * cell)
    else
      if key == "w" or key == "up" then
        offsetY = offsetY + (mapScale * scrollCells * cell)
      else
        if key == "s" or key == "down" then
          offsetY = offsetY - (mapScale * scrollCells * cell)
        else
          if key == "=" then
            if mapScale >= 2 then
              return 
            end
            mapScale = mapScale + 0.5
            local val = mapScale * scrollCells * cell
            offsetX = val * math.floor(offsetX / val)
            offsetY = val * math.floor(offsetY / val)
            return drawLines()
          else
            if key == "-" then
              if mapScale <= 0.5 then
                return 
              end
              mapScale = mapScale - 0.5
              local val = mapScale * scrollCells * cell
              offsetX = val * math.floor(offsetX / val)
              offsetY = val * math.floor(offsetY / val)
              return drawLines()
            else
              if key == "0" then
                offsetX = 0
                offsetY = 0
              else
                if key == "v" then
                  if mode == "view" then
                    mode = lastMode
                    lastMode = "view"
                  else
                    lastMode = mode
                    mode = "view"
                  end
                else
                  if key == "1" then
                    currentLayerI = 1
                    currentLayer = layers[1]
                  else
                    if key == "2" then
                      currentLayerI = 2
                      currentLayer = layers[2]
                    else
                      if key == "3" then
                        currentLayerI = 3
                        currentLayer = layers[3]
                      else
                        if key == "4" then
                          currentLayerI = 4
                          currentLayer = layers[4]
                        else
                          if key == "5" then
                            currentLayerI = 5
                            currentLayer = layers[5]
                          else
                            if key == "6" then
                              currentLayerI = 6
                              currentLayer = layers[6]
                            else
                              if key == "7" then
                                currentLayerI = 7
                                currentLayer = layers[7]
                              else
                                if key == "8" then
                                  currentLayerI = 8
                                  currentLayer = layers[8]
                                else
                                  if key == "9" then
                                    currentLayerI = 9
                                    currentLayer = layers[9]
                                  end
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
love.draw = function()
  local ww, wh = love.graphics.getDimensions()
  local pww, pwh = ww / 2, wh / 2
  love.graphics.push()
  love.graphics.push()
  love.graphics.push()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.scale(scaleX, scaleY)
  love.graphics.draw(inventoryCanvas, 0, 0)
  love.graphics.setBlendMode("alpha")
  love.graphics.pop()
  love.graphics.push()
  love.graphics.translate(0, inventoryHeight * scaleY)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("fill", 0, 0, ww, scaleY * (pwh - inventoryHeight - statusHeight))
  love.graphics.pop()
  love.graphics.push()
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  love.graphics.setScissor(0, 0, ww, pwh - statusHeight - inventoryHeight)
  love.graphics.translate(offsetX, offsetY)
  love.graphics.scale(mapScale, mapScale)
  love.graphics.setColor(1, 0, 0, 1)
  if mode ~= "view" then
    love.graphics.circle("fill", 0, 0, 3)
  end
  love.graphics.setColor(1, 1, 1, 1)
  for i, layer in ipairs(layers) do
    if i == currentLayerI or mode == "view" then
      love.graphics.setColor(1, 1, 1, 1)
    else
      love.graphics.setColor(1, 1, 1, 0.5)
    end
    love.graphics.draw(layer.batch)
  end
  love.graphics.setScissor()
  love.graphics.pop()
  love.graphics.pop()
  love.graphics.setCanvas()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.draw(canvas, 0, inventoryHeight * scaleY, 0, scaleX, scaleY)
  love.graphics.setBlendMode("alpha")
  love.graphics.pop()
  if mode ~= "view" then
    love.graphics.push()
    love.graphics.translate(0, inventoryHeight * scaleY)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(linesCanvas, 0, 0)
    love.graphics.setBlendMode("alpha")
    love.graphics.pop()
  end
  love.graphics.setColor(1, 1, 1, 1)
  local status = string.upper("[" .. mode .. "] ")
  if offsetX == 0 then
    status = status .. "x: 0"
  else
    status = status .. ("x: " .. -offsetX)
  end
  status = status .. ", "
  if offsetY == 0 then
    status = status .. "y: 0"
  else
    status = status .. ("y: " .. -offsetY)
  end
  status = status .. ", "
  status = status .. ("layer: " .. currentLayerI)
  return love.graphics.print(status, 0, wh - statusHeight * scaleY)
end
