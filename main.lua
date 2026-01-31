Fx = {
    r = require("src.renderer"),
    i = require("src.input"),
}

local config = {
    integerScaling = true
}

local canvas

-- GAME LOGIC

local player = {
    x = 20,
    y = 20,
    z = 0,
    j = {
        t = 0,
        cd = 200,
    },
    hp = 3,
    c = 0,
}

function love.load()
    canvas = love.graphics.newCanvas(640, 360)
    canvas:setFilter("nearest", "nearest")
end

function love.keypressed(k)
    if k == "space" then
        player.z = 20
        player.j.t = player.j.cd
    end
end

function love.update(dt)
    if Fx.i.i("d") then
        player.x = player.x + 20 * dt
    end
    if Fx.i.i("a") then
        player.x = player.x - 20 * dt
    end
    if Fx.i.i("w") then
        player.y = player.y - 20 * dt
    end
    if Fx.i.i("s") then
        player.y = player.y + 20 * dt
    end

    if player.z > 0 then
        player.z = player.z - 1 * dt
    elseif player.z < 0 then
        player.z = 0
    end
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.06, 0.08, 0.11)

    Fx.r.rect(player.x, player.y - player.z, 20, 20, {200, 200, 200})

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