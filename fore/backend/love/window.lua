local Window = {}
local fore = nil

---Initializes the window backend reference
---@param foreRef table Engine instance
function Window.init(foreRef)
    fore = foreRef
    Window.apply() -- Set up the initial window on start
end

---Applies the current engine data state to the physical window
function Window.apply()
    if not fore then return end
    
    -- Gather current parameters from your engine's central data storage
    local w = fore.data.width * fore.data.scale
    local h = fore.data.height * fore.data.scale
    
    love.window.setMode(w, h, { 
        fullscreen = fore.data.fullscreen,
        vsync = fore.data.vsync,
        resizable = fore.data.resizable,
        minwidth = fore.data.width,
        minheight = fore.data.height,
        msaa = (fore.conf.pixelated and 4) or 0,
    })

    love.window.setTitle(fore.data.title)
    
    if fore.data.icon then
        -- LÖVE requires an ImageData object for the icon
        love.window.setIcon(love.image.newImageData(fore.data.icon))
    end
end

---Sets whether the window is fullscreen at runtime
---@param enabled boolean
function Window.setFullscreen(enabled)
    fore.data.fullscreen = enabled
    love.window.setFullscreen(enabled, "desktop")
end

return Window