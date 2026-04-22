local utf8 = require("utf8")
local Editor = {}

local foreRef = nil
local json = require("fore.utils.json")

-- Editor State
Editor.enabled = false
Editor.types = {}
Editor.objects = {}
Editor.globalToggles = { showGrid = true }
Editor.playCustom = false

Editor.mapWidth = 1000
Editor.mapHeight = 1000
Editor.activeInputId = nil
Editor.inputText = ""
Editor.onInputCommit = nil

-- UI State
Editor.tools = {"Select", "Place"}
Editor.activeTool = "Select"
Editor.activeBuildType = nil
Editor.selectedObject = nil

Editor.snap = 20
Editor.camera = { x = 0, y = 0, zoom = 1, dragging = false }
Editor.mouse = { px = 0, py = 0, sx = 0, sy = 0, wx = 0, wy = 0, dragging = false, dragObj = nil, dragOffsetX = 0, dragOffsetY = 0, rectStartX = 0, rectStartY = 0 }
Editor.uiRects = {} 

-- Layout metrics (dynamic botH)
local topH = 40
local leftW = 200
local rightW = 250
local botH = 80

-- Palette Colors
local P_BG_TOP = {0.15, 0.16, 0.18, 0.95}
local P_BG_SIDE = {0.18, 0.19, 0.22, 0.95}
local P_BG_BOT = {0.12, 0.13, 0.15, 0.95}
local P_BORDER = {0.3, 0.35, 0.4, 0.5}

local P_BTN_IDLE = {0.25, 0.28, 0.32, 1.0}
local P_BTN_HOVER = {0.35, 0.4, 0.45, 1.0}
local P_BTN_ACTIVE = {0.4, 0.5, 0.65, 1.0}
local P_BTN_BORDER = {0.6, 0.65, 0.7, 0.3}

function Editor.init(fore)
    foreRef = fore
    return Editor
end

function Editor.registerType(id, def)
    Editor.types[id] = def
    if not Editor.activeBuildType then
        Editor.activeBuildType = id
    end
end

function Editor.registerGlobalToggle(id, defaultVal)
    Editor.globalToggles[id] = defaultVal
end

function Editor.getGlobalToggle(id)
    return Editor.globalToggles[id]
end

function Editor.save()
    local data = { objects = {} }
    for _, obj in ipairs(Editor.objects) do
        table.insert(data.objects, {
            type = obj.type,
            x = obj.x, y = obj.y, w = obj.w, h = obj.h,
            params = obj.params
        })
    end
    data.globals = Editor.globalToggles
    data.mapWidth = Editor.mapWidth
    data.mapHeight = Editor.mapHeight
    local jsonStr = json.encode(data)
    love.filesystem.write("custom.json", jsonStr)
end

function Editor.clear()
    Editor.objects = {}
    Editor.selectedObject = nil
end

function Editor.toggle()
    Editor.enabled = not Editor.enabled
    
    local Objects = package.loaded["okanerun.src.data.objects"]
    if Objects then
        for _, def in pairs(Objects) do
            if Editor.enabled then
                if def.onEditorLoad then def.onEditorLoad() end
            else
                if def.onEditorUnload then def.onEditorUnload() end
            end
        end
    end
end

local function snap(val)
    if Editor.snap <= 1 then return math.floor(val) end
    return math.floor(val / Editor.snap + 0.5) * Editor.snap
end

