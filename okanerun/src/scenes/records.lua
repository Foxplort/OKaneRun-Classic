local Scene = {}
local Documents = require("okanerun.src.data.documents")

local MARGIN_LEFT = 60
local MARGIN_TOP = 80
local CARD_W = 140
local CARD_H = 100
local CARD_SPACING = 20
local ROW_SPACING = 30

local currentMode = "list"
local selectedIdx = 1
local logScore = 0
local availableDocs = {}
local animTimer = 0
local listVScroll = 0
local readerVScroll = 0
local readerMaxScroll = 0

local particles = {}
local loaded_assets = {}

local function isUnlocked(doc)
    return logScore >= (doc.scoreReq or 0)
end

function Scene.enter()
    -- Recalculate logScore
    local deaths = fore.save.get("deaths") or 0
    local coins = fore.save.get("coint_deposited") or 0
    local effects = fore.save.get("effects_obtained") or 0
    logScore = deaths * 3 + coins + effects

    availableDocs = Documents
    currentMode = "list"
    selectedIdx = 1
    animTimer = 0
    listVScroll = 0
    readerVScroll = 0

    -- Particles
    particles = {}
    for i = 1, 40 do
        table.insert(particles, {
            x = math.random(fore.data.width),
            y = math.random(fore.data.height),
            s = math.random(1, 3),
            vx = math.random(-10, 10),
            vy = math.random(5, 20),
            a = math.random(0.1, 0.5)
        })
    end
    
    fore.audio.load("menu_music", "okanerun/assets/sounds/music/001.ogg", false, "music")

    fore.graphics.scheduleLoad("missing", "okanerun/assets/images/docs/missing.png", false)
    for _, doc in ipairs(Documents) do
        if doc.icon and not loaded_assets[doc.icon] then
            fore.graphics.scheduleLoad(doc.icon, "okanerun/assets/images/docs/" .. doc.icon .. ".png", false)
            table.insert(loaded_assets, doc.icon)
        end
    end
end

function Scene.onComplete()
    if not fore.audio.isPlaying("menu_music") then
        fore.audio.play("menu_music", {volume = 2.0, loop = true, fadeIn = 2.0})
    end
end

function Scene.exit()
    if fore.scenes.next ~= "menu" then
        fore.audio.fadeOutAndUnload("menu_music", 2.0)
    end
    fore.graphics.scheduleUnload("missing")
    for _, asset in ipairs(loaded_assets) do
        fore.graphics.scheduleUnload(asset)
    end
end

