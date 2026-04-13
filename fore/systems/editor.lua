local Editor = {}

local foreRef = nil
local json = require("fore.utils.json")

-- Editor State
Editor.enabled = false
Editor.types = {}
Editor.objects = {}
Editor.globalToggles = {}
Editor.playCustom = false

-- UI State
Editor.tools = {"Select", "Place"}
Editor.activeTool = "Select"
Editor.activeBuildType = nil
Editor.selectedObject = nil

Editor.snap = 10
Editor.camera = { x = 0, y = 0, zoom = 1, dragging = false }
Editor.mouse = { sx = 0, sy = 0, wx = 0, wy = 0, dragging = false, dragObj = nil, dragOffsetX = 0, dragOffsetY = 0, rectStartX = 0, rectStartY = 0 }
Editor.uiRects = {} -- format: {x,y,w,h,action=function()}

function Editor.init(fore)
    foreRef = fore
    return Editor
end

function Editor.registerType(id, def)
    -- def should have: shape="point"|"rectangle", color={r,g,b}, defaultParams={}
    Editor.types[id] = def
    if Editor.tools[2] == "Place" then
        if not Editor.activeBuildType then
            Editor.activeBuildType = id
        end
    end
end

function Editor.registerGlobalToggle(id, defaultVal)
    Editor.globalToggles[id] = defaultVal
end

function Editor.getGlobalToggle(id)
    return Editor.globalToggles[id]
end

function Editor.save()
    local data = {
        objects = {}
    }
    for _, obj in ipairs(Editor.objects) do
        table.insert(data.objects, {
            type = obj.type,
            x = obj.x,
            y = obj.y,
            w = obj.w,
            h = obj.h,
            params = obj.params
        })
    end
    data.globals = Editor.globalToggles

    local jsonStr = json.encode(data)
    love.filesystem.write("custom.json", jsonStr)
    print("Saved custom.json to", love.filesystem.getSaveDirectory())
end

function Editor.clear()
    Editor.objects = {}
    Editor.selectedObject = nil
end

local function snap(val)
    if Editor.snap <= 1 then return math.floor(val) end
    return math.floor(val / Editor.snap + 0.5) * Editor.snap
end

-- Input handlers
function Editor.mousepressed(px, py, button, istouch)
    local x, y = Editor.mouse.sx, Editor.mouse.sy
    local hitUI = false
    for _, rect in ipairs(Editor.uiRects) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            rect.action()
            hitUI = true
        end
    end

    if hitUI then return end

    if button == 2 then -- Right click pans camera
        Editor.camera.dragging = true
        return
    end

    if button == 1 then
        if Editor.activeTool == "Select" then
            -- Try to select
            Editor.selectedObject = nil
            for i = #Editor.objects, 1, -1 do
                local o = Editor.objects[i]
                local typ = Editor.types[o.type]
                if typ.shape == "point" then
                    if math.abs(Editor.mouse.wx - o.x) < 10 and math.abs(Editor.mouse.wy - o.y) < 10 then
                        Editor.selectedObject = o
                        break
                    end
                elseif typ.shape == "rectangle" then
                    local w = o.w or 40
                    local h = o.h or 40
                    if Editor.mouse.wx >= o.x and Editor.mouse.wx <= o.x + w and Editor.mouse.wy >= o.y and Editor.mouse.wy <= o.y + h then
                        Editor.selectedObject = o
                        break
                    end
                end
            end

            if Editor.selectedObject then
                Editor.mouse.dragObj = Editor.selectedObject
                Editor.mouse.dragOffsetX = Editor.selectedObject.x - Editor.mouse.wx
                Editor.mouse.dragOffsetY = Editor.selectedObject.y - Editor.mouse.wy
            end
        elseif Editor.activeTool == "Place" and Editor.activeBuildType then
            local def = Editor.types[Editor.activeBuildType]
            if def.shape == "point" then
                local obj = {
                    type = Editor.activeBuildType,
                    x = snap(Editor.mouse.wx),
                    y = snap(Editor.mouse.wy),
                    params = {}
                }
                if def.defaultParams then
                    for k, v in pairs(def.defaultParams) do obj.params[k] = v end
                end
                table.insert(Editor.objects, obj)
            elseif def.shape == "rectangle" then
                Editor.mouse.rectStartX = snap(Editor.mouse.wx)
                Editor.mouse.rectStartY = snap(Editor.mouse.wy)
                Editor.mouse.draggingRect = true
            end
        end
    end
end

