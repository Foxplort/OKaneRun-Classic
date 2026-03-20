local Renderer = {}

-- VARIABLES

Renderer.images = {}
Renderer.debugColor = {255, 0, 255}

local loader_channel = love.thread.getChannel("fore_loader")
local response_channel = love.thread.getChannel("fore_response")

Renderer.fore = nil
Renderer.pending_assets = 0

---@return table
function Renderer.init()
    Renderer.fonts = {
        small = love.graphics.newFont("fore/assets/fonts/JetBrainsMono.ttf", 8, "normal", 4),
        medium = love.graphics.newFont("fore/assets/fonts/JetBrainsMono.ttf", 8, "normal", 8),
        large = love.graphics.newFont("fore/assets/fonts/JetBrainsMono.ttf", 8, "normal", 16)
    }

    return Renderer
end

-- INNER FUNCTIONS

local function coloring(c, pA)
    pA = pA or 1
    if not c then return 1, 1, 1, pA end
    local r, g, b, a = 1, 1, 1, 1
    if type(c) == "number" then
        local v = c > 1 and c / 255 or c
        r, g, b = v, v, v
    elseif type(c) == "table" then
        r, g, b, a = c[1] or 255, c[2] or 255, c[3] or 255, c[4] or 255
        if r > 1 or g > 1 or b > 1 or a > 1 then
            r, g, b, a = r/255, g/255, b/255, a/255
        end
    end
    return r, g, b, a * pA
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

---Draw a circle from the center
---@param x number
---@param y number
---@param r number|table
---@param c number|table
---@param f boolean
---@param s number
---@return nil
function Renderer.mCirc(x, y, r, c, f, s)
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
        love.graphics.setLineStyle("smooth")
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
    
    -- Restore state
    love.graphics.pop()
end

function Renderer.graph(points, x, y, w, h, color, min, max, target)
    -- Draw graph background
    Renderer.rect(x, y, w, h, {20, 20, 20, 200})
    Renderer.rect(x - 1, y - 1, w + 2, h + 2, {255, 255, 255, 40}, false)
    
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
        Renderer.line({x, targetY, x + w, targetY}, {100, 255, 100, 100}, 1)
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
    Renderer.line(vertices, color, 1)
    
    -- Draw min/max labels
    Renderer.text(string.format("%.1f", mx), x + w - 35, y - 15, 0.7, {200, 200, 200})
    Renderer.text(string.format("%.1f", mn), x + w - 35, y + h + 2, 0.7, {200, 200, 200})
end

function Renderer.sparkline(points, x, y, w, h, color)
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
    Renderer.line(vertices, color, 1.5)
end

function Renderer.polygon(vertices, c, f)
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

function Renderer.text(text, x, y, s, c, wrap, align)
    s = s or {1, 1}
    if type(s) == "number" then s = {s, s} end
    local sx = s[1] or 1
    local sy = s[2] or s[1]
    align = align or "left"

    local font = "small"
    local fontScale = math.max(sx, sy)
    if fontScale < 1.5 then font = "small"
    elseif fontScale < 2.5 then font = "medium"
    else font = "large" end 
    love.graphics.setFont(Renderer.fonts[font])

    setColor(c)
    if wrap then
        love.graphics.printf(text, x, y, wrap/sx, align, 0, sx, sy)
    else
        love.graphics.print(text, x, y, 0, sx, sy)
    end
end

