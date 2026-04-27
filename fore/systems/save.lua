---@meta
local json = require("fore.utils.json")

---@class fore.save
---@field private _data table The internal storage for all saved states
---@field private _path string The filename for the save data
local save = {
    _data = {
        engine = {
            vsync = 1,
            fullscreen = false,
            volume = 100,
            dev_mode = false,
        },
        game = {} -- User defined data goes here
    },
    _path = "fore_save.json"
}

local fore

---Initializes the save system and merges existing files with defaults.
---@param user_defaults table? Optional table of default game-specific stats/settings
---@param foreref fore engine reference
function save.init(user_defaults, foreref)
    fore = foreref

    if user_defaults then
        save._data.game = user_defaults
    end

    if love.filesystem.getInfo(save._path) then
        local content = love.filesystem.read(save._path)
        local ok, decoded = pcall(json.decode, content)
        if ok and type(decoded) == "table" then
            -- Merge loaded data into our current data structure
            for category, values in pairs(decoded) do
                if save._data[category] then
                    for k, v in pairs(values) do
                        save._data[category][k] = v
                    end
                end
            end
        end
    end

    fore.data.devmode = save._data.engine.dev_mode
end

---Writes the current state to the disk.
---@return boolean success
function save.write()
    local ok, str = pcall(json.encode, save._data)
    if ok then
        return love.filesystem.write(save._path, str)
    end
    return false
end

---Sets an engine-level setting (e.g. vsync, resolution).
---@param key string
---@param value any
function save.set_engine(key, value)
    save._data.engine[key] = value

    if key == "dev_mode" then
        fore.data.devmode = value
        if fore.debug.enabled then fore.debug.enabled = false end
    end
end

---Gets an engine-level setting.
---@param key string
---@return any
function save.get_engine(key)
    return save._data.engine[key]
end

---Sets a game-specific piece of data.
---@param key string
---@param value any
function save.set(key, value)
    save._data.game[key] = value
end

---Retrieves a game-specific piece of data.
---@param key string
---@return any
function save.get(key)
    return save._data.game[key]
end

return save
