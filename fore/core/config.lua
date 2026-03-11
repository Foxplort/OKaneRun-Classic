local Config = {}

---Creates new config
---@param userConfig table User-provided config
---@return table config
function Config.new(userConfig)
    local config = {
        -- Game settings
        name = userConfig.name or "Untitled Game",
        version = userConfig.version or "1.0.0",
        baseWidth = userConfig.baseWidth or 640,
        baseHeight = userConfig.baseHeight or 360,
        width = userConfig.baseWidth or 640,
        height = userConfig.baseHeight or 360,

        -- Window settings
        minDT = userConfig.minDT ~= nil and userConfig.minDT or 1/20,
        pixelBank = userConfig.pixelBank or 0,
        windowScale = userConfig.windowScale or 2,
        icon = userConfig.icon,
        title = userConfig.title or 
                ((userConfig.name or "Untitled Game") .. " [" .. (userConfig.version or "1.0.0") .. "]"),
        
        -- Window flags
        fullscreen = userConfig.fullScreen or false,
        resizable = userConfig.resizable or true,
        vsync = userConfig.vsync or true,
        borderless = userConfig.borderless or false,
        
        -- Starting scene (must be provided)
        startScene = userConfig.startScene,
    }
    
    assert(config.startScene, "Config must specify a startScene")
    
    return config
end

return Config