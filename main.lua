Fx = {
    r = require("src.renderer"),
    i = require("src.input"),
}

local config = {
    integerScaling = true
}

local canvas

-- GAME LOGIC

local debug = false

local player = {
    x = {
        pos = 20,
        vel = 0,
    },
    y = {
        pos = 20,
        vel = 0,
    },
    z = {
        pos = 0,
        vel = 0,
    },
    jump = {
        timer = 0,
    },
    hp = {
        count = 3,
        max = 3,
    },
    coins = 0,
    meta = {
        move = {
            accel = 600,
            maxVel = 120,
            fri = 800,
        },
        jump = {
            vel = 260,
            g = 900,
            cd = 200,
        },
    },
}

local function approach(v, target, amount)
    if v < target then
        return math.min(v + amount, target)
    elseif v > target then
        return math.max(v - amount, target)
    end
    return target
end


-------------------
-- BASE LUA LOVE --
-------------------

function love.load()
    canvas = love.graphics.newCanvas(640, 360)
    canvas:setFilter("nearest", "nearest")
end

function love.keypressed(k)
    if k == "space" then
        player.z.vel = player.meta.jump.vel
        player.jump.timer = player.meta.jump.cd
    elseif k == "k" then
        debug = not debug
    end
end

function love.update(dt)
    local mx, my = 0, 0

    if Fx.i.i("d") then mx = mx + 1 end
    if Fx.i.i("a") then mx = mx - 1 end
    if Fx.i.i("w") then my = my - 1 end
    if Fx.i.i("s") then my = my + 1 end

    -- Normalize diagonal movement
    if mx ~= 0 or my ~= 0 then
        local len = math.sqrt(mx*mx + my*my)
        mx, my = mx / len, my / len

        player.x.vel = player.x.vel + mx * player.meta.move.accel * dt
        player.y.vel = player.y.vel + my * player.meta.move.accel * dt
    else
        -- Apply friction when no input
        player.x.vel = approach(player.x.vel, 0, player.meta.move.fri * dt)
        player.y.vel = approach(player.y.vel, 0, player.meta.move.fri * dt)
    end

    -- Clamp max speed
    local speed = math.sqrt(player.x.vel^2 + player.y.vel^2)
    if speed > player.meta.move.maxVel then
        local s = player.meta.move.maxVel / speed
        player.x.vel = player.x.vel * s
        player.y.vel = player.y.vel * s
    end

    -- Apply movement
    player.x.pos = player.x.pos + player.x.vel * dt
    player.y.pos = player.y.pos + player.y.vel * dt

    -- Z physics (jump)
    player.z.vel = player.z.vel - player.meta.jump.g * dt
    player.z.pos = player.z.pos + player.z.vel * dt

    -- Ground collision
    if player.z.pos < 0 then
        player.z.pos = 0
        player.z.vel = 0
    end
end


function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.06, 0.08, 0.11)

    Fx.r.circ(player.x.pos-5, player.y.pos+17, 30, 6, {100, 100, 100})
    Fx.r.rect(player.x.pos, player.y.pos - player.z.pos, 20, 20, {200, 200, 200})

    -- UI

    if debug then
        Fx.r.text("test", 10, 10, 1, 1)
    end

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