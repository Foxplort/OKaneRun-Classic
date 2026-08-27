local Scene = {}

local Effects = require("okanerun.src.game.effects")
local EffectsDesc = require("okanerun.src.data.effectsDesc")

-- State
local sections = {}
local selectedSection = 1
local selectedIndex = 1
local verticalScroll = 0
local animTimer = 0
local hintText = "ESC: Return"

local function buildSections()
    sections = {}
    local buffs = {}
    local debuffs = {}

    for _, eff in pairs(Effects) do
        if eff.type == "buff" then
            table.insert(buffs, eff)
        elseif eff.type == "debuff" then
            table.insert(debuffs, eff)
        end
    end

    table.sort(buffs, function(a, b) return a.id < b.id end)
    table.sort(debuffs, function(a, b) return a.id < b.id end)

    if #buffs > 0 then
        table.insert(sections, { name = "BLESSINGS", items = buffs })
    end
    if #debuffs > 0 then
        table.insert(sections, { name = "CURSES", items = debuffs })
    end
end

local function getSelectedItem()
    local sec = sections[selectedSection]
    if sec then
        return sec.items[selectedIndex]
    end
    return nil
end

-- Scene API

function Scene.enter()
    buildSections()
    selectedSection = 1
    selectedIndex = 1
    verticalScroll = 0
    animTimer = 0

    -- Build hint text once based on input method
    if fore.save.get("hints") then
        if fore.input:getMethod() == "touch" then
            hintText = "TAP: Return"
        elseif fore.input:getMethod() == "gamepad" then
            hintText = "B: Return"
        else
            hintText = "ESC: Return"
        end
    else
        hintText = ""
    end

    fore.assets.scheduleLoad("missing", "okanerun/assets/images/buffs/missing.png", "nearest")
    for _, sec in ipairs(sections) do
        for _, eff in ipairs(sec.items) do
            local path = "okanerun/assets/images/buffs/" .. eff.id .. ".png"
            if fore.files.exists(path) then
                fore.assets.scheduleLoad(eff.id, path, "nearest")
            end
        end
    end

    -- Ensure nearest filtering on all loaded icons
    for _, sec in ipairs(sections) do
        for _, eff in ipairs(sec.items) do
            local img = fore.assets.getImage(eff.id)
            if img then img:setFilter("nearest", "nearest") end
        end
    end
    local missingImg = fore.assets.getImage("missing")
    if missingImg then missingImg:setFilter("nearest", "nearest") end
end

function Scene.exit()
    for _, sec in ipairs(sections) do
        for _, eff in ipairs(sec.items) do
            fore.assets.scheduleUnload(eff.id)
        end
    end
    fore.assets.scheduleUnload("missing")
end

