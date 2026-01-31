Fx = {
    render = require("src.renderer"),
}

local config = {
    integerScaling = true
}

local canvas

function love.load()
    canvas = love.graphics.newCanvas(640, 360)
    canvas:setFilter("nearest", "nearest")
end

function love.update(dt)
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.06, 0.08, 0.11)

    Fx.render.rect(10, 10, 20, 20, {200, 200, 200})

    love.graphics.setCanvas()

    -- Calculate scale to fill the window while keeping aspect ratio
    local screenW, screenH = love.graphics.getDimensions()
    local scale = math.min(screenW / 640, screenH / 360)

    -- If integer scaling is ON, we floor the scale (e.g., 2.7x becomes 2.0x)
    if config.integerScaling then
        scale = math.max(1, math.floor(scale))
    end

    -- Calculate shift to the center
    local screenX = math.floor((screenW - 640 * scale) / 2)
    local screenY = math.floor((screenH - 360 * scale) / 2)

    -- UPDATE INPUT DATA FOR MOUSE MATH
    -- Input.scale = scale
    -- Input.offsetX = screenX
    -- Input.offsetY = screenY

    love.graphics.draw(canvas, screenX, screenY, 0, scale, scale)
end