function Scene.update(dt)
    animTimer = animTimer + dt

    -- Update particles
    for _, p in ipairs(particles) do
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        if p.y > fore.data.height then p.y = -5 end
        if p.x > fore.data.width then p.x = -5 elseif p.x < -5 then p.x = fore.data.width end
    end

    if currentMode == "list" then
        -- List Navigation
        local cols = 3
        if fore.input:pressed("right") then
            selectedIdx = math.min(#availableDocs, selectedIdx + 1)
            fore.audio.play("select", { volume = 0.1 })
        elseif fore.input:pressed("left") then
            selectedIdx = math.max(1, selectedIdx - 1)
            fore.audio.play("select", { volume = 0.1 })
        elseif fore.input:pressed("down") then
            selectedIdx = math.min(#availableDocs, selectedIdx + cols)
            fore.audio.play("select", { volume = 0.1, pitch = 0.9 })
        elseif fore.input:pressed("up") then
            selectedIdx = math.max(1, selectedIdx - cols)
            fore.audio.play("select", { volume = 0.1, pitch = 1.1 })
        end

        if fore.input:pressed("accept") then
            local doc = availableDocs[selectedIdx]
            if isUnlocked(doc) then
                currentMode = "reading"
                readerVScroll = 0
                fore.audio.play("accept")
            else
                fore.audio.play("select", { pitch = 0.5, volume = 0.8 })
            end
        end

        if fore.input:pressed("cancel") then
            fore.transition.start("dither", function()
                fore.scenes:goTo("menu")
            end)
        end

        -- Scroll list
        local row = math.ceil(selectedIdx / cols)
        local selY = MARGIN_TOP + (row - 1) * (CARD_H + ROW_SPACING)
        local visibleH = fore.data.height - 100
        local targetScroll = math.max(0, selY - visibleH / 2)
        listVScroll = fore.math.lerp(listVScroll, targetScroll, dt * 8)

    else
        -- Reading Mode
        if fore.input:down("down") then
            readerVScroll = math.min(readerMaxScroll, readerVScroll + 300 * dt)
        elseif fore.input:down("up") then
            readerVScroll = math.max(0, readerVScroll - 300 * dt)
        end

        if fore.input:pressed("cancel") then
            currentMode = "list"
            fore.audio.play("select", { volume = 0.1, pitch = 0.8 })
        end
    end
end

local function drawDocument(doc)
    local padding = 40
    local boxX, boxY = padding, padding
    local boxW, boxH = fore.data.width - padding * 2, fore.data.height - padding * 2
    local sidebarW = 220
    
    -- Document background
    fore.graphics.rect(boxX, boxY, boxW, boxH, {15, 20, 25, 240})
    fore.graphics.rect(boxX, boxY, boxW, 4, {doc.tint[1], doc.tint[2], doc.tint[3], 255})

    -- Sidebar
    local sx = boxX + 20
    local sy = boxY + 40
    
    -- Icon Frame
    fore.graphics.rect(sx, sy, 64, 64, {30, 35, 45})
    fore.graphics.rect(sx, sy, 64, 64, {doc.tint[1], doc.tint[2], doc.tint[3], 100}, false)
    fore.graphics.imageSafe(doc.icon or "missing", "missing", sx + 16, sy + 16, 32, 32, 0, 0, 0, doc.tint)
    
    -- Metadata
    fore.graphics.text(doc.name:upper(), sx, sy + 80, 1.2, {255, 255, 255}, sidebarW - 40, "left")
    fore.graphics.textEx(doc.desc, sx, sy + 110, 0.8, {160, 170, 180}, sidebarW - 40, "left")
    
    fore.graphics.text("BACK [ESC]", sx, boxY + boxH - 30, 0.8, {100, 110, 120})

    -- Body Text Area
    local tx = boxX + sidebarW
    local ty = boxY + 40
    local tw = boxW - sidebarW - 40
    local th = boxH - 80

    local s = fore.data.scale
    love.graphics.setScissor((tx-5) * s, ty * s, (tw+10) * s, th * s)
    love.graphics.push()
    love.graphics.translate(tx, ty - readerVScroll)

    local cy = 0
    
    -- Title tags
    local lines = {}
    for line in doc.body:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end

    for _, line in ipairs(lines) do
        local isTitle = false
        local content = line:gsub("%[title%](.*)%[/title%]", function(t)
            isTitle = true
            return t
        end)

        if isTitle then
            cy = cy + (cy > 0 and 20 or 0)
            fore.graphics.text(content:upper(), 0, cy, 1.4, doc.tint)
            cy = cy + 35
        else
            local h = fore.graphics.textEx(content, 0, cy, 1.0, {200, 210, 220}, tw, "left")
            cy = cy + h + 10
        end
    end

    readerMaxScroll = math.max(0, cy - th + 20)
    
    love.graphics.pop()
    love.graphics.setScissor()

    -- Scroll Indicator
    if readerMaxScroll > 0 then
        local barH = 50
        local trackH = th - barH
        local barY = ty + (readerVScroll / readerMaxScroll) * trackH
        fore.graphics.rect(boxX + boxW - 10, barY, 3, barH, {doc.tint[1], doc.tint[2], doc.tint[3], 150})
    end
end

function Scene.draw()
    -- Background
    fore.graphics.rect(0, 0, fore.data.width, fore.data.height, {8, 12, 16})
    
    -- Dust
    for _, p in ipairs(particles) do
        fore.graphics.circ(p.x, p.y, p.s, p.s, {200, 200, 220, p.a * 255})
    end

    if currentMode == "list" then
        -- Header
        fore.graphics.text("INTERNAL RECORDS", 60, 25, 2.5, {255, 250, 240})
        fore.graphics.text("Progress: " .. logScore .. " pts", fore.data.width - 220, 30, 1.0, {0, 200, 220})

        love.graphics.push()
        love.graphics.translate(0, -listVScroll)

        local boxFun = nil

        local cols = 3
        for i, doc in ipairs(availableDocs) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local rx = MARGIN_LEFT + col * (CARD_W + CARD_SPACING)
            local ry = MARGIN_TOP + row * (CARD_H + ROW_SPACING)
            
            local isSelected = (selectedIdx == i)
            local unlocked = isUnlocked(doc)
            
            local themeCol = unlocked and doc.tint or {80, 80, 80}
            local bgAlpha = isSelected and 255 or 180
            local bgCol = isSelected and {220, 240, 255, bgAlpha} or {35, 40, 50, bgAlpha}
            
            if not unlocked then bgCol = {15, 15, 20, 150} end

            -- Selection
            if isSelected then
                fore.graphics.rect(rx - 3, ry - 3, CARD_W + 6, CARD_H + 6, {themeCol[1], themeCol[2], themeCol[3], 150}, true)
            end

            -- Card Body
            fore.graphics.rect(rx, ry, CARD_W, CARD_H, bgCol)
            fore.graphics.rect(rx, ry, CARD_W, 4, {themeCol[1], themeCol[2], themeCol[3], 255})

            if unlocked then
                local txtCol = isSelected and {20, 25, 40} or {200, 210, 230}
                fore.graphics.text(doc.name:upper(), rx + 5, ry + 20, 1, txtCol, CARD_W - 10, "center")
                
                -- Icon
                fore.graphics.imageSafe(doc.icon or "missing", "missing", rx + CARD_W/2 - 12, ry + 50, 24, 24, 0, 0, 0, isSelected and {20,25,40} or themeCol)
                
                -- Summary box
                if isSelected then
                    boxFun = function()
                        local sw, sh = 200, 100
                        local sx, sy = rx + CARD_W + 10, ry - 10
                        if col == cols - 1 then sx = rx - sw - 10 end
                        
                        fore.graphics.rect(sx, sy, sw, sh, {0, 0, 0, 220})
                        fore.graphics.rect(sx, sy, sw, sh, {255, 255, 255, 100}, false)
                        fore.graphics.textEx(doc.desc, sx + 10, sy + 10, 0.8, {255, 255, 255}, sw - 20, "left")
                    end
                end
            else
                fore.graphics.text("LOCKED", rx + 5, ry + 35, 1, {80, 85, 90}, CARD_W - 10, "center")
                fore.graphics.text(doc.scoreReq .. " pts", rx + 5, ry + 55, 0.8, {60, 65, 70}, CARD_W - 10, "center")
            end
        end

            if boxFun then boxFun() end


        love.graphics.pop()
    else
        local doc = availableDocs[selectedIdx]
        drawDocument(doc)
    end
end

return Scene
