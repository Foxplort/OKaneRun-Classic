---@class fore.transition
local T = {}

-- Internal State
local active = false
local progress = 0
local current_style = "spike"
local on_covered = nil 
local on_complete = nil 
local la = require("fore.utils.loading")
local dither_shader
local freeze_thresholds = { start = 0, stop = 1 }

T.is_frozen = false

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

    -- DITHER
    dither_duration = 1.2,
    dither_steps = 10,
}

local function getSpikePolygon(x, width, spikeCount, depth, yShift)
    local h, verts = fore.data.height, {}
    local overdraw, step = 300, h / spikeCount
    local loopedShift = yShift % (step * 2)

    for i = -3, spikeCount + 3 do
        local isTip = (i % 2 ~= 0)
        table.insert(verts, x + width + (isTip and depth or 0))
        table.insert(verts, i * step + loopedShift)
    end
    table.insert(verts, x + width); table.insert(verts, h + overdraw)
    table.insert(verts, x);         table.insert(verts, h + overdraw)
    for i = spikeCount + 3, -3, -1 do
        local isTip = (i % 2 ~= 0)
        table.insert(verts, x - (isTip and depth or 0))
        table.insert(verts, i * step + loopedShift)
    end
    table.insert(verts, x);         table.insert(verts, -overdraw)
    table.insert(verts, x + width); table.insert(verts, -overdraw)
    return verts
end

function T.init()
    dither_shader = love.graphics.newShader("fore/assets/shaders/dither.glsl")
end

---@param style "spike"|"dither"
---@param callback_covered function Called when screen is fully black
---@param callback_complete function? Called when animation finishes
---@param f_start number? Progress (0-1) to freeze game (default 0)
---@param f_stop number? Progress (0-1) to unfreeze game (default 1)
function T.start(style, callback_covered, callback_complete, f_start, f_stop)
    if active then return end -- Don't interrupt an existing transition
    
    active = true
    T.is_frozen = true
    progress = 0
    current_style = style or "spike"
    on_covered = callback_covered
    on_complete = callback_complete

    -- Set custom freeze windows
    freeze_thresholds.start = f_start or 0
    freeze_thresholds.stop = f_stop or 1
    
    -- Initial check in case start is 0
    T.is_frozen = progress >= freeze_thresholds.start and progress < freeze_thresholds.stop
    
    la.start()
end

function T.update(dt)
    if not active then return end
    la.update(dt)
    
    local duration = (current_style == "dither") and T.config.dither_duration or T.config.duration

    -- Progress Logic
    if progress < 0.5 then
        progress = math.min(0.5, progress + dt / duration)
        if progress == 0.5 and on_covered then
            on_covered() 
            on_covered = nil
        end
        -- Stay at 0.5 if assets are still loading
        if progress == 0.5 and fore.graphics.pending_assets > 0 then return end
    else
        progress = progress + dt / duration
    end

    -- DYNAMIC FREEZE LOGIC
    local in_freeze_window = progress >= freeze_thresholds.start and progress < freeze_thresholds.stop
    local is_loading = (progress == 0.5 and fore.graphics.pending_assets > 0)
    
    T.is_frozen = in_freeze_window or is_loading

    -- Finish Logic
    if progress >= 1 then
        active = false
        T.is_frozen = false
        la.stop()
        if on_complete then 
            on_complete() 
            on_complete = nil
        end
    end
end

function T.draw()
    if not active then return end

    if current_style == "dither" and dither_shader then
        local steps = T.config.dither_steps
        local lagged_p = math.floor(progress * steps) / steps
        
        love.graphics.setShader(dither_shader)
        local dither_val = lagged_p < 0.5 and (lagged_p * 2) or (1 - (lagged_p - 0.5) * 2)
        dither_shader:send("progress", dither_val)
        
        love.graphics.rectangle("fill", 0, 0, fore.data.width, fore.data.height)
        love.graphics.setShader()
    elseif current_style == "spike" then
        local sw, c = fore.data.width, T.config
        local shapeW = sw * c.widthMult
        local buffer = 120 + c.xOffset
        local startX, endX = -shapeW - buffer, sw + buffer
        local totalDist = endX - startX

        for i, l in ipairs(c.layers) do
            local window = 1 - l.delay - l.finishEarly

            local p = math.max(0, math.min(1, (progress - l.delay) / window))
            local ease = p * p * (3 - 2 * p)
            
            local posX = startX + (totalDist * ease) + (i == 2 and c.xOffset or 0)
            posX = math.floor(posX / 2) * 2
            if c.dir == -1 then posX = sw - posX - shapeW end

            fore.graphics.polygon(
                getSpikePolygon(posX, shapeW, l.count, l.depth, progress * l.yShift),
                l.color, true
            )
        end
    end

    la.draw()
end

return T