function Scene.update(dt)
    animTimer = animTimer + dt

    local sec = sections[selectedSection]
    if not sec then return end

    local COLS = 5
    local CARD_W = 80
    local CARD_SPACING = 12
    local gridWidth = COLS * (CARD_W + CARD_SPACING)

    -- Navigation
    if fore.input:pressed("left") then
        selectedIndex = math.max(1, selectedIndex - 1)
        fore.audio.play("select", { volume = 0.1 })
    elseif fore.input:pressed("right") then
        selectedIndex = math.min(#sec.items, selectedIndex + 1)
        fore.audio.play("select", { volume = 0.1 })
    elseif fore.input:pressed("up") then
        local row = math.ceil(selectedIndex / COLS)
        local col = ((selectedIndex - 1) % COLS) + 1
        if row > 1 then
            selectedIndex = (row - 2) * COLS + col
        elseif selectedSection > 1 then
            selectedSection = selectedSection - 1
            local prevSec = sections[selectedSection]
            local lastRow = math.ceil(#prevSec.items / COLS)
            local lastRowItems = math.min(COLS, #prevSec.items - (lastRow - 1) * COLS)
            local targetCol = math.min(col, lastRowItems)
            selectedIndex = (lastRow - 1) * COLS + targetCol
        end
        fore.audio.play("select", { volume = 0.1, pitch = 1.1 })
    elseif fore.input:pressed("down") then
        local row = math.ceil(selectedIndex / COLS)
        local col = ((selectedIndex - 1) % COLS) + 1
        local newIdx = row * COLS + col
        if newIdx <= #sec.items then
            selectedIndex = newIdx
        elseif selectedSection < #sections then
            selectedSection = selectedSection + 1
            local nextSec = sections[selectedSection]
            selectedIndex = math.min(col, #nextSec.items)
        end
        fore.audio.play("select", { volume = 0.1, pitch = 0.9 })
    end

    local CARD_H = 100
    local SPACING = 12

    -- Calculate Y position of selected item across all sections
    local selY = 60 -- MARGIN_TOP
    for sIdx = 1, selectedSection do
        selY = selY + 30 -- section title
        local sItems = sections[sIdx].items
        if sIdx == selectedSection then
            local row = math.ceil(selectedIndex / COLS)
            selY = selY + (row - 1) * (CARD_H + SPACING)
        else
            selY = selY + math.ceil(#sItems / COLS) * (CARD_H + SPACING)
        end
        selY = selY + 10 -- gap
    end

    -- Calculate total content height across all sections
    local totalH = 0
    for _, s in ipairs(sections) do
        totalH = totalH + 30 -- title
        totalH = totalH + math.ceil(#s.items / COLS) * (CARD_H + SPACING)
        totalH = totalH + 10 -- gap
    end

    local visibleH = fore.data.height - 80
    local targetScroll = 0
    if totalH > visibleH then
        targetScroll = math.max(0, math.min(totalH - visibleH, selY - visibleH / 2 + CARD_H / 2))
    end
    verticalScroll = fore.math.lerp(verticalScroll, targetScroll, dt * 8)

    -- Return to menu
    local exitPressed = fore.input:pressed("cancel")
    if not exitPressed and fore.input:getMethod() == "touch" then
        exitPressed = fore.input:pressed("accept")
    end
    if exitPressed then
        fore.transition.start("dither", function()
            fore.scenes:goTo("menu")
        end, nil, 0, 0.5)
    end
end

function Scene.draw()
    local W = fore.data.width
    local H = fore.data.height

    -- Layout: grid on left, detail on right
    local COLS = 5
    local CARD_W = 80
    local CARD_H = 100
    local CARD_SPACING = 12
    local MARGIN_LEFT = 20
    local MARGIN_TOP = 60
    local gridWidth = COLS * (CARD_W + CARD_SPACING)
    local detailX = gridWidth + 40
    local detailW = W - detailX - 20
    local detailH = 200

    -- Background
    fore.draw2d.rect(0, 0, W, H, {10, 15, 20})

    -- Title
    fore.text.text("PENDIUM", MARGIN_LEFT, 20, 1.5, {255, 255, 255})

    -- Left side: scrollable grid
    fore.window.pushMatrix()
    fore.window.translateMatrix(0, -verticalScroll)

    local currentY = MARGIN_TOP
    for secIdx, sec in ipairs(sections) do
        local isCurrentSection = (secIdx == selectedSection)

        -- Section title
        local titleCol = isCurrentSection and {255, 255, 255} or {120, 120, 130}
        fore.text.text(sec.name, MARGIN_LEFT, currentY, 1, titleCol)
        currentY = currentY + 30

        -- Grid of cards
        local seen = fore.save.get("seen_effects") or {}
        for i, eff in ipairs(sec.items) do
            local col = ((i - 1) % COLS) + 1
            local row = math.ceil(i / COLS)
            local rx = MARGIN_LEFT + (col - 1) * (CARD_W + CARD_SPACING)
            local ry = currentY + (row - 1) * (CARD_H + CARD_SPACING)

            local isSelected = (isCurrentSection and selectedIndex == i)
            local isSeen = seen[eff.id]

            -- Theme colors (gray if unseen)
            local themeCol
            if isSeen then
                themeCol = eff.type == "buff" and {0, 200, 180} or {220, 20, 80}
            else
                themeCol = {80, 80, 90}
            end

            -- Card background
            local bgCol = isSeen and {40, 45, 55, 220} or {30, 32, 38, 200}
            if isSelected then
                bgCol = isSeen and {220, 240, 255, 255} or {120, 125, 135, 255}
                fore.draw2d.rect(rx - 3, ry - 3, CARD_W + 6, CARD_H + 6,
                    {themeCol[1], themeCol[2], themeCol[3], 150}, true)
            end

            -- Main card body
            fore.draw2d.rect(rx, ry, CARD_W, CARD_H, bgCol)

            -- Colored accent border
            fore.draw2d.rect(rx, ry, CARD_W, 3,
                {themeCol[1], themeCol[2], themeCol[3], isSelected and 255 or 180})

            -- Inner frame
            local innerAlpha = isSelected and 40 or 15
            fore.draw2d.rect(rx + 2, ry + 2, CARD_W - 4, CARD_H - 4,
                {themeCol[1], themeCol[2], themeCol[3], innerAlpha})

            -- Icon
            local iconCol = isSelected and {20, 25, 40, 255} or {themeCol[1], themeCol[2], themeCol[3], 255}
            local iconKey = isSeen and eff.id or "missing"
            fore.draw2d.imageSafe(iconKey, "missing", rx + CARD_W/2 - 16, ry + 8, 32, 32, 0, 0, 0, iconCol)

            -- Name
            local nameCol = isSelected and {20, 25, 40, 255} or {180, 200, 220, 255}
            if not isSeen then nameCol = isSelected and {60, 65, 75, 255} or {80, 85, 95, 255} end
            local displayName = isSeen and eff.id:upper() or "???"
            fore.text.text(displayName, rx + 4, ry + 50, 0.8, nameCol, CARD_W - 8, "center")
        end

        currentY = currentY + math.ceil(#sec.items / COLS) * (CARD_H + CARD_SPACING) + 10
    end

    fore.window.popMatrix()

    -- Right side: detail card
    local item = getSelectedItem()
    if item and detailW > 80 then
        local dx = detailX
        local dy = MARGIN_TOP
        local seen = fore.save.get("seen_effects") or {}
        local isSeen = seen[item.id]

        local themeCol
        if isSeen then
            themeCol = item.type == "buff" and {0, 200, 180} or {220, 20, 80}
        else
            themeCol = {80, 80, 90}
        end

        -- Detail panel background
        fore.draw2d.rect(dx, dy, detailW, detailH, {25, 30, 40, 230})
        fore.draw2d.rect(dx, dy, detailW, 4, {themeCol[1], themeCol[2], themeCol[3], 255})
        fore.draw2d.rect(dx + 2, dy + 2, detailW - 4, detailH - 4,
            {themeCol[1], themeCol[2], themeCol[3], 15})

        -- Large icon
        local iconKey = isSeen and item.id or "missing"
        fore.draw2d.imageSafe(iconKey, "missing", dx + detailW/2 - 32, dy + 15, 64, 64, 0, 0, 0,
            {themeCol[1], themeCol[2], themeCol[3], 255})

        -- Name
        local displayName = isSeen and item.id:upper() or "???"
        local nameCol = isSeen and {255, 255, 255} or {100, 100, 110}
        fore.text.text(displayName, dx + 10, dy + 90, 1.2, nameCol, detailW - 20, "center")

        -- Type badge
        if isSeen then
            local typeText = item.type == "buff" and "BLESSING" or "CURSE"
            local typeCol = item.type == "buff" and {0, 200, 180} or {220, 20, 80}
            fore.text.text(typeText, dx + 10, dy + 115, 0.7, typeCol, detailW - 20, "center")
        end

        -- Description
        if isSeen then
            local desc = EffectsDesc[item.id] or "No description"
            fore.text.textEx(desc, dx + 10, dy + 140, 0.8, {180, 200, 220}, detailW - 20, "left")
        else
            fore.text.text("[NOT YET DISCOVERED]", dx + 10, dy + 140, 0.8, {80, 85, 95}, detailW - 20, "center")
        end
    end

    -- Bottom hint
    fore.text.text(hintText, MARGIN_LEFT, H - 25, 0.8, {120, 120, 130})
end

return Scene
