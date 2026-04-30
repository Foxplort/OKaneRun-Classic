local LevelLoader = {}
local json = require("fore.utils.json")

function LevelLoader.loadJSON(path, customParser)
    local content, err = love.filesystem.read(path)
    if not content then error("Could not load " .. path .. ": " .. tostring(err)) end
    local raw = json.decode(content)
    
    local data = {}
    
    if customParser and type(customParser) == "function" then
        data = customParser(raw)
    else
        data = { objects = raw.objects or {} }
    end
    
    data.mapWidth = raw.mapWidth or 2000
    data.mapHeight = raw.mapHeight or 2000
    data.levelAuthor = raw.levelAuthor
    data.levelName = raw.levelName
    
    return data
end

return LevelLoader
