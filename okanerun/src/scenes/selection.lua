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

-- State
local rows = {
    { name = "Buffs", type = "shop", items = {}, scroll = 0, selected = 1 },
    { name = "Debuffs", type = "selection", items = {}, scroll = 0, selected = 1 },
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
    local availableBuffs = getAllByType("buff")
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
    local availableDebuffs = getAllByType("debuff")
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
            if not selectedDebuff then
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
            fore.audio.play("select")
            fore.scenes:goTo("menu")
        end }
    }
end

-- ###################### --
-- ### MAIN FUNCTIONS ### --
-- ###################### --

function Scene.enter()
    selectedDebuff = nil
    currentRow = 1
    rows[1].selected = 1
    rows[2].selected = 1
    rows[3].selected = 1
    message = ""
    messageTimer = 0
    animTimer = 0
    verticalScroll = 0
    buildRows()

    fore.graphics.scheduleLoad("missing", "okanerun/assets/images/buffs/missing.png")
    for id, eff in pairs(require("okanerun.src.game.effects")) do
        local path = "okanerun/assets/images/buffs/" .. eff.id .. ".png"
        if love.filesystem.getInfo(path) then
            fore.graphics.scheduleLoad(eff.id, path)
            table.insert(loadedImages, eff.id)
        end
    end
end

