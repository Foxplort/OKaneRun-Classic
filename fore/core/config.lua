local Config = {}

---Creates new config
---@param userConfig table User-provided config
---@return table config
function Config.init(userConfig)
    local config = {
        -- Game settings
        name = userConfig.name or "Untitled Game",
        version = userConfig.version or "1.0.0",
        width = userConfig.width or 640,
        height = userConfig.height or 360,
        scale = userConfig.scale or 2,

        -- Window settings
        minDT = userConfig.minDT ~= nil and userConfig.minDT or 1/20,
        windowScale = userConfig.windowScale or 2,
        
        -- Starting scene (must be provided)
        startScene = userConfig.startScene,
    }
    
    assert(config.startScene, "Config must specify a startScene")
    
    return config
end

return Config