local Renderer = {}

-- VARIABLES

Renderer.images = {}
Renderer.debugColor = {255, 0, 255}

local loader_channel = love.thread.getChannel("fore_loader")
local response_channel = love.thread.getChannel("fore_response")

local TypeRef = require("fore.backend.love.graphics.types")
local setColor = TypeRef.setColor
local coloring = TypeRef.coloring
local filling = TypeRef.filling

Renderer.fore = nil
Renderer.pending_assets = 0

Renderer.asset_registry = {}
Renderer.planned_loads = {}
Renderer.planned_unloads = {}

---Initializes the backend
---@param foreRef table
function Renderer.init(foreRef)
    Renderer.fore = foreRef
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

function Renderer.tail(tail, color, baseWidth, outlineColor, outlineWidth)
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
    Renderer.fore.text.text(string.format("%.1f", mx), x + w - 35, y - 15, 0.7, {200, 200, 200})
    Renderer.fore.text.text(string.format("%.1f", mn), x + w - 35, y + h + 2, 0.7, {200, 200, 200})
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
    
    Renderer.asset_registry[name] = {path = path, imgtype = imgtype or "linear"}
    
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
    Renderer.asset_registry[name] = nil
    --collectgarbage()
end

-- SMART ASSET LOADING SYSTEM

function Renderer.scheduleLoad(name, path, imgtype)
    Renderer.planned_loads[name] = {path = path, imgtype = imgtype or "linear"}
end

function Renderer.scheduleUnload(name)
    Renderer.planned_unloads[name] = true
end

function Renderer.flushAssetSchedule()
    local available_paths = {}
    for existing_name, data in pairs(Renderer.asset_registry) do
        available_paths[data.path] = available_paths[data.path] or {}
        table.insert(available_paths[data.path], existing_name)
    end

    for new_name, load_data in pairs(Renderer.planned_loads) do
        local path = load_data.path
        local existing_names = available_paths[path]

        if existing_names and #existing_names > 0 then
            local exact_match = false
            for _, ename in ipairs(existing_names) do
                if ename == new_name then
                    exact_match = true
                    break
                end
            end

            if exact_match then
                Renderer.planned_unloads[new_name] = nil
            else
                local reused_name = nil
                for i, ename in ipairs(existing_names) do
                    if Renderer.planned_unloads[ename] then
                        reused_name = ename
                        table.remove(existing_names, i)
                        break
                    end
                end

                if reused_name then
                    Renderer.images[new_name] = Renderer.images[reused_name]
                    Renderer.asset_registry[new_name] = Renderer.asset_registry[reused_name]
                    
                    Renderer.images[reused_name] = nil
                    Renderer.asset_registry[reused_name] = nil
                    
                    Renderer.planned_unloads[reused_name] = nil
                    Renderer.planned_unloads[new_name] = nil
                    
                    table.insert(existing_names, new_name)
                else
                    local source_name = existing_names[1]
                    Renderer.images[new_name] = Renderer.images[source_name]
                    Renderer.asset_registry[new_name] = {path = path, imgtype = load_data.imgtype}
                    Renderer.planned_unloads[new_name] = nil
                    table.insert(existing_names, new_name)
                end
            end
        else
            Renderer.loadImage(new_name, path, load_data.imgtype)
            Renderer.planned_unloads[new_name] = nil
        end
    end

    for name, _ in pairs(Renderer.planned_unloads) do
        Renderer.unloadImage(name)
    end

    Renderer.planned_loads = {}
    Renderer.planned_unloads = {}
end

return Renderer
