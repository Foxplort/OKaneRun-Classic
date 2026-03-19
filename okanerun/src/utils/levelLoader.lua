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
    -- load file as Lua table
    local chunk = love.filesystem.load(path)
    local data = chunk()

    -- Merge defaults
    applyDefaults(data, defaults)

    if data.cores then fixCores(data.cores) end
    if data.ground then fixGround(data.ground) end
    if not data.spawn then data.spawn = defaults.spawn end

    return data
end

return LevelLoader
