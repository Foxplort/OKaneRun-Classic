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
    
    -- Gather current parameters from engine's central data storage
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

---Clears the entire window with a color
---@param color table { r, g, b } 0-255
function Window.clear(color)
    love.graphics.clear(color[1]/255, color[2]/255, color[3]/255, 1)
end

---Returns current window resolution (w, h)
---@return table<number, number> { width, height }
function Window.getResolution()
    return love.graphics.getDimensions()
end

---Pushes a coordinate transformation matrix onto the stack
function Window.pushMatrix()
    love.graphics.push()
end

---Pops a coordinate transformation matrix off the stack
function Window.popMatrix()
    love.graphics.pop()
end

---Scales the current transformation matrix
---@param sx number X scale
---@param sy number Y scale
function Window.scaleMatrix(sx, sy)
    love.graphics.scale(sx, sy)
end

---Blits a compiled canvas object centered on the screen buffer
---@param canvasObj table The fore.canvas instance wrapper
---@param x number Screen placement X
---@param y number Screen placement Y
function Window.drawCanvasToScreen(canvasObj, x, y)
    if not canvasObj or not canvasObj.native then return end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvasObj.native, x, y)
end

---Returns hardware render profile stats for debugging
---@return number Total drawcalls this frame
function Window.getDrawCalls()
    return love.graphics.getStats().drawcalls
end

---Translates the current coordinate system matrix
---@param tx number X offset
---@param ty number Y offset
function Window.translateMatrix(tx, ty)
    love.graphics.translate(tx, ty)
end

return Window