function Editor.mousereleased(px, py, button, istouch)
    local x, y = Editor.mouse.sx, Editor.mouse.sy
    if button == 2 then
        Editor.camera.dragging = false
    end
    if button == 1 then
        if Editor.mouse.dragObj then
            Editor.mouse.dragObj.x = snap(Editor.mouse.dragObj.x)
            Editor.mouse.dragObj.y = snap(Editor.mouse.dragObj.y)
            Editor.mouse.dragObj = nil
        end
        if Editor.mouse.draggingRect then
            local rx = math.min(Editor.mouse.rectStartX, snap(Editor.mouse.wx))
            local ry = math.min(Editor.mouse.rectStartY, snap(Editor.mouse.wy))
            local rw = math.abs(snap(Editor.mouse.wx) - Editor.mouse.rectStartX)
            local rh = math.abs(snap(Editor.mouse.wy) - Editor.mouse.rectStartY)
            
            if rw > 0 and rh > 0 then
                local obj = {
                    type = Editor.activeBuildType,
                    x = rx, y = ry, w = rw, h = rh,
                    params = {}
                }
                local def = Editor.types[Editor.activeBuildType]
                if def.defaultParams then
                    for k, v in pairs(def.defaultParams) do obj.params[k] = v end
                end
                table.insert(Editor.objects, obj)
            end
            Editor.mouse.draggingRect = false
        end
    end
end

function Editor.wheelmoved(x, y)
    -- zooming
    if y > 0 then
        Editor.camera.zoom = Editor.camera.zoom * 1.1
    elseif y < 0 then
        Editor.camera.zoom = Editor.camera.zoom / 1.1
    end
end

function Editor.mousemoved(x, y, dx, dy, istouch)
    if Editor.camera.dragging then
        Editor.camera.x = Editor.camera.x - dx / Editor.camera.zoom
        Editor.camera.y = Editor.camera.y - dy / Editor.camera.zoom
    end
    
    if Editor.mouse.dragObj then
        Editor.mouse.dragObj.x = Editor.mouse.wx + Editor.mouse.dragOffsetX
        Editor.mouse.dragObj.y = Editor.mouse.wy + Editor.mouse.dragOffsetY
    end
end

function Editor.keypressed(key)
    if key == "delete" or key == "backspace" then
        if Editor.selectedObject then
            for i, v in ipairs(Editor.objects) do
                if v == Editor.selectedObject then
                    table.remove(Editor.objects, i)
                    break
                end
            end
            Editor.selectedObject = nil
        end
    end
end

function Editor.update(dt)
    local screenW, screenH = love.graphics.getDimensions()
    local mx, my = love.mouse.getPosition()
    
    -- In this custom editor scene, we bypass the main camera, but calculate world pos manually
    local pW, pH, vW, vH = foreRef:computeInternalResolution()
    local scale = foreRef.data.scale
    local offsetX = (screenW - pW) / 2
    local offsetY = (screenH - pH) / 2
    
    local internalMx = (mx - offsetX) / scale
    local internalMy = (my - offsetY) / scale

    Editor.mouse.sx = internalMx
    Editor.mouse.sy = internalMy
    
    -- Simple camera logic
    Editor.mouse.wx = (internalMx - vW/2) / Editor.camera.zoom + Editor.camera.x
    Editor.mouse.wy = (internalMy - vH/2) / Editor.camera.zoom + Editor.camera.y

end

-- Custom UI helper
local function drawButton(id, txt, x, y, w, h, active, action)
    table.insert(Editor.uiRects, {x=x, y=y, w=w, h=h, action=action})
    
    if active then
        love.graphics.setColor(0.3, 0.6, 0.9, 1)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
    end
    
    local mx, my = Editor.mouse.sx, Editor.mouse.sy
    if mx >= x and mx <= x+w and my >= y and my <= y+h then
        love.graphics.setColor(0.4, 0.7, 1.0, 1)
    end
    
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.print(txt, x + 5, y + 5)
end