function Scene.exit()
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

    -- Handle Input
    if fore.input:pressed("up") then
        currentRow = math.max(1, currentRow - 1)
        fore.audio.play("select", { volume = 0.1 })
    elseif fore.input:pressed("down") then
        currentRow = math.min(#rows, currentRow + 1)
        fore.audio.play("select", { volume = 0.1 })
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
        if r.type == "shop" then
            if not item.bought then
                local player = GameState.player
                if player.coins >= item.price then
                    if EffectSystem.apply(player, item.def) then
                        player.coins = player.coins - item.price
                        coins = player.coins
                        item.bought = true
                        fore.audio.play("accept", { pitch = 1.2 })
                    else
                        message = "Already at max amount!"
                        messageTimer = 2
                    end
                else
                    message = "Not enough coins!"
                    messageTimer = 2
                end
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
    local totalHeight = #rows * (CARD_H + ROW_SPACING) + MARGIN_TOP
    local visibleHeight = fore.data.height - 40
    local targetVScroll = 0
    if totalHeight > visibleHeight then
        local selY = MARGIN_TOP + (currentRow - 1) * (CARD_H + ROW_SPACING)
        targetVScroll = math.max(0, math.min(totalHeight - visibleHeight, selY - visibleHeight / 2 + CARD_H / 2))
    end
    verticalScroll = fore.math.lerp(verticalScroll, targetVScroll, dt * 8)
end

function Scene.draw()
    -- Background
    fore.graphics.rect(0, 0, fore.data.width, fore.data.height, {10, 15, 20})

    -- Header
    fore.graphics.text("SELECTION", 60, 25, 2.5, {255, 255, 255})
    fore.graphics.text("Coins: " .. coins, fore.data.width - 160, 30, 1.2, {255, 255, 120})

    love.graphics.push()
    love.graphics.translate(0, -verticalScroll)

    -- Rows
    for i, row in ipairs(rows) do
        local rowAnimOffset = math.max(0, 1 - (animTimer - i * 0.15) * 4)
        local ry = MARGIN_TOP + (i - 1) * (CARD_H + ROW_SPACING) + rowAnimOffset * 20
        local isRowFocused = (i == currentRow)
        local rowAlpha = math.min(1, (animTimer - i * 0.15) * 4)
        
        if rowAlpha > 0 then
            -- Row title
            local titleColor = isRowFocused and {255, 255, 255, rowAlpha * 255} or {127, 127, 127, rowAlpha * 180}
            fore.graphics.text(row.name:upper(), MARGIN_LEFT, ry - 25, 1, titleColor)

            -- Items
            love.graphics.push()
            love.graphics.translate(-row.scroll, 0)
            
            for j, item in ipairs(row.items) do
                local rx = MARGIN_LEFT + (j - 1) * (CARD_W + CARD_SPACING)
                local isSelected = (isRowFocused and row.selected == j)
                
                if row.type == "shop" or row.type == "selection" then
                    -- Card Background
                    local bgCol = {200, 200, 200}
                    local tint = {255, 255, 255}
                    if row.type == "shop" then 
                        tint = {200, 200, 255}
                    else
                        tint = {255, 200, 200}
                    end

                    -- Limit check for darkening
                    local limit = isAtLimit(GameState.player, item.def)
                    if limit then
                        bgCol = {100, 100, 100}
                    end
                    
                    if item.bought then
                        bgCol = {50, 50, 50}
                    end

                    -- Selection border
                    if isSelected then
                        fore.graphics.rect(rx - 2, ry - 2, CARD_W + 4, CARD_H + 4, {255, 255, 0, rowAlpha * 255}, true)
                    end
                    
                    -- Selected mark for debuff
                    if row.type == "selection" and selectedDebuff == item then
                        fore.graphics.rect(rx - 4, ry - 4, CARD_W + 8, CARD_H + 8, {255, 50, 50, rowAlpha * 255}, false)
                    end

                    -- Main Card
                    fore.graphics.rect(rx, ry, CARD_W, CARD_H, {bgCol[1]*tint[1]/255, bgCol[2]*tint[2]/255, bgCol[3]*tint[3]/255, rowAlpha * 255})
                    fore.graphics.rect(rx+4, ry+4, CARD_W-8, CARD_H-8, {255, 255, 255, rowAlpha * 150})
                    
                    -- Card Content
                    local txtCol = limit and {180, 180, 180, rowAlpha * 255} or {0, 0, 0, rowAlpha * 255}
                    if item.bought then txtCol = {120, 120, 120, rowAlpha * 255} end

                    -- Icon
                    fore.graphics.imageSafe(item.def.id, "missing", rx + CARD_W/2 - 16, ry + 10, 32, 32, 0, 0, 0, {0,0,0})
                    
                    -- ID/Name
                    fore.graphics.text(item.def.id:upper(), rx + 5, ry + 50, 1, txtCol, CARD_W - 10, "center")
                    
                    -- Desc
                    fore.graphics.textEx(EffectsDesc[item.def.id] or "No description", rx + 10, ry + 70, 0.8, txtCol, CARD_W - 20, "left")

                    -- Price for buffs
                    if row.type == "shop" and not item.bought then
                        fore.graphics.text(item.price .. "c", rx + CARD_W - 25, ry + CARD_H - 15, 0.7, {25, 25, 0, rowAlpha * 255})
                    end

                elseif row.type == "buttons" then
                    -- Button rendering
                    local btnW = 140
                    local btnH = 40
                    local bx = rx
                    local by = ry
                    
                    local bCol = isSelected and {255, 255, 255, rowAlpha * 255} or {100, 100, 100, rowAlpha * 150}
                    local tCol = isSelected and {0, 0, 0, rowAlpha * 255} or {200, 200, 200, rowAlpha * 200}
                    
                    fore.graphics.rect(bx, by, btnW, btnH, bCol)
                    fore.graphics.text(item.txt, bx, by + 12, 1, tCol, btnW, "center")
                end
            end
            love.graphics.pop()
        end
    end
    love.graphics.pop()

    -- Message overlay
    if messageTimer > 0 then
        local alpha = math.min(1, messageTimer * 2)
        fore.graphics.text(message, 0, fore.data.height - 40, 1, {1, 0.3, 0.3, alpha}, fore.data.width, "center")
    end
end

function Scene.exit()
    -- Apply selected
    if selectedDebuff then
        EffectSystem.apply(GameState.player, selectedDebuff.def)
    end
    fore.save.write()
end

return Scene
