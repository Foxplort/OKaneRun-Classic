local LevelLoader = {}
local json = require("fore.utils.json")

function LevelLoader.loadJSON(path, customParser)
    local content, err = fore.files.read(path)
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

function LevelLoader.load(path, customParser)
    local data
    if path:match("%.json$") then
        data = LevelLoader.loadJSON(path, customParser)
    elseif path:match("%.4lf$") then
        local mntPath = "temp_mount_level_" .. tostring(fore.time.getTicks()):gsub("%.", "")
        
        -- use FileData to bypass OS path constraints and PhysFS extension restrictions
        local fd = love.filesystem.newFileData(path)
        if not fd then error("Could not load file data for " .. path) end
        
        local success = love.filesystem.mount(fd, mntPath)
        if not success then error("Could not mount FileData for " .. path) end
        
        data = LevelLoader.loadJSON(mntPath .. "/meta.json", customParser)
        love.filesystem.unmount(fd)
    else
        -- load file as Lua table
        local chunk = love.filesystem.load(path)
        if chunk then
            data = chunk()
        else
            error("Could not load lua map: " .. path)
        end
        data.levelName = string.match(path, "([^/\\]*)$")
        if data.levelName then data.levelName = string.sub(data.levelName, 1, -5) end
        
        -- A lua map generally returns the data directly, but we can pass it to customParser if needed
        -- Note: We only call customParser if the data looks like raw json (e.g., has an objects array).
        if customParser and type(customParser) == "function" and data.objects then
            local parsed = customParser(data)
            for k, v in pairs(parsed) do data[k] = v end
            data.objects = nil
        end
    end
    return data
end

return LevelLoader
