local CanvasUtil = {}
CanvasUtil.__index = CanvasUtil

local fore = nil

function CanvasUtil.init(foreRef)
    fore = foreRef
    return CanvasUtil
end

---Creates a new canvas target wrapper
---@param width number
---@param height number
---@param settings table { pixelated: boolean, depth: boolean, mode: "2d"|"3d" }
function CanvasUtil.new(width, height, settings)
    local instance = setmetatable({}, CanvasUtil)
    settings = settings or {}
    
    instance.width = width
    instance.height = height
    instance.mode = settings.mode or "2d" 
    
    instance.native = love.graphics.newCanvas(width, height, {
        type = "2d",
        format = settings.depth and "depth24stencil8" or "normal",
        msaa = settings.msaa or (settings.pixelated and 0 or fore.conf.msaa),
    })

    -- Apply filtering
    if settings.pixelated then
        instance.native:setFilter("nearest", "nearest")
    else
        instance.native:setFilter("linear", "linear")
    end

    return instance
end

---Start rendering onto this specific canvas
function CanvasUtil:beginRender()
    love.graphics.setCanvas({self.native, stencil = true})
end

---Stop rendering and return to the main hardware buffer
function CanvasUtil:endRender()
    love.graphics.setCanvas()
end

function CanvasUtil:clear(r, g, b, a)
    -- Store whatever canvas was currently active
    local oldCanvas = love.graphics.getCanvas()
    
    love.graphics.setCanvas(self.native)
    love.graphics.clear(r, g, b, a or 1)
    
    -- Restore it back to normal
    love.graphics.setCanvas(oldCanvas)
end

return CanvasUtil