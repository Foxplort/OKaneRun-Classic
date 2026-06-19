local Scene = {}

-- ################# --
-- ### VARIABLES ### --
-- ################# --

local EffectSystem = require("okanerun.src.game.effectSystem")
local Effects      = require("okanerun.src.game.effects")

-- Layout constants
local CARD_W = 120
local CARD_H = 160
local CARD_SPACING = 30
local ROW_SPACING = 50
local MARGIN_TOP = 80
local MARGIN_LEFT = 60
local FONT_S = 1.0

-- State
local rows = {
    { name = "Blessings", type = "shop", items = {}, scroll = 0, selected = 1 },
    { name = "Curses", type = "selection", items = {}, scroll = 0, selected = 1 },
    { name = "Controls", type = "buttons", items = {}, scroll = 0, selected = 1 }
}
local currentRow = 1
local selectedDebuff = nil
local coins = 0
local message = ""
local messageTimer = 0
local animTimer = 0
local verticalScroll = 0
local EffectsDesc = require("okanerun.src.data.effectsDesc")
local loadedImages = {}
local particles = {}

-- ################# --
-- ### FUNCTIONS ### --
-- ################# --

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = love.math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

local function pickRandom(list, n)
    local t = {}
    for _, v in pairs(list) do t[#t+1] = v end
    shuffle(t)
    local r = {}
    for i = 1, math.min(n, #t) do r[#r+1] = t[i] end
    return r
end

local function getAllByType(t)
    local r = {}
    for _, e in pairs(Effects) do
        if e.type == t then r[#r+1] = e end
    end
    return r
end

local function isAtLimit(player, effect)
    local entry = player.effects[effect.id]
    if not entry then return false end
    return effect.maxAmount and entry.amount >= effect.maxAmount
end

local function buildRows()
    local player = GameState.player
    coins = player.coins

    -- Row 1: Buffs
    local themeBuffs = getAllByType("buff")
    local availableBuffs = {}
    for _, b in ipairs(themeBuffs) do
        if not isAtLimit(player, b) then table.insert(availableBuffs, b) end
    end
    local pickedBuffs = pickRandom(availableBuffs, 3)
    rows[1].items = {}
    for _, b in ipairs(pickedBuffs) do
        table.insert(rows[1].items, {
            def = b,
            price = love.math.random(1, 4),
            bought = false
        })
    end

    -- Row 2: Debuffs
    local themeDebuffs = getAllByType("debuff")
    local availableDebuffs = {}
    for _, d in ipairs(themeDebuffs) do
        if not isAtLimit(player, d) then table.insert(availableDebuffs, d) end
    end
    local pickedDebuffs = pickRandom(availableDebuffs, 2)
    rows[2].items = {}
    for _, d in ipairs(pickedDebuffs) do
        table.insert(rows[2].items, {
            def = d
        })
    end

    -- Row 3: Buttons
    rows[3].items = {
        { txt = "Continue", action = function()
            if #rows[2].items > 0 and not selectedDebuff then
                message = "Pick a debuff first!"
                messageTimer = 2
                return
            end
            fore.audio.play("accept")
            fore.transition.start("dither", function()
                fore.scenes:goTo("game")
            end)
        end },
        { txt = "Menu", action = function()
            fore.audio.play("accept")
            fore.transition.start("spike", function()
                fore.scenes:goTo("menu")
            end)
        end }
    }
end

-- ###################### --
-- ### MAIN FUNCTIONS ### --
-- ###################### --

function Scene.enter()
    selectedDebuff = nil
    rows[1].selected = 1
    rows[2].selected = 1
    rows[3].selected = 1
    message = ""
    messageTimer = 0
    animTimer = 0
    verticalScroll = 0
    buildRows()
    
    currentRow = 3
    if #rows[1].items > 0 then currentRow = 1
    elseif #rows[2].items > 0 then currentRow = 2 end

    fore.graphics.scheduleLoad("missing", "okanerun/assets/images/buffs/missing.png")
    for id, eff in pairs(require("okanerun.src.game.effects")) do
        local path = "okanerun/assets/images/buffs/" .. eff.id .. ".png"
        if love.filesystem.getInfo(path) then
            fore.graphics.scheduleLoad(eff.id, path)
            table.insert(loadedImages, eff.id)
        end
    end

    -- Init particles
    particles = {}
    for i = 1, 40 do
        table.insert(particles, {
            x = math.random(0, fore.data.width),
            y = math.random(0, fore.data.height),
            s = math.random() * 2 + 0.5,
            vx = (math.random() - 0.5) * 10,
            vy = (math.random() * 5) + 5,
            a = math.random() * 0.3 + 0.1
        })
    end

    if fore.data.phone then
       CARD_W = 120*1.2
       CARD_H = 160*1.2
       FONT_S = 1.2
       --CARD_SPACING = 30
       --ROW_SPACING = 50
       --MARGIN_TOP = 80
       --MARGIN_LEFT = 60
    end
end

function Scene.exit()
    -- Apply selected
    if selectedDebuff then
        EffectSystem.apply(GameState.player, selectedDebuff.def)
    end
    fore.save.write()

    -- Unload assets
    for _, eff in pairs(loadedImages) do
        fore.graphics.scheduleUnload(eff)
    end
    fore.graphics.scheduleUnload("missing")
end

function Scene.update(dt)
    animTimer = animTimer + dt
    if messageTimer > 0 then
        messageTimer = messageTimer - dt
    end

    -- Touch selection
    if fore.input.gestures.taps.any then
        local tx, ty = fore.input.gestures.taps.x, fore.input.gestures.taps.y
        local adjTy = ty + verticalScroll
        
        local currentY = MARGIN_TOP
        for i, row in ipairs(rows) do
            local rowHeight = (row.type == "buttons" and 60 or (CARD_H + ROW_SPACING))
            if #row.items > 0 then
                if adjTy >= currentY - 20 and adjTy <= currentY + rowHeight then
                    -- Hit this row
                    for j, item in ipairs(row.items) do
                        local rx = MARGIN_LEFT + (j - 1) * (CARD_W + CARD_SPACING) - row.scroll
                        local rw = (row.type == "buttons" and 140 or CARD_W)
                        local rh = (row.type == "buttons" and 40 or CARD_H)
                        
                        if tx >= rx and tx <= rx + rw and
                           adjTy >= currentY and adjTy <= currentY + rh then
                            if currentRow == i and row.selected == j then
                                -- Trigger accept logic
                                fore.input.state["accept"] = true
                            else
                                currentRow = i
                                row.selected = j
                                fore.audio.play("select", { volume = 0.1 })
                            end
                            break
                        end
                    end
                end
                currentY = currentY + rowHeight
            end
        end
    end

    -- Handle Input
    local prevRow = currentRow
    local prevSelect = rows[currentRow].selected

    if fore.input:pressed("up") then
        local nextRow = currentRow
        for i = currentRow - 1, 1, -1 do
            if #rows[i].items > 0 then
                nextRow = i
                break
            end
        end
        
        if nextRow ~= currentRow then
            currentRow = nextRow
            rows[currentRow].selected = math.min(#rows[currentRow].items, prevSelect)
            fore.audio.play("select", { volume = 0.1, pitch = 1.1 })
        end
    elseif fore.input:pressed("down") then
        local nextRow = currentRow
        for i = currentRow + 1, #rows do
            if #rows[i].items > 0 then
                nextRow = i
                break
            end
        end

        if nextRow ~= currentRow then
            currentRow = nextRow
            rows[currentRow].selected = math.min(#rows[currentRow].items, prevSelect)
            fore.audio.play("select", { volume = 0.1, pitch = 0.9 })
        end
    end

    local r = rows[currentRow]
    if fore.input:pressed("left") then
        r.selected = math.max(1, r.selected - 1)
        fore.audio.play("select", { volume = 0.1 })
    elseif fore.input:pressed("right") then
        r.selected = math.min(#r.items, r.selected + 1)
        fore.audio.play("select", { volume = 0.1 })
    end

    if fore.input:pressed("accept") then
        local item = r.items[r.selected]
        if not item then return end

        if r.type == "shop" then
            local player = GameState.player
            if player.coins >= item.price then
                if not isAtLimit(player, item.def) then
                    if EffectSystem.apply(player, item.def) then
                        player.coins = player.coins - item.price
                        coins = player.coins
                        fore.audio.play("accept", { pitch = 1.2 })
                    end
                else
                    message = "Already at max amount!"
                    messageTimer = 2
                end
            else
                message = "Not enough coins!"
                messageTimer = 2
            end
        elseif r.type == "selection" then
            if selectedDebuff ~= item then
                selectedDebuff = item
                fore.audio.play("accept")
            end
        elseif r.type == "buttons" then
            if item.action then item.action() end
        end
    end

    -- Scrolling logic
    for _, row in ipairs(rows) do
        local targetScroll = 0
        local visibleWidth = fore.data.width - MARGIN_LEFT * 2
        local totalWidth = #row.items * (CARD_W + CARD_SPACING)
        
        if totalWidth > visibleWidth then
            local selX = (row.selected - 1) * (CARD_W + CARD_SPACING)
            targetScroll = math.max(0, math.min(totalWidth - visibleWidth, selX - visibleWidth / 2 + CARD_W / 2))
        end
        row.scroll = fore.math.lerp(row.scroll, targetScroll, dt * 10)
    end

    -- Vertical scrolling
    local totalHeight = MARGIN_TOP
    local selY = MARGIN_TOP
    for i, row in ipairs(rows) do
        if #row.items > 0 then
            local h = (row.type == "buttons" and 60 or (CARD_H + ROW_SPACING))
            if i == currentRow then
                selY = totalHeight
            end
            totalHeight = totalHeight + h
        end
    end
    
    local visibleHeight = fore.data.height - 40
    local targetVScroll = 0
    if totalHeight > visibleHeight then
        targetVScroll = math.max(0, math.min(totalHeight - visibleHeight, selY - visibleHeight / 2 + CARD_H / 2))
    end
    verticalScroll = fore.math.lerp(verticalScroll, targetVScroll, dt * 8)

    -- Update particles
    for _, p in ipairs(particles) do
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        if p.y > fore.data.height then p.y = -5 end
        if p.x > fore.data.width then p.x = -5 elseif p.x < -5 then p.x = fore.data.width end
    end
end

function Scene.draw()
    -- Background
    fore.draw2d.rect(0, 0, fore.data.width, fore.data.height, {10, 15, 20})
    
    -- Dust particles
    for _, p in ipairs(particles) do
        fore.draw2d.circ(p.x, p.y, p.s, p.s, {200, 200, 220, p.a * 255})
    end

    -- Header
    fore.text.text("Coins: " .. coins, fore.data.width - 160, 30, 1.2, {255, 240, 100}, 130, "right")

    love.graphics.push()
    love.graphics.translate(0, -verticalScroll)

    -- Rows
    local currentY = MARGIN_TOP
    for i, row in ipairs(rows) do
        local rowHeight = (row.type == "buttons" and 60 or (CARD_H + ROW_SPACING))
        
        if #row.items > 0 then
            local rowAnimOffset = math.max(0, 1 - (animTimer - i * 0.15) * 4)
            local ry = currentY + rowAnimOffset * 20
            local isRowFocused = (i == currentRow)
            
            -- Alpha fade when scrolling up
            local yInView = ry - verticalScroll + 40
            local topFade = math.min(1, (yInView - 40) / 60)
            local rowAlpha = math.min(1, (animTimer - i * 0.15) * 4) * math.max(0, topFade)
            
            if rowAlpha > 0 then
                -- Row title
                local titleColor = isRowFocused and {255, 255, 255, rowAlpha * 255} or {127, 127, 127, rowAlpha * 180}
                fore.text.text(row.name:upper(), MARGIN_LEFT, ry - 25, 1 * FONT_S, titleColor)

                -- Items
                love.graphics.push()
                love.graphics.translate(-row.scroll, 0)
                
                for j, item in ipairs(row.items) do
                    local rx = MARGIN_LEFT + (j - 1) * (CARD_W + CARD_SPACING)
                    local isSelected = (isRowFocused and row.selected == j)
                    
                    if row.type == "shop" or row.type == "selection" then
                        local isShop = (row.type == "shop")
                        local limit = isAtLimit(GameState.player, item.def)
                        
                        -- Colors
                        local themeCol = isShop and {0, 200, 180} or {220, 20, 80}
                        if limit or item.bought then
                             themeCol = isShop and {40, 80, 80} or {80, 40, 50}
                        end

                        -- Card Body Color
                        local bgCol = {40, 45, 55, rowAlpha * 220}
                        if not isShop then bgCol = {45, 40, 45, rowAlpha * 220} end
                        
                        if isSelected then
                            bgCol = {220, 240, 255, rowAlpha * 255}
                            if currentRow == 1 then
                                fore.draw2d.rect(rx - 3, ry - 3, CARD_W + 6, CARD_H + 6, {0, 180, 180, rowAlpha * 150}, true)
                            else
                                fore.draw2d.rect(rx - 3, ry - 3, CARD_W + 6, CARD_H + 6, {220, 20, 80, rowAlpha * 150}, true)
                            end
                        end
                        if limit then bgCol = {20, 22, 28, rowAlpha * 200} end
                        if item.bought then bgCol = {15, 15, 20, rowAlpha * 180} end
                        
                        -- Selected mark for debuff
                        if row.type == "selection" and selectedDebuff == item then
                            fore.draw2d.rect(rx - 5, ry - 5, CARD_W + 10, CARD_H + 10, {220, 20, 80, rowAlpha * 255}, false)
                        end

                        -- Main Card Body
                        fore.draw2d.rect(rx, ry, CARD_W, CARD_H, bgCol)
                        
                        -- Colored Accent Border
                        fore.draw2d.rect(rx, ry, CARD_W, 4, {themeCol[1], themeCol[2], themeCol[3], rowAlpha * 255})
                        
                        -- Inner frame
                        local innerAlpha = isSelected and 40 or 15
                        if limit then innerAlpha = 5 end
                        fore.draw2d.rect(rx + 2, ry + 2, CARD_W - 4, CARD_H - 4, {themeCol[1], themeCol[2], themeCol[3], rowAlpha * innerAlpha})

                        -- Card Content Colors
                        local txtAlpha = rowAlpha * 255
                        local txtCol = isSelected and {20, 25, 40, txtAlpha} or {180, 200, 220, txtAlpha}
                        if limit then txtCol = {100, 110, 120, txtAlpha} end
                        if item.bought then txtCol = {60, 65, 75, txtAlpha} end

                        -- Icon
                        local iconTint = isSelected and {20, 25, 40, txtAlpha} or {themeCol[1], themeCol[2], themeCol[3], txtAlpha}
                        fore.graphics.imageSafe(item.def.id, "missing", rx + CARD_W/2 - 16, ry + 10, 32, 32, 0, 0, 0, iconTint)
                        
                        -- ID/Name
                        fore.text.text(item.def.id:upper(), rx + 5, ry + 50, 1 * FONT_S, txtCol, CARD_W - 10, "center")
                        
                        -- Desc
                        fore.text.textEx(EffectsDesc[item.def.id] or "No description", rx + 10, ry + 70, 0.8 * FONT_S, txtCol, CARD_W - 20, "left")

                        -- Price for buffs
                        if isShop then
                            local priceCol = isSelected and {20, 25, 40, txtAlpha} or {themeCol[1], themeCol[2], themeCol[3], txtAlpha}
                            fore.text.text(item.price .. "c", rx + CARD_W - 35, ry + CARD_H - 18, 1, priceCol, 30, "right")
                        end

                    elseif row.type == "buttons" then
                        -- Button rendering
                        local btnW = 140
                        local btnH = 40
                        local bx = rx
                        local by = ry
                        
                        local bCol = isSelected and {255, 255, 230, rowAlpha * 255} or {60, 65, 80, rowAlpha * 200}
                        local tCol = isSelected and {20, 20, 30, rowAlpha * 255} or {220, 225, 240, rowAlpha * 255}
                        
                        -- shadow/border for selected
                        if isSelected then
                            fore.draw2d.rect(bx - 3, by - 3, btnW + 6, btnH + 6, {0, 127, 127, rowAlpha * 180}, true)
                        end
                        fore.draw2d.rect(bx, by, btnW, btnH, bCol)
                        fore.text.text(item.txt, bx, by + 15, 1, tCol, btnW, "center")
                    end
                end
                love.graphics.pop()
            end
            currentY = currentY + rowHeight
        end
    end
    love.graphics.pop()

    -- Message overlay
    if messageTimer > 0 then
        local alpha = math.min(1, messageTimer * 2)
        fore.text.text(message, 0, fore.data.height - 40, 1, {1, 0.3, 0.3, alpha}, fore.data.width, "center")
    end

    if fore.save.get("hints") then
        local input_hint = "DPad - select\nA - confirm"
        if fore.input:getMethod() == "keyboard" then
            input_hint = "WASD / Arrow Keys - select\nSpace - confirm"
        end

        if not fore.data.phone then
            fore.text.textEx(
                input_hint,
                fore.data.width - 170, fore.data.height - 30, 0.75, {255, 255, 255, 70}, 150, "right"
            )
        end
    end
end


return Scene
