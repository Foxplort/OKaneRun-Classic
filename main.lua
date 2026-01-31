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
local drawQueue = {}

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
        player = {
            w = 20,
            h = 20,
            hitbox = {
                w = 20,
                h = 6,
                xt = 0,
                yt = -3,
            },
        },
    },
}

local area = {
    walls = {
        {
            x = 200,
            y = 120,
            w = 30,
            h = 30,
            t = 30,
        },
        {
            x = 300,
            y = 170,
            w = 60,
            h = 20,
            t = 40,
        },
    },
    coins = {},
}

local function approach(v, target, amount)
    if v < target then
        return math.min(v + amount, target)
    elseif v > target then
        return math.max(v - amount, target)
    end
    return target
end

local function submitDraw(y, fn)
    drawQueue[#drawQueue + 1] = {
        y = y,
        fn = fn
    }
end

local function getPlayerHitbox()
    local hb = player.meta.player.hitbox
    return {
        x = player.x.pos + hb.xt,
        y = player.y.pos + hb.yt,
        w = hb.w,
        h = hb.h,
    }
end

-- wall collision zone (the base)
local function getWallHitbox(w)
    return {
        x = w.x,
        y = w.y - w.h, -- base thickness
        w = w.w,
        h = w.h,
    }
end

local function aabb(a, b)
    return a.x < b.x + b.w and
           a.x + a.w > b.x and
           a.y < b.y + b.h and
           a.y + a.h > b.y
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

    -- Apply X movement
    local nextX = player.x.pos + player.x.vel * dt
    local hb = getPlayerHitbox()

    hb.x = nextX + player.meta.player.hitbox.xt

    for _, w in ipairs(area.walls) do
        local wh = getWallHitbox(w)
        if aabb(hb, wh) then
            nextX = player.x.pos
            player.x.vel = 0
            break
        end
    end

    player.x.pos = nextX

    -- Apply Y movement
    local nextY = player.y.pos + player.y.vel * dt
    hb = getPlayerHitbox()
    hb.y = nextY + player.meta.player.hitbox.yt

    for _, w in ipairs(area.walls) do
        local wh = getWallHitbox(w)
        if aabb(hb, wh) then
            nextY = player.y.pos
            player.y.vel = 0
            break
        end
    end

    player.y.pos = nextY


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

    -- ## BASE DRAW PART ##

    -- shadow
    submitDraw(player.y.pos - 9999, function()
        local z = player.z.pos
        local pm = player.meta.player

        -- base shadow size from player size
        local baseW = pm.w * 1.2
        local baseH = pm.h * 0.35

        -- shrink with jump
        local shrink = math.max(0.45, 1 - z / 80)

        local w = baseW * shrink
        local h = baseH * shrink

        -- fade slightly with height
        local alpha = math.max(60, 160 - z * 1.5)

        -- center under feet
        local cx = player.x.pos + pm.w * 0.5
        local cy = player.y.pos - 2

        Fx.r.circ(
            cx - w * 0.5,
            cy - h * 0.5 + 2,
            w,
            h,
            {0, 0, 0, alpha}
        )
    end)



    -- player
    submitDraw(player.y.pos, function()
        Fx.r.rect(
            player.x.pos,
            player.y.pos - player.z.pos - player.meta.player.h,
            player.meta.player.w, player.meta.player.h,
            {200,200,200}
        )
    end)

    -- walls
    for _, i in pairs(area.walls) do
        local px = player.x.pos + player.meta.player.w * 0.5
        local py = player.y.pos

        submitDraw(i.y - 1, function()
            -- direction from player to wall
            local wx = i.x + i.w * 0.5
            local wy = i.y

            local dx = wx - px
            local dy = wy - py

            local len = math.sqrt(dx*dx + dy*dy)
            if len > 0 then
                dx = dx / len
                dy = dy / len
            end

            local shadowLen = 8
            local sx = dx * shadowLen
            local sy = dy * shadowLen

            -- shadow
            Fx.r.rect(
                i.x + sx,
                i.y - i.h - i.t + sy,
                i.w,
                i.h + i.t,
                {0, 0, 0, 80}
            )

            -- wall
            Fx.r.rect(
                i.x,
                i.y - i.h - i.t,
                i.w,
                i.h + i.t,
                {0,100,200}
            )

            -- roof
            Fx.r.rect(
                i.x,
                i.y - i.h - i.t,
                i.w,
                i.h,
                {0,50,100}
            )
        end)
    end

    -- ## END OF DRAW ##

    -- Depth based visual reder thingy
    table.sort(drawQueue, function(a, b)
        return a.y < b.y
    end)

    for _, item in ipairs(drawQueue) do
        item.fn()
    end

    drawQueue = {}

    if debug then
        local hb = getPlayerHitbox()
        Fx.r.rect(hb.x, hb.y, hb.w, hb.h, {255,0,0}, false)

        for _, w in ipairs(area.walls) do
            local wh = getWallHitbox(w)
            Fx.r.rect(wh.x, wh.y, wh.w, wh.h, {0,255,0}, false)
        end
    end

    -- ## USER INERTFACE ##

    if debug then
        Fx.r.text("player.pos - " .. tostring(math.floor(player.x.pos)) .. " / " .. tostring(math.floor(player.y.pos)), 10, 10, 1)
    end

    -- ## END OF UI ##

    love.graphics.setColor(1, 1, 1, 1)
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

    love.graphics.draw(canvas, screenX, screenY, 0, scale, scale)
end