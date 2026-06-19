local Draw2DUtil = {}

-- variables

local fore = nil

local TypeRef = require("fore.backend.love.graphics.types")
local setColor = TypeRef.setColor
local coloring = TypeRef.coloring
local filling = TypeRef.filling

-- init

function Draw2DUtil.init(foreRef)
    fore = foreRef
end

-- functions

function Draw2DUtil.rect(x, y, w, h, c, f)
    f = filling(f)

    setColor(c)
    love.graphics.rectangle(f, x, y, w, h)
end

function Draw2DUtil.circ(x, y, w, h, c, f, s)
    f = filling(f)
    if s == nil then s = 8 end

    x = x + w/2
    w = w/2
    y = y + h/2
    h = h/2

    setColor(c)
    love.graphics.ellipse(f, x, y, w, h, s)
end

---Draw a circle from the center
---@param x number
---@param y number
---@param r number|table
---@param c number|table
---@param f boolean
---@param s number
---@return nil
function Draw2DUtil.mCirc(x, y, r, c, f, s)
    f = filling(f)
    if s == nil then s = 8 end
    local w
    local h

    if type(r) == "number" then
        w = r
        h = r
    else
        w = r[1]
        h = r[2]
    end

    setColor(c)
    love.graphics.ellipse(f, x, y, w, h, s)
end

function Draw2DUtil.line(vertices, c, width)
    love.graphics.push("all")
    if width then love.graphics.setLineWidth(width) end
    setColor(c)
    love.graphics.line(vertices)
    love.graphics.pop()
end

function Draw2DUtil.arc(x, y, r, a1, a2, c, arcType, f, s, width)
    if not arcType then arcType = "closed" end

    love.graphics.push("all")

    if width then
        love.graphics.setLineWidth(width)
        love.graphics.setLineStyle("smooth")
    end

    setColor(c)
    love.graphics.arc(filling(f), arcType, x, y, r, a1, a2, s)

    love.graphics.pop()
end

function Draw2DUtil.tail(tail, color, baseWidth, outlineColor, outlineWidth)
    -- Push ALL state
    love.graphics.push("all")
    
    local function drawTail(tColor, tWidth)
        setColor(tColor)
        -- Draw segments
        for i = 1, #tail - 1 do
            local a = tail[i]
            local b = tail[i+1]
            
            -- Tapering logic
            local r = (i - 1) / (#tail - 1)
            local taper = math.sqrt(1 - r * r)
            local currWidth = tWidth * (0.4 + 0.6 * taper)
            
            -- Set width for this specific segment
            love.graphics.setLineStyle("smooth")
            love.graphics.setLineWidth(currWidth)
            love.graphics.setLineJoin("none") -- We use circles for joins instead
            
            -- Draw the joint circle
            love.graphics.circle("fill", a.x, a.y, currWidth / 2)
            -- Draw the segment line
            love.graphics.line(a.x, a.y, b.x, b.y)
            
            -- If it's the very last segment, cap the tip
            if i == #tail - 1 then
                love.graphics.circle("fill", b.x, b.y, currWidth / 2)
            end
        end
    end

    baseWidth = baseWidth or 5
    
    -- Draw outline
    if outlineColor then
        drawTail(outlineColor, baseWidth + (outlineWidth or 1.5))
    end
    
    -- Draw main tail
    drawTail(color, baseWidth)
    
    -- Restore state
    love.graphics.pop()
end

function Draw2DUtil.graph(points, x, y, w, h, color, min, max, target)
    -- Draw graph background
    Draw2DUtil.rect(x, y, w, h, {20, 20, 20, 200})
    Draw2DUtil.rect(x - 1, y - 1, w + 2, h + 2, {255, 255, 255, 40}, false)
    
    if not points or #points < 2 then return end
    
    -- Find min/max if not provided
    local mn, mx = min or math.huge, max or -math.huge
    if not min or not max then
        for _, v in ipairs(points) do
            if v < mn then mn = v end
            if v > mx then mx = v end
        end
    end
    local range = math.max(mx - mn, 0.001)
    
    -- Draw target line if provided
    if target then
        local targetY = y + h - ((target - mn) / range) * h
        targetY = math.max(y, math.min(y + h, targetY))
        Draw2DUtil.line({x, targetY, x + w, targetY}, {100, 255, 100, 100}, 1)
    end
    
    -- Draw graph line
    local vertices = {}
    for i, value in ipairs(points) do
        local px = x + (i-1)/(#points-1) * w
        local py = y + h - ((value - mn) / range) * h
        py = math.max(y, math.min(y + h, py))
        table.insert(vertices, px)
        table.insert(vertices, py)
    end
    Draw2DUtil.line(vertices, color, 1)
    
    -- Draw min/max labels
    fore.text.text(string.format("%.1f", mx), x + w - 35, y - 15, 0.7, {200, 200, 200})
    fore.text.text(string.format("%.1f", mn), x + w - 35, y + h + 2, 0.7, {200, 200, 200})
end

function Draw2DUtil.sparkline(points, x, y, w, h, color)
    if not points or #points < 2 then return end
    
    -- Find min/max
    local mn, mx = math.huge, -math.huge
    for _, v in ipairs(points) do
        if v < mn then mn = v end
        if v > mx then mx = v end
    end
    local range = math.max(mx - mn, 0.001)
    
    -- Draw the line
    local vertices = {}
    for i, value in ipairs(points) do
        local px = x + (i-1)/(#points-1) * w
        local py = y + h - ((value - mn) / range) * h
        py = math.max(y, math.min(y + h, py))
        table.insert(vertices, px)
        table.insert(vertices, py)
    end
    Draw2DUtil.line(vertices, color, 1.5)
end

function Draw2DUtil.polygon(vertices, c, f)
    f = filling(f)
    setColor(c)

    -- If we are filling, we need to handle concave shapes
    if f == "fill" then
        -- This breaks the shape into tiny triangles LÖVE can handle
        local success, triangles = pcall(love.math.triangulate, vertices)
        if success then
            for i, triangle in ipairs(triangles) do
                love.graphics.polygon("fill", triangle)
            end
        else
            -- Fallback: If triangulation fails (e.g. self-intersecting), 
            -- draw the standard polygon
            love.graphics.polygon("fill", vertices)
        end
    else
        love.graphics.polygon("line", vertices)
    end
end

return Draw2DUtil
