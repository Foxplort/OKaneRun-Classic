local LevelLoader = {}

-- Default values for fields
local defaults = {
    walls = {z=0, t=0},
    ground = {},
    coins = {},
    cores = {}
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
local function fixWalls(walls)
    for _, w in ipairs(walls) do
        if w.z == nil then w.z = 0 end
        if w.t == nil then w.t = 0 end
    end
end

-- Main loader
function LevelLoader.load(path)
    -- load file as Lua table
    local chunk = love.filesystem.load(path)
    local data = chunk()

    -- Merge defaults
    applyDefaults(data, defaults)

    if data.walls then fixWalls(data.walls) end

    return data
end

return LevelLoader
