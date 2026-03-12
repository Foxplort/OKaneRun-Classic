local T = {}

local active, covered = false, false
local t, onCovered = 0, nil
local la = require("okanerun.src.render.loading")

T.config = {
    duration = 3.0,
    dir = 1,
    widthMult = 8.0,
    layers = {
        {count = 12, depth = 30, yShift = 400, color = {0, 20, 10, 130}, delay = 0, finishEarly = 0},
        {count = 12, depth = 30, yShift = 200, color = {5, 35, 35}, delay = 0.04, finishEarly = 0.04},
        {count = 11, depth = 20, yShift = 50, color = {30, 70, 120, 80}, delay = 0.1, finishEarly = 0.1},
        {count = 10, depth = 30, yShift = -150, color = {30, 70, 110}, delay = 0.16, finishEarly = 0.16},
    },
    xOffset = 0,
}

local function getSpikePolygon(x, width, spikeCount, depth, yShift)
    local h, verts = fore.data.height, {}
    local overdraw, step = 300, fore.data.height / spikeCount
    local loopedShift = yShift % (step * 2)

    -- Right Edge
    for i = -3, spikeCount + 3 do
        local isTip = (i % 2 ~= 0)
        table.insert(verts, x + width + (isTip and depth or 0))
        table.insert(verts, i * step + loopedShift)
    end

    -- Bottom Cap
    table.insert(verts, x + width); table.insert(verts, h + overdraw)
    table.insert(verts, x);         table.insert(verts, h + overdraw)

    -- Left Edge
    for i = spikeCount + 3, -3, -1 do
        local isTip = (i % 2 ~= 0)
        table.insert(verts, x - (isTip and depth or 0))
        table.insert(verts, i * step + loopedShift)
    end

    -- Top Cap
    table.insert(verts, x);         table.insert(verts, -overdraw)
    table.insert(verts, x + width); table.insert(verts, -overdraw)

    return verts
end

function T.cover(callback)
    if active and not covered then
        onCovered = callback
        return 
    end

    if active and covered then
        t = 0
        covered = false
        onCovered = callback
        return
    end

    la.start()
    active = true
    t = 0
    covered = false
    onCovered = callback
end

function T.update(dt)
    la.update(dt)
    if not active then return end
    t = t + dt / T.config.duration
    
    if not covered and t >= 0.5 then
        covered = true
        if onCovered then
            onCovered()
            onCovered = nil
        end
    end
    if t >= 1 then active = false; covered = false; la.stop() end
end

function T.draw()
    if not active then return end

    local sw, c = fore.data.width, T.config
    local shapeW = sw * c.widthMult
    local buffer = 120 + c.xOffset
    local startX, endX = -shapeW - buffer, sw + buffer
    local totalDist = endX - startX

    for i, l in ipairs(c.layers) do
        local window = 1 - l.delay - l.finishEarly
        local progress = math.max(0, math.min(1, (t - l.delay) / window))
        
        local ease = progress * progress * (3 - 2 * progress)
        
        local posX = startX + (totalDist * ease) + (i == 2 and c.xOffset or 0)
        posX = math.floor(posX / 2) * 2
        if c.dir == -1 then posX = sw - posX - shapeW end

        fore.graphics.polygon(
            getSpikePolygon(posX, shapeW, l.count, l.depth, t * l.yShift),
            l.color, true
        )
    end

    la.draw()
end

return T