local function parseStyledText(str, defaultColor)
    local segments, stack, i = {}, { defaultColor }, 1
    str = str:gsub("%[br%]", "\n")
    while i <= #str do
        local s, e, cap = str:find("%[c=([%w_,]+)%]", i)
        local cs, ce = str:find("%[/c%]", i)
        local nextS = s or (#str + 1)
        local nextE = cs or (#str + 1)
        if nextS < nextE and nextS == i then
            local p = {}
            for v in cap:gmatch("[^,]+") do table.insert(p, tonumber(v) or v) end
            table.insert(stack, p)
            i = e + 1
        elseif nextE <= nextS and nextE == i then
            if #stack > 1 then table.remove(stack) end
            i = ce + 1
        else
            local stop = math.min(nextS, nextE)
            table.insert(segments, { text = str:sub(i, stop - 1), color = stack[#stack] })
            i = stop
        end
    end
    return segments
end

local function layoutStyledText(segments, maxWidth, scale)
    local lines, currentLine, currentWidth = {}, {}, 0
    local function flush()
        table.insert(lines, currentLine)
        currentLine, currentWidth = {}, 0
    end
    for _, seg in ipairs(segments) do
        local lastPos = 1
        while lastPos <= #seg.text do
            local nlS, nlE = seg.text:find("\n", lastPos)
            local part = seg.text:sub(lastPos, (nlS or 0) - 1)
            if #part > 0 then
                for word, space in part:gmatch("([^%s]+)(%s*)") do
                    local fW = word .. space
                    local w = Renderer.getTextWidth(fW, scale)
                    if maxWidth and currentWidth + w > maxWidth and currentWidth > 0 then flush() end
                    table.insert(currentLine, { text = fW, color = seg.color })
                    currentWidth = currentWidth + w
                end
            end
            if nlS then flush() lastPos = nlE + 1 else break end
        end
    end
    table.insert(lines, currentLine)
    return lines
end

function Renderer.textAdvanced(text, x, y, s, c, wrap, align)
    s = type(s) == "table" and s[1] or s or 1
    local _, _, _, baseAlpha = coloring(c)
    local h = love.graphics.getFont():getHeight() * s
    local lines = layoutStyledText(parseStyledText(text, c), wrap, s)

    for i, line in ipairs(lines) do
        local cx = x
        if align and align ~= "left" and wrap then
            local lw = 0
            for _, seg in ipairs(line) do lw = lw + Renderer.getTextWidth(seg.text, s) end
            cx = align == "center" and x + (wrap - lw)/2 or x + wrap - lw
        end
        for _, seg in ipairs(line) do
            local r, g, b, a = coloring(seg.color, baseAlpha)
            love.graphics.setColor(r, g, b, a)
            love.graphics.print(seg.text, cx, y + (i - 1) * h, 0, s, s)
            cx = cx + Renderer.getTextWidth(seg.text, s)
        end
    end
end

function Renderer.textEx(text, x, y, s, c, wrap, align)
    if type(text) == "string" and text:find("%[c=") or text:find("%[br") then
        return Renderer.textAdvanced(text, x, y, s, c, wrap, align)
    else
        return Renderer.text(text, x, y, s, c, wrap, align)
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

Renderer.pending_assets = 0

function Renderer.loadImage(name, path, imgtype)
    local loader = love.thread.getChannel("fore_loader")
    Renderer.pending_assets = Renderer.pending_assets + 1
    loader:push({
        cmd = "load_image", 
        name = name, 
        path = path, 
        imgtype = imgtype or "nearest"
    })
end

function Renderer.update_loading()
    local response = love.thread.getChannel("fore_response")
    local uploads_this_frame = 0
    local max_uploads = 1 -- Keep it strictly to 1 to kill the lag

    while uploads_this_frame < max_uploads do
        local msg = response:pop()
        if not msg then break end

        if msg.type == "image" then
            local img = love.graphics.newImage(msg.data)
            img:setFilter(msg.imgtype, msg.imgtype)
            Renderer.images[msg.name] = img
            Renderer.pending_assets = Renderer.pending_assets - 1
            uploads_this_frame = uploads_this_frame + 1

        elseif msg.type == "audio" then
            -- Creating a Source from SoundData is instantaneous!
            local source = love.audio.newSource(msg.data, "static")
            Renderer.fore.audio.sounds[msg.name] = {
                name = msg.name,
                source = source,
                category = msg.category,
                stream = false
            }
            Renderer.pending_assets = Renderer.pending_assets - 1
            -- We don't increment uploads_this_frame here because 
            -- Audio Sources don't block the GPU like Textures do.
        
        elseif msg.type == "error" then
            Renderer.pending_assets = Renderer.pending_assets - 1
        end
    end
end

function Renderer.getImage(name)
    return Renderer.images[name]
end

function Renderer.unloadImage(name)
    Renderer.images[name] = nil
    --collectgarbage()
end

return Renderer
