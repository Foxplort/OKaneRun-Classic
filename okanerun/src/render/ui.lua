local UI = {}

local coinTrackers = {}
local healthWave = 0

local function updateCoinTrackers()
    local p = GameState.player
    local coins = GameState.area.coins
    
    local active = {}
    for _, coin in ipairs(coins) do
        active[coin] = true
        if not coinTrackers[coin] then
            coinTrackers[coin] = {
                fill = 0, exit = 0, fade = 0,
                angle = math.atan2(coin.y - p.pos.y, coin.x - p.pos.x)
            }
        end
    end
    
    for coin, t in pairs(coinTrackers) do
        if active[coin] then
            local dx, dy = coin.x - p.pos.x, coin.y - p.pos.y
            local dist = math.sqrt(dx*dx + dy*dy)
            t.angle = math.atan2(coin.y - p.pos.y, coin.x - p.pos.x)
            
            if dist < 200 then
                t.fill = math.min(1, t.fill + 0.02)
                t.exit = math.max(0, t.exit - 0.03)
            else
                t.fill = math.max(0, t.fill - 0.03)
                t.exit = math.min(1, t.exit + 0.02)
            end
            t.fade = 1
        else
            t.fade = math.max(0, t.fade - 0.03)
            if t.fade <= 0 then coinTrackers[coin] = nil end
        end
    end
end

local function drawCoinIndicator()
    local p = GameState.player
    local coins = GameState.area.coins
    local full = #coins > 0
    local coinText = full and (#coins .. " left") or "Deposit!"
    fore.graphics.text(coinText, fore.data.width-80, 35, 1, 255, 80, "center")

    if full then
        local centerX, centerY = fore.data.width - 40, 40
        local radius, baseThick = 20, 3
        local time = love.timer.getTime()
        
        fore.graphics.arc(centerX, centerY, radius, 0, math.pi*2, {255,255,255,30}, "open", false, 32, baseThick)

        for coin, t in pairs(coinTrackers) do
            if t.fade > 0 then
                local angle = t.angle
                local arcSize
                
                if t.fill > 0 then
                    local fill = t.fill * t.fill
                    arcSize = 0.3 + (math.pi*2 - 0.3) * fill
                    if t.fill >= 0.99 then
                        local pulse = (math.sin(time * 8) + 1) / 2
                        arcSize = math.pi*2 + pulse * 0.2
                    end
                else
                    local dx = coin.x - p.pos.x
                    local dy = coin.y - p.pos.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    local minDist, maxDist = 50, 400
                    local tDist = 1 - math.max(0, math.min(1, (dist - minDist) / (maxDist - minDist)))
                    tDist = tDist * tDist * (3 - 2 * tDist)
                    arcSize = 0.1 + tDist * 0.6
                end
                
                local thickness = baseThick + t.fill * 4
                local r, g, b = 255, 220 + t.fill * 35, 100 + t.fill * 155
                local alpha = 255 * t.fade
                
                if arcSize > 0.01 then
                    fore.graphics.arc(centerX, centerY, radius, angle - arcSize/2, angle + arcSize/2,
                        {r, g, b, alpha}, "open", false, math.max(4, math.floor(arcSize*4)), thickness)
                end
                
                if t.fill > 0.5 then
                    local pulse = (math.sin(time * 5) + 1) / 2 * t.fill
                    fore.graphics.arc(centerX, centerY, radius + 2, angle - arcSize/2 - 0.05, angle + arcSize/2 + 0.05,
                        {255, 200, 0, 100 * pulse * t.fade}, "open", false, 8, thickness + 2)
                end
            end
        end
    end
end

local function drawHealthIndicator()
    local hp = GameState.player.hp.count
    local maxHp = GameState.player.hp.max
    if maxHp <= 0 then return end
    
    local startX, y = 0, fore.data.height - 45
    local size, spacing = 20, 24
    local perRow = 6
    local rows = math.ceil(maxHp / perRow)
    
    local lastRowCrystals = maxHp - (rows-1) * perRow
    local totalWidth = (math.min(maxHp, perRow) - 1) * spacing + size
    local bgHeight = rows * (size + 16)/2 - 4
    local bgTop = y - (rows-1) * (size + 16)/2 - size/2 - 6
    local bgBottom = bgTop + bgHeight + 8
    
    local bgPoints = {
        startX - 20, bgTop,
        startX + totalWidth + 20, bgTop - 2,
        startX + totalWidth + 16, bgBottom,
        startX - 16, bgBottom + 2,
    }
    fore.graphics.polygon(bgPoints, {0,0,0,180}, true)
    fore.graphics.polygon(bgPoints, {255,255,255,40}, false)

    startX = startX + 15
    y = y - 5
    
    for row = 0, rows - 1 do
        local rowY = y - row * (size - 4)
        local rowStart = row * perRow + 1
        local rowEnd = math.min(maxHp, rowStart + perRow - 1)
        
        for i = rowStart, rowEnd - 1 do
            local idx = i - rowStart
            local cx1 = startX + idx * spacing + (row*size/1.8)
            local cy1 = rowY + math.sin(healthWave * 2 + (i+row*1.8) * 1.5)
            local cx2 = startX + (idx + 1) * spacing + (row*size/2)
            local cy2 = rowY + math.sin(healthWave * 2 + (i+1+row*2) * 1.5)
            
            local isActive = i <= hp or (i+1) <= hp
            local lineColor = isActive and {255,200,255,60} or {80,80,100,30}
            fore.graphics.line({cx1 + size/3, cy1, cx2 - size/3, cy2}, lineColor, 1.5)
        end
    end
    
    for row = 0, rows - 1 do
        local rowY = y - row * (size - 4)
        local rowStart = row * perRow + 1
        local rowEnd = math.min(maxHp, rowStart + perRow - 1)
        
        for i = rowStart, rowEnd do
            local idx = i - rowStart
            local waveY = math.sin(healthWave * 2 + (i+row*2) * 1.5)
            local cx = startX + idx * spacing + (row*size/1.8)
            local cy = rowY + waveY
            local isActive = i <= hp
            local isLast = (i == hp)
            
            local points = {
                cx, cy - size/2,
                cx + size/2, cy,
                cx, cy + size/2,
                cx - size/2, cy,
            }
            
            if isActive then
                if isLast then
                    local glow = 0.7 + 0.3 * (math.sin(healthWave * 3 + i) + 1) / 2
                    fore.graphics.polygon(points, {255, 100 * glow, 200 * glow}, true)
                    fore.graphics.polygon({cx, cy - size/4, cx + size/4, cy, cx, cy + size/4, cx - size/4, cy},
                        {255,255,255,150}, true)
                else
                    fore.graphics.polygon(points, {255, 80, 180}, true)
                    fore.graphics.polygon({cx, cy - size/4, cx + size/4, cy, cx, cy + size/4, cx - size/4, cy},
                        {200,220,255,100}, true)
                end
                fore.graphics.polygon(points, {255,255,255,80}, false)
            else
                fore.graphics.polygon(points, {30,30,50}, true)
                fore.graphics.polygon(points, {60,60,80,80}, false)
            end
        end
    end
end

function UI.update(dt)
    updateCoinTrackers()
    healthWave = healthWave + dt
end

function UI.draw()
    drawHealthIndicator()
    drawCoinIndicator()
end

return UI