function Editor.draw()
    local pW, pH, vW, vH = foreRef:computeInternalResolution()
    Editor.uiRects = {}
    
    -- Draw World
    love.graphics.push()
    love.graphics.translate(vW/2, vH/2)
    love.graphics.scale(Editor.camera.zoom, Editor.camera.zoom)
    love.graphics.translate(-Editor.camera.x, -Editor.camera.y)
    
    -- Draw Grid
    love.graphics.setColor(1, 1, 1, 0.1)
    local cx, cy = Editor.camera.x, Editor.camera.y
    local hw, hh = vW/2/Editor.camera.zoom, vH/2/Editor.camera.zoom
    local snapVal = Editor.snap > 1 and Editor.snap or 10
    local startX = math.floor((cx - hw) / snapVal) * snapVal
    local endX = math.floor((cx + hw) / snapVal) * snapVal
    local startY = math.floor((cy - hh) / snapVal) * snapVal
    local endY = math.floor((cy + hh) / snapVal) * snapVal
    for x = startX, endX, snapVal do love.graphics.line(x, startY, x, endY) end
    for y = startY, endY, snapVal do love.graphics.line(startX, y, endX, y) end
    
    -- Draw Objects
    for _, obj in ipairs(Editor.objects) do
        local typ = Editor.types[obj.type]
        if typ then
            if typ.color then
                love.graphics.setColor(typ.color)
            else
                love.graphics.setColor(0.8, 0.8, 0.8)
            end
            
            if typ.shape == "point" then
                love.graphics.circle("fill", obj.x, obj.y, 5)
            elseif typ.shape == "rectangle" then
                love.graphics.rectangle("fill", obj.x, obj.y, obj.w or 20, obj.h or 20)
            end
            
            if obj == Editor.selectedObject then
                love.graphics.setColor(1, 1, 1, 1)
                if typ.shape == "point" then
                    love.graphics.circle("line", obj.x, obj.y, 8)
                else
                    love.graphics.rectangle("line", obj.x, obj.y, obj.w or 20, obj.h or 20)
                end
            end
        end
    end
    
    -- Dragging rect preview
    if Editor.mouse.draggingRect then
        love.graphics.setColor(1, 1, 1, 0.5)
        local curX, curY = snap(Editor.mouse.wx), snap(Editor.mouse.wy)
        love.graphics.rectangle("fill", 
            math.min(Editor.mouse.rectStartX, curX),
            math.min(Editor.mouse.rectStartY, curY),
            math.abs(curX - Editor.mouse.rectStartX),
            math.abs(curY - Editor.mouse.rectStartY)
        )
    end
    
    love.graphics.pop()
    
    -- Draw UI Background Strip
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", 0, 0, vW, 40)
    
    -- Draw Buttons
    local bx = 10
    drawButton("btn_select", "Select", bx, 5, 50, 30, Editor.activeTool=="Select", function() Editor.activeTool = "Select" Editor.selectedObject = nil end)
    bx = bx + 60
    drawButton("btn_place", "Place", bx, 5, 50, 30, Editor.activeTool=="Place", function() Editor.activeTool = "Place" Editor.selectedObject = nil end)
    bx = bx + 70
    
    if Editor.activeTool == "Place" then
        for id, def in pairs(Editor.types) do
            local w = love.graphics.getFont():getWidth(id) + 10
            drawButton("btn_type_"..id, id, bx, 5, w, 30, Editor.activeBuildType==id, function() Editor.activeBuildType = id end)
            bx = bx + w + 10
        end
    end
    
    -- Right side buttons
    local rbx = vW - 60
    drawButton("btn_play", "Play", rbx, 5, 50, 30, false, function() 
        Editor.playCustom = true
        Editor.enabled = false
        foreRef.scenes:goTo("game") 
    end)
    rbx = rbx - 60
    drawButton("btn_save", "Save", rbx, 5, 50, 30, false, function() Editor.save() end)
    rbx = rbx - 90
    drawButton("btn_snap", "Snap: " .. Editor.snap, rbx, 5, 80, 30, false, function()
        if Editor.snap == 10 then Editor.snap = 1 else Editor.snap = 10 end
    end)
    rbx = rbx - 120
    drawButton("btn_clear", "Clear", rbx, 5, 50, 30, false, function() Editor.clear() end)
    rbx = rbx - 100
    drawButton("btn_load", "Load Editor", rbx, 5, 90, 30, false, function()
        -- Helper strictly to deserialize custom.json back to editor
        if love.filesystem.getInfo("custom.json") then
            local str = love.filesystem.read("custom.json")
            if str then
                local data = json.decode(str)
                if data and data.objects then
                    Editor.objects = data.objects
                    if data.globals then Editor.globalToggles = data.globals end
                end
            end
        end
    end)
    
    -- Global Toggles
    local gy = 50
    for id, val in pairs(Editor.globalToggles) do
        local txt = id .. ": " .. tostring(val)
        drawButton("tog_"..id, txt, 10, gy, 150, 30, val, function() 
            Editor.globalToggles[id] = not val 
        end)
        gy = gy + 40
    end
    
    -- Inspector
    if Editor.selectedObject then
        love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
        love.graphics.rectangle("fill", vW - 150, 40, 150, vH - 40)
        love.graphics.setColor(1,1,1,1)
        love.graphics.print("Type: " .. Editor.selectedObject.type, vW - 140, 50)
        love.graphics.print("X: " .. Editor.selectedObject.x, vW - 140, 70)
        love.graphics.print("Y: " .. Editor.selectedObject.y, vW - 140, 90)
        
        -- Draw delete hint
        love.graphics.setColor(1, 0.3, 0.3, 1)
        love.graphics.print("DEL to delete", vW - 140, 110)
    end
    
end

return Editor