-- Input handlers
function Editor.mousepressed(px, py, button, istouch)
    local x, y = Editor.mouse.sx, Editor.mouse.sy
    local hitUI = false
    local clickedInputId = nil

    for _, rect in ipairs(Editor.uiRects) do
        if px >= rect.x and px <= rect.x + rect.w and py >= rect.y and py <= rect.y + rect.h then
            rect.action()
            if rect.inputId then clickedInputId = rect.inputId end
            hitUI = true
        end
    end
    
    if Editor.activeInputId and Editor.activeInputId ~= clickedInputId then
        local num = tonumber(Editor.inputText)
        if num and Editor.onInputCommit then Editor.onInputCommit(num) end
        Editor.activeInputId = clickedInputId
        if not clickedInputId then Editor.onInputCommit = nil end
    end

    local screenW, screenH = love.graphics.getDimensions()
    if py < topH or py > screenH - botH or px < leftW or px > screenW - rightW then
        hitUI = true
    end

    if hitUI then return end

    if button == 2 then
        Editor.camera.dragging = true
        return
    end

    if button == 1 then
        if Editor.activeTool == "Select" then
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
                    x = snap(Editor.mouse.wx), y = snap(Editor.mouse.wy),
                    params = {}
                }
                if def.defaultParams then
                    for k, v in pairs(def.defaultParams) do obj.params[k] = v end
                end
                table.insert(Editor.objects, obj)
                Editor.selectedObject = obj
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
                    x = rx, y = ry, w = rw, h = rh, params = {}
                }
                local def = Editor.types[Editor.activeBuildType]
                if def.defaultParams then
                    for k, v in pairs(def.defaultParams) do obj.params[k] = v end
                end
                table.insert(Editor.objects, obj)
                Editor.selectedObject = obj
            end
            Editor.mouse.draggingRect = false
        end
    end
end

function Editor.wheelmoved(x, y)
    if y > 0 then
        Editor.camera.zoom = Editor.camera.zoom * 1.1
    elseif y < 0 then
        Editor.camera.zoom = Editor.camera.zoom / 1.1
    end
end

function Editor.textinput(t)
    if Editor.activeInputId and t:match("[%d%-%.]") then
        Editor.inputText = Editor.inputText .. t
    end
end

function Editor.keypressed(key)
    if Editor.activeInputId then
        if key == "backspace" then
            local byteoffset = utf8.offset(Editor.inputText, -1)
            if byteoffset then Editor.inputText = string.sub(Editor.inputText, 1, byteoffset - 1) end
        elseif key == "return" or key == "kpenter" then
            local num = tonumber(Editor.inputText)
            if num and Editor.onInputCommit then Editor.onInputCommit(num) end
            Editor.activeInputId = nil
            Editor.onInputCommit = nil
        elseif key == "escape" then
            Editor.activeInputId = nil
            Editor.onInputCommit = nil
        end
        return
    end

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

function Editor.mousemoved(x, y, dx, dy, istouch)
    if Editor.camera.dragging then
        Editor.camera.x = Editor.camera.x - (dx / foreRef.data.scale) / Editor.camera.zoom
        Editor.camera.y = Editor.camera.y - (dy / foreRef.data.scale) / Editor.camera.zoom
    end
    
    if Editor.mouse.dragObj then
        Editor.mouse.dragObj.x = Editor.mouse.wx + Editor.mouse.dragOffsetX
        Editor.mouse.dragObj.y = Editor.mouse.wy + Editor.mouse.dragOffsetY
    end
end

function Editor.update(dt)
    local screenW, screenH = love.graphics.getDimensions()
    local mx, my = love.mouse.getPosition()
    
    local pW, pH, vW, vH = foreRef:computeInternalResolution()
    local scale = foreRef.data.scale
    local offsetX = (screenW - pW) / 2
    local offsetY = (screenH - pH) / 2
    
    local internalMx = (mx - offsetX) / scale
    local internalMy = (my - offsetY) / scale

    Editor.mouse.px = mx
    Editor.mouse.py = my
    Editor.mouse.sx = internalMx
    Editor.mouse.sy = internalMy
    
    Editor.mouse.wx = (internalMx - vW/2) / Editor.camera.zoom + Editor.camera.x
    Editor.mouse.wy = (internalMy - vH/2) / Editor.camera.zoom + Editor.camera.y
end

