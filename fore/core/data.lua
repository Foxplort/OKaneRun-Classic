local Data = {}

---Creates new dataset
---@param userConfig table User-provided config
---@param config table Premade config 
---@return table data
function Data.init(userConfig, config)
    local data = {
        -- Window
        width = config.width,
        height = config.height,
        pixelBank = userConfig.pixelBank or 0,
        icon = userConfig.icon,
        title = userConfig.title or 
                ((userConfig.name or "Untitled Game") .. " [" .. (userConfig.version or "1.0.0") .. "]"),
                
        -- Window flags
        fullscreen = userConfig.fullscreen or false,
        resizable = userConfig.resizable or true,
        vsync = userConfig.vsync or true,
        borderless = userConfig.borderless or false,
        pixelated = userConfig.pixelated or false,

        deadzone = userConfig.deadzone or 0.4,
    }

    return data
end

return Data