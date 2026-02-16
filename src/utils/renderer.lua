local Renderer = {}

-- VARIABLES

Renderer.images = {}
Renderer.debugColor = {255, 0, 255}

-- INNER FUNCTIONS

local function coloring(c)
    -- default: white
    if c == nil then
        return 1, 1, 1, 1
    end

    -- grayscale number (0–255)
    if type(c) == "number" then
        local v = c > 1 and c / 255 or c
        return v, v, v, 1
    end

    -- table color
    if type(c) == "table" then
        local r = c[1] or 255
        local g = c[2] or 255
        local b = c[3] or 255
        local a = c[4] or 255

        -- auto-detect format
        if r > 1 or g > 1 or b > 1 or a > 1 then
            return r/255, g/255, b/255, a/255
        else
            return r, g, b, a
        end
    end

    -- fallback
    return 1, 1, 1, 1
end

local function setColor(c)
    love.graphics.setColor(coloring(c))
end

local function filling(f)
    if f == nil then f = true end
    if f then f = "fill" else f = "line" end
    return f
end

-- BASIC FUNCTIONS

function Renderer.rect(x, y, w, h, c, f)
    f = filling(f)

    setColor(c)
    love.graphics.rectangle(f, x, y, w, h)
end

function Renderer.circ(x, y, w, h, c, f, s)
    f = filling(f)
    if s == nil then s = 8 end

    x = x + w/2
    w = w/2
    y = y + h/2
    h = h/2

    setColor(c)
    love.graphics.ellipse(f, x, y, w, h, s)
end

function Renderer.line(vertices, c, width)
    love.graphics.push("all")
    if width then love.graphics.setLineWidth(width) end
    setColor(c)
    love.graphics.line(vertices)
    love.graphics.pop()
end

function Renderer.arc(x, y, r, a1, a2, c, arcType, f, s, width)
    if not arcType then arcType = "closed" end

    love.graphics.push("all")

    if width then
        love.graphics.setLineWidth(width)
        love.graphics.setLineStyle("rough")
    end

    setColor(c)
    love.graphics.arc(filling(f), arcType, x, y, r, a1, a2, s)

    love.graphics.pop()
end

function Renderer.tail(tail, color, baseWidth)
    -- Push ALL state
    love.graphics.push("all")
    
    setColor(color)
    baseWidth = baseWidth or 5
    
    -- Draw segments
    for i = 1, #tail - 1 do
        local a = tail[i]
        local b = tail[i+1]
        
        -- Tapering logic
        local t = (i - 1) / (#tail - 1)
        local taper = math.sqrt(1 - t * t)
        local currWidth = baseWidth * (0.4 + 0.6 * taper)
        
        -- Set width for this specific segment
        love.graphics.setLineStyle("rough")
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
    
    -- Restore state
    love.graphics.pop()
end

function Renderer.polygon(vertices, c, f)
    f = filling(f)
    setColor(c)

    -- If we are filling, we need to handle concave shapes (like spikes)
    if f == "fill" then
        -- This breaks the "saw" shape into tiny triangles LÖVE can handle
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
        -- Lines don't have the convex issue
        love.graphics.polygon("line", vertices)
    end
end

function Renderer.text(text, x, y, s, c, wrap, align)
    s = s or {1, 1}
    if type(s) == "number" then s = {s, s} end
    local sx = s[1] or 1
    local sy = s[2] or s[1]
    align = align or "left"

    setColor(c)
    if wrap then
        love.graphics.printf(text, x, y, wrap, align, 0, sx, sy)
    else
        love.graphics.print(text, x, y, 0, sx, sy)
    end
end

function Renderer.getTextWidth(text, scale)
    scale = scale or 1
    local font = love.graphics.getFont()
    return font:getWidth(text) * scale
end

function Renderer.getTextHeight(scale)
    scale = scale or 1
    local font = love.graphics.getFont()
    return font:getHeight() * scale
end

function Renderer.imageScaled(name, x, y, sx, sy, r, ox, oy, c)
    local img = Renderer.images[name]
    if not img then return end

    r = r or 0
    ox = ox or 0
    oy = oy or 0
    sx = sx or 1
    sy = sy or 1

    setColor(c)
    love.graphics.draw(img, x, y, r, sx, sy, ox, oy)
end

function Renderer.imageSafe(name, fallback, x, y, w, h, r, ox, oy, c)
    local img = Renderer.images[name] or Renderer.images[fallback]
    if not img then return end

    r = r or 0
    ox = ox or 0
    oy = oy or 0
    local iw, ih = img:getDimensions()
    w = w or iw
    h = h or ih

    setColor(c)
    love.graphics.draw(img, x, y, r, w/iw, h/ih, ox, oy)
end

function Renderer.image(name, x, y, w, h, c)
    local img = Renderer.images[name]
    if not img then return end

    setColor(c)
    local iw, ih = img:getDimensions()
    love.graphics.draw(img, x, y, 0, w/iw, h/ih)
end


-- IMAGES LOADING HANDLER

function Renderer.loadImage(name, path, imgtype)
    local img = love.graphics.newImage(path)
    imgtype = imgtype or "nearest" 
    img:setFilter(imgtype, imgtype)
    Renderer.images[name] = img
end

function Renderer.getImage(name)
    return Renderer.images[name]
end

function Renderer.unloadImage(name)
    Renderer.images[name] = nil
    --collectgarbage()
end

return Renderer
