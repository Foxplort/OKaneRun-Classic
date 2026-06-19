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
