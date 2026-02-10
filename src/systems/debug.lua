local Debug = {}

Debug.enabled = false
Debug.providers = {}

-- Register a provider
-- fn must return a table of strings
function Debug.add(name, fn)
    Debug.providers[name] = fn
end

function Debug.remove(name)
    Debug.providers[name] = nil
end

local function bytesToMB(b)
    return string.format("%.2f MB", b / 1024 / 1024)
end

function Debug.draw()
    if not Debug.enabled then return end

    local lines = {}

    local function push(text)
        table.insert(lines, text)
    end

    -- Header
    push("OkaneRun [" .. Game.version .. "]")
    push("DEBUG (K to close)")
    push("----------------")

    -- Core stats
    push("FPS: " .. love.timer.getFPS())
    push(string.format("DT: %.2f ms", love.timer.getDelta() * 1000))
    push("RAM: " .. string.format("%.2f MB", collectgarbage("count") / 1024))

    push("")

    -- Providers
    for name, fn in pairs(Debug.providers) do
        local ok, data = pcall(fn)
        if ok and data then
            push("[" .. name .. "]")
            for _, l in ipairs(data) do
                push(l)
            end
            push("")
        end
    end

    -- ---- DRAW ----

    local x, y = 6, 6
    local lineH = 12
    local padding = 4

    local h = #lines * lineH + padding * 2
    local w = 0

    -- measure width
    local font = love.graphics.getFont()
    for _, l in ipairs(lines) do
        w = math.max(w, font:getWidth(l))
    end
    w = w + padding * 2

    -- background
    Fx.r.rect(
        x,
        y,
        w,
        h,
        {0, 0, 0, 160}
    )

    -- border
    Fx.r.rect(
        x - 1,
        y - 1,
        w + 2,
        h + 2,
        {255, 255, 255, 40},
        false
    )

    -- text
    for i, l in ipairs(lines) do
        Fx.r.text(
            l,
            x + padding,
            y + padding + (i - 1) * lineH,
            1,
            {255, 255, 255, 255}
        )
    end
end


return Debug
