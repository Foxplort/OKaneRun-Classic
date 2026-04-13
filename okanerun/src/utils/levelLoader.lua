local LevelLoader = {}

-- Default values for fields
local defaults = {
    ground = {},
    coins = {},
    spawn = {x=150, y=150},
    cores = {w=40,h=40},
}

-- Merge defaults
local function applyDefaults(tbl, defs)
    for k,v in pairs(defs) do
        if tbl[k] == nil then
            tbl[k] = v
        end
    end
end

-- Merge missing fields for walls
local function fixCores(cores)
    for _, c in ipairs(cores) do
        if c.w == nil then c.w = 40 end
        if c.h == nil then c.h = 40 end
    end
end

local function fixGround(ground)
    for _, g in ipairs(ground) do
        if g.w == nil then g.w = g.xp - g.x end
        if g.h == nil then g.h = g.yp - g.y end
    end
end

-- Main loader
function LevelLoader.load(path)
    local data
    if path:match("%.json$") then
        local json = require("fore.utils.json")
        local content, err = love.filesystem.read(path)
        if not content then error("Could not load " .. path .. ": " .. tostring(err)) end
        local raw = json.decode(content)
        
        -- Transform editor raw objects back into game's level format
        data = { ground = {}, coins = {}, cores = {}, spawn = {x=150, y=150} }
        if raw.objects then
            for _, obj in ipairs(raw.objects) do
                if obj.type == "ground" then
                    table.insert(data.ground, {x = obj.x, y = obj.y, xp = obj.x + obj.w, yp = obj.y + obj.h, w = obj.w, h = obj.h})
                elseif obj.type == "coins" then
                    table.insert(data.coins, {x = obj.x, y = obj.y})
                elseif obj.type == "cores" then
                    table.insert(data.cores, {x = obj.x, y = obj.y, w = obj.w, h = obj.h})
                elseif obj.type == "spawn" then
                    data.spawn = {x = obj.x, y = obj.y}
                end
            end
        end
        -- Add mapWidth / mapHeight for camera constraints
        data.mapWidth = raw.mapWidth or 2000
        data.mapHeight = raw.mapHeight or 2000
    else
        -- load file as Lua table
        local chunk = love.filesystem.load(path)
        if chunk then
            data = chunk()
        else
            error("Could not load lua map: " .. path)
        end
    end

    -- Merge defaults
    applyDefaults(data, defaults)

    if data.cores then fixCores(data.cores) end
    if data.ground then fixGround(data.ground) end
    if not data.spawn then data.spawn = defaults.spawn end

    return data
end

return LevelLoader