-- Custom UI helper
local function drawButton(id, txt, x, y, w, h, active, action)
    table.insert(Editor.uiRects, {x=x, y=y, w=w, h=h, action=action})
    
    local mx, my = Editor.mouse.px, Editor.mouse.py
    local isHover = mx >= x and mx <= x+w and my >= y and my <= y+h
    
    if active then
        love.graphics.setColor(P_BTN_ACTIVE)
    elseif isHover then
        love.graphics.setColor(P_BTN_HOVER)
    else
        love.graphics.setColor(P_BTN_IDLE)
    end
    love.graphics.rectangle("fill", x, y, w, h)
    
    love.graphics.setColor(P_BTN_BORDER)
    love.graphics.rectangle("line", x, y, w, h)
    
    love.graphics.setColor(1,1,1,1)
    local font = love.graphics.getFont()
    local th = font:getHeight()
    local tw = font:getWidth(txt)
    love.graphics.print(txt, x + (w - tw)/2, y + (h - th)/2)
end

local function drawNumberInput(id, label, value, x, y, w, h, onCommit)
    local active = (Editor.activeInputId == id)
    local displayVal = active and Editor.inputText or tostring(math.floor(value))
    
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(label, x, y + (h - Editor.uiFont:getHeight())/2)
    
    local lw = Editor.uiFont:getWidth(label) + 10
    local bx = x + lw
    local bw = w - lw
    
    table.insert(Editor.uiRects, {x=bx, y=y, w=bw, h=h, inputId=id, action=function()
        if Editor.activeInputId ~= id then
            Editor.activeInputId = id
            Editor.inputText = tostring(math.floor(value))
            Editor.onInputCommit = onCommit
        end
    end})
    
    local mx, my = Editor.mouse.px, Editor.mouse.py
    local isHover = mx >= bx and mx <= bx+bw and my >= y and my <= y+h
    
    if active then 
        love.graphics.setColor(P_BTN_ACTIVE)
    elseif isHover then
        love.graphics.setColor(P_BTN_HOVER)
    else 
        love.graphics.setColor(P_BTN_IDLE)
    end
    love.graphics.rectangle("fill", bx, y, bw, h)
    
    love.graphics.setColor(P_BTN_BORDER)
    love.graphics.rectangle("line", bx, y, bw, h)
    
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(displayVal .. (active and "_" or ""), bx + 5, y + (h - Editor.uiFont:getHeight())/2)
end

function Editor.drawWorld()
    local pW, pH, vW, vH = foreRef:computeInternalResolution()
    
    love.graphics.push()
    love.graphics.translate(vW/2, vH/2)
    love.graphics.scale(Editor.camera.zoom, Editor.camera.zoom)
    love.graphics.translate(-Editor.camera.x, -Editor.camera.y)
    
    -- Level Boundaries Outline
    love.graphics.setColor(1, 0, 0, 0.4)
    love.graphics.rectangle("line", 0, 0, Editor.mapWidth, Editor.mapHeight)
    
    for _, obj in ipairs(Editor.objects) do
        local typ = Editor.types[obj.type]
        if typ then
            if not Editor.globalToggles["simpleView"] and typ.gameDraw then
                typ.gameDraw(obj, true)
            else
                if typ.color then love.graphics.setColor(typ.color) else love.graphics.setColor(0.8, 0.8, 0.8) end
                if typ.shape == "point" then
                    love.graphics.circle("fill", obj.x, obj.y, 5)
                elseif typ.shape == "rectangle" then
                    love.graphics.rectangle("fill", obj.x, obj.y, obj.w or 20, obj.h or 20)
                end
            end
            
            if obj == Editor.selectedObject then
                love.graphics.setColor(1, 1, 1, 0.9)
                if typ.shape == "point" then
                    love.graphics.circle("line", obj.x, obj.y, 8)
                else
                    love.graphics.rectangle("line", obj.x, obj.y, obj.w or 20, obj.h or 20)
                end
            end
        end
    end
    
    -- Snapping Grid drawn OVER objects
    if Editor.snap > 1 and Editor.globalToggles["showGrid"] ~= false then
        love.graphics.setColor(1, 1, 1, 0.05)
        local cx, cy = Editor.camera.x, Editor.camera.y
        local hw, hh = vW/2/Editor.camera.zoom, vH/2/Editor.camera.zoom
        local snapVal = Editor.snap
        local startX = math.floor((cx - hw) / snapVal) * snapVal
        local endX = math.floor((cx + hw) / snapVal) * snapVal
        local startY = math.floor((cy - hh) / snapVal) * snapVal
        local endY = math.floor((cy + hh) / snapVal) * snapVal
        for x = startX, endX, snapVal do love.graphics.line(x, startY, x, endY) end
        for y = startY, endY, snapVal do love.graphics.line(startX, y, endX, y) end
    end
    
    if Editor.mouse.draggingRect then
        love.graphics.setColor(1, 1, 1, 0.3)
        local curX, curY = snap(Editor.mouse.wx), snap(Editor.mouse.wy)
        love.graphics.rectangle("fill", 
            math.min(Editor.mouse.rectStartX, curX), math.min(Editor.mouse.rectStartY, curY),
            math.abs(curX - Editor.mouse.rectStartX), math.abs(curY - Editor.mouse.rectStartY)
        )
    end
    
    love.graphics.pop()
end

function Editor.drawUI()
    local screenW, screenH = love.graphics.getDimensions()
    Editor.uiRects = {}
    
    if not Editor.uiFont then
        Editor.uiFont = love.graphics.newFont(16)
    end
    love.graphics.setFont(Editor.uiFont)
    
    -- Calculate Bottom Panel Rows dynamically
    local toolX = 140
    local rows = 1
    for id, def in pairs(Editor.types) do
        local w = Editor.uiFont:getWidth(" + " .. id) + 30
        if toolX + w > screenW - 170 then
            toolX = 140
            rows = rows + 1
        end
        toolX = toolX + w + 10
    end
    botH = 20 + rows * 40
    
    -- Panel Backgrounds
    love.graphics.setColor(P_BG_TOP)
    love.graphics.rectangle("fill", 0, 0, screenW, topH)
    love.graphics.setColor(P_BG_SIDE)
    love.graphics.rectangle("fill", 0, topH, leftW, screenH - topH - botH)
    love.graphics.rectangle("fill", screenW - rightW, topH, rightW, screenH - topH - botH)
    love.graphics.setColor(P_BG_BOT)
    love.graphics.rectangle("fill", 0, screenH - botH, screenW, botH)
    
    -- Panel Borders
    love.graphics.setColor(P_BORDER)
    love.graphics.line(0, topH, screenW, topH)
    love.graphics.line(leftW, topH, leftW, screenH - botH)
    love.graphics.line(screenW - rightW, topH, screenW - rightW, screenH - botH)
    love.graphics.line(0, screenH - botH, screenW, screenH - botH)
    
    -- ===================
    -- TOP PANEL
    -- ===================
    local curX = 10
    local curY = 5
    local function addTopBtn(tag, label, rw, func)
        drawButton("btn_"..tag, label, curX, curY, rw, 30, false, func)
        curX = curX + rw + 10
    end
    
    addTopBtn("load", "Load Custom", 120, function()
        if love.filesystem.getInfo("custom.json") then
            local str = love.filesystem.read("custom.json")
            if str then
                local data = json.decode(str)
                if data and data.objects then
                    Editor.objects = data.objects
                    if data.globals then Editor.globalToggles = data.globals end
                    Editor.mapWidth = data.mapWidth or 1000
                    Editor.mapHeight = data.mapHeight or 1000
                    if Editor.globalToggles["showGrid"] == nil then Editor.globalToggles["showGrid"] = true end
                end
            end
        end
    end)
    addTopBtn("save", "Save", 80, function() Editor.save() end)
    addTopBtn("snap", "Snap: " .. Editor.snap, 100, function()
        local snaps = {1, 10, 20, 50}
        for i, s in ipairs(snaps) do
            if Editor.snap == s then
                Editor.snap = snaps[(i % #snaps) + 1]
                return
            end
        end
        Editor.snap = 10
    end)
    addTopBtn("clear", "Clear Layout", 120, function() Editor.clear() end)
    
    curX = screenW - 100
    drawButton("btn_play", "Play", curX, curY, 80, 30, false, function()
        Editor.save()
        Editor.playCustom = true
        Editor.toggle()
        foreRef.scenes:goTo("game") 
    end)
    
    -- ===================
    -- LEFT PANEL (Hierarchy)
    -- ===================
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("-- Scene Objects --", 10, topH + 10)
    
    local listY = topH + 40
    for i, obj in ipairs(Editor.objects) do
        local label = string.format("%03d | %s", i, obj.type)
        drawButton("btn_obj_"..i, label, 10, listY, leftW - 20, 25, Editor.selectedObject == obj, function()
            Editor.selectedObject = obj
            Editor.activeTool = "Select"
        end)
        listY = listY + 30
        if listY > screenH - botH - 30 then break end
    end
    
    -- ===================
    -- BOTTOM PANEL (Tools)
    -- ===================
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("-- Tools --", 10, screenH - botH + 10)
    
    toolX = 10
    local toolY = screenH - botH + 10
    
    drawButton("btn_tool_select", "Select Mode", toolX, toolY, 120, 35, Editor.activeTool=="Select", function()
        Editor.activeTool = "Select"
    end)
    toolX = toolX + 130
    
    for id, def in pairs(Editor.types) do
        local w = Editor.uiFont:getWidth(" + " .. id) + 30
        if toolX + w > screenW - 170 then
            toolX = 140
            toolY = toolY + 40
        end
        local isActive = (Editor.activeTool == "Place" and Editor.activeBuildType == id)
        drawButton("btn_tool_"..id, " + " .. id, toolX, toolY, w, 35, isActive, function()
            Editor.activeTool = "Place"
            Editor.activeBuildType = id
            Editor.selectedObject = nil
        end)
        toolX = toolX + w + 10
    end
    
    drawButton("btn_tool_delete", "Delete Selected", screenW - 160, screenH - botH + 10, 150, 35, false, function()
        if Editor.selectedObject then
            for i, v in ipairs(Editor.objects) do
                if v == Editor.selectedObject then
                    table.remove(Editor.objects, i)
                    break
                end
            end
            Editor.selectedObject = nil
        end
    end)

    -- ===================
    -- RIGHT PANEL (Inspector)
    -- ===================
    local inspX = screenW - rightW + 10
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    
    if Editor.selectedObject then
        love.graphics.print("-- Properties --", inspX, topH + 10)
        local sy = topH + 40
        love.graphics.print("Type: " .. Editor.selectedObject.type, inspX, sy)
        sy = sy + 30
        
        drawNumberInput("obj_x", "X:", Editor.selectedObject.x, inspX, sy, 180, 25, function(v) Editor.selectedObject.x = v end)
        sy = sy + 30
        drawNumberInput("obj_y", "Y:", Editor.selectedObject.y, inspX, sy, 180, 25, function(v) Editor.selectedObject.y = v end)
        sy = sy + 30
        
        if Editor.selectedObject.w then
            drawNumberInput("obj_w", "Width:", Editor.selectedObject.w, inspX, sy, 180, 25, function(v) Editor.selectedObject.w = v end)
            sy = sy + 30
            drawNumberInput("obj_h", "Height:", Editor.selectedObject.h, inspX, sy, 180, 25, function(v) Editor.selectedObject.h = v end)
            sy = sy + 30
        end
        
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.print("(Use Delete action at bottom", inspX, sy + 15)
        love.graphics.print(" or DEL key to remove)", inspX, sy + 30)
    else
        love.graphics.print("-- Level Settings --", inspX, topH + 10)
        local gy = topH + 40
        drawNumberInput("map_w", "Map W:", Editor.mapWidth, inspX, gy, 180, 25, function(v) Editor.mapWidth = v end)
        gy = gy + 30
        drawNumberInput("map_h", "Map H:", Editor.mapHeight, inspX, gy, 180, 25, function(v) Editor.mapHeight = v end)
        gy = gy + 40
        
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.print("-- Global Toggles --", inspX, gy)
        gy = gy + 30
        for id, val in pairs(Editor.globalToggles) do
            local txt = string.format("%s: %s", id, tostring(val))
            drawButton("tog_g_"..id, txt, inspX, gy, rightW - 20, 30, val, function() 
                Editor.globalToggles[id] = not val 
            end)
            gy = gy + 40
        end
    end
end

return Editor
