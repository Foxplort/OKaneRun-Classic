local Debug = {}

Debug.enabled = false
Debug.providers = {}

local stats = {
    fps = 0,
    dt = 0,
    ram = 0,
    draws = 0,
    canvases = 0
}

local timer = 0
local updateRate = 0.2

function Debug.add(name, fn) Debug.providers[name] = fn end
function Debug.remove(name) Debug.providers[name] = nil end

function Debug.draw()
    if not Debug.enabled then return end

    -- Smooth counter updates
    timer = timer + love.timer.getDelta()
    if timer >= updateRate then
        local loveStats = love.graphics.getStats()
        stats.fps = love.timer.getFPS()
        stats.dt = love.timer.getDelta() * 1000
        stats.ram = collectgarbage("count") / 1024
        stats.draws = loveStats.drawcalls
        stats.canvases = loveStats.canvases
        timer = 0
    end

    local lines = {
        "OkaneRun [" .. Game.version .. "]",
        "DEBUG (K to close)",
        "----------------",
        string.format("FPS: %d", stats.fps),
        string.format("DT : %.2f ms", stats.dt),
        string.format("RAM: %.2f MB", stats.ram),
        string.format("DRW: %d", stats.draws),
        string.format("CNV: %d", stats.canvases),
        string.format("RES: %dx%d", Game.width, Game.height),
        string.format("AUD: %d", Fx.s.getStats().loaded),
        ""
    }

    for name, fn in pairs(Debug.providers) do
        local ok, data = pcall(fn)
        if ok and data then
            table.insert(lines, "[" .. name .. "]")
            for _, l in ipairs(data) do table.insert(lines, l) end
            table.insert(lines, "")
        end
    end

    -- Measuring and Drawing
    local x, y, lineH, padding = 6, 6, 12, 4
    local font = love.graphics.getFont()
    local w = 0
    for _, l in ipairs(lines) do w = math.max(w, font:getWidth(l)) end
    w = w + padding * 2
    local h = #lines * lineH + padding * 2

    Fx.r.rect(x, y, w, h, {0, 0, 0, 160})
    Fx.r.rect(x - 1, y - 1, w + 2, h + 2, {255, 255, 255, 40}, false)

    for i, l in ipairs(lines) do
        Fx.r.text(l, x + padding, y + padding + (i - 1) * lineH, 1, {1, 1, 1, 1})
    end
end

return Debug