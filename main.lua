Fx = {
    r = require("src.renderer"),
    i = require("src.input"),
}

local config = {
    integerScaling = true,
    fullScreen = false,
}

local canvas
local scale
local screenX
local screenY

local shader_code = [[
    extern number time;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 texcolor = Texel(texture, texture_coords);
        
        vec2 uv = texture_coords - 0.5;
        float dist = length(uv);
        float vignette = smoothstep(0.95, 0.4, dist);
        
        texcolor.rgb *= vignette;
        texcolor.rgb *= 1.1;
        
        return texcolor * color;
    }
]]
local myShader

-- GAME LOGIC

local debug = false
local drawQueue = {}

local mapWidth, mapHeight = 1200, 800
local camX, camY = 0, 0
local shakeAmount = 0
local uiShake = 0

local particles = {}

local trail = {}
local TRAIL_MAX = 30

local player = {
    x = {
        pos = 80,
        vel = 0,
    },
    y = {
        pos = 80,
        vel = 0,
    },
    z = {
        pos = 0,
        vel = 0,
    },
    jump = {
        cons = 0,
    },
    hp = {
        count = 3,
        max = 3,
    },
    coins = 0,
    visual = {
        sx = 1,
        sy = 1,
    },
    dead = false,
    meta = {
        move = {
            accel = 600,
            maxVel = 120,
            fri = 800,
        },
        jump = {
            vel = 260,
            g = 900,
            lim = 2,
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
        {
            x = 600,
            y = 230,
            w = 40,
            h = 40,
            t = 120,
        },
        {
            x = 200,
            y = 450,
            w = 10,
            h = 15,
            t = 10,
        },
    },
    ground = {
        { x = 50, y = 50, w = mapWidth-100, h = mapHeight-100 }
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

local function getGroundHitbox(g)
    return {
        x = g.x,
        y = g.y,
        w = g.w,
        h = g.h,
    }
end

local function aabb(a, b)
    return a.x < b.x + b.w and
           a.x + a.w > b.x and
           a.y < b.y + b.h and
           a.y + a.h > b.y
end

local function spawnDust(x, y, z)
    for i = 1, 4 do -- Spawn a small cluster
        table.insert(particles, {
            x = x + math.random(-5, 5),
            y = y,
            z = z,
            vx = math.random(-40, 40) + player.x.vel/2,
            vy = math.random(-20, 20) + player.y.vel/3, -- movement on the ground plane
            vz = math.random(10, 30),  -- initial "puff" upward
            life = 1.0,
            size = math.random(2, 4)
        })
    end
end

local function updateParticles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        
        -- Air resistance (drag)
        p.vx = approach(p.vx, 0, 100 * dt)
        p.vy = approach(p.vy, 0, 100 * dt)
        p.vz = p.vz - 20 * dt -- very light gravity for dust
        
        -- Move
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.z = p.z + p.vz * dt
        
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i) end
    end
end

local function checkOnGround(tx, ty)
    local hb = getPlayerHitbox()
    hb.x, hb.y = tx + player.meta.player.hitbox.xt, ty + player.meta.player.hitbox.yt
    for _, g in ipairs(area.ground) do
        if aabb(hb, getGroundHitbox(g)) then return true end
    end
    return false
end


-------------------
-- BASE LUA LOVE --
-------------------

function love.load()
    canvas = love.graphics.newCanvas(640, 360)
    canvas:setFilter("nearest", "nearest")
    myShader = love.graphics.newShader(shader_code)
end

function love.keypressed(k)
    if k == "space" then
        if player.jump.cons < player.meta.jump.lim then
            player.jump.cons = player.jump.cons + 1
            player.z.vel = player.meta.jump.vel
            player.jump.timer = player.meta.jump.cd
            player.visual.sx = 0.7 -- Thin
            player.visual.sy = 1.4 -- Tall
            if player.z.pos == 0 then
                spawnDust(player.x.pos + 10, player.y.pos, 0)
            end
        end
    elseif k == "k" then
        debug = not debug
    elseif k == "f11" then
        fullScreen = not fullScreen
        love.window.setFullscreen(fullScreen)
    end
end

local function damageHandler(dt)
    -- Fall into the pit
    if player.z.pos <= -150 then
        player.hp.count = player.hp.count - 1
        player.x.pos = 100
        player.y.pos = 100
        player.z.pos = 40
        shakeAmount = shakeAmount + 3
        uiShake = uiShake + 3
    end

    -- Getting the results
    if player.hp.count <= 0 then
        player.dead = true
    end
end

function love.update(dt)
    local lastX = player.x.pos
    local lastY = player.y.pos
    
    local isSubmerged = player.z.pos < 0
    local mx, my = 0, 0

    if not player.dead then
        if Fx.i.i("d") then mx = mx + 1 end
        if Fx.i.i("a") then mx = mx - 1 end
        if Fx.i.i("w") then my = my - 1 end
        if Fx.i.i("s") then my = my + 1 end
    end

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

    -- PIT COLLISION LOGIC
    if player.z.pos < 0 then
        local hb = getPlayerHitbox()
        local touchingGround = false
        
        for _, g in ipairs(area.ground) do
            if aabb(hb, getGroundHitbox(g)) then
                touchingGround = true
                break
            end
        end

        -- If we are below ground level and touching the ground area,
        -- that means we just walked into a "wall" of the pit.
        if touchingGround then
            player.x.pos = lastX
            player.y.pos = lastY
            -- Kill velocity so they don't keep sliding into the wall
            player.x.vel = 0
            player.y.vel = 0
        end
    end


    -- Z physics (jump)
    player.z.vel = player.z.vel - player.meta.jump.g * dt
    player.z.pos = player.z.pos + player.z.vel * dt

    local overPit = true
    for _, g in ipairs(area.ground) do
        if aabb(getPlayerHitbox(), getGroundHitbox(g)) then
            overPit = false
        end
    end

    -- Ground collision
    if player.z.pos < 0 and not overPit then
        -- Detect landing
        if player.z.vel < -50 then 
            player.visual.sx = 1.5 -- Wide
            player.visual.sy = 0.5 -- Short
            spawnDust(player.x.pos + 10, player.y.pos, 0)
        end
        player.z.pos = 0
        player.z.vel = 0
        player.jump.cons = 0
    end

    -- Visual recovery (bring scale back to 1)
    player.visual.sx = approach(player.visual.sx, 1, 2 * dt)
    player.visual.sy = approach(player.visual.sy, 1, 2 * dt)

    -- Trail
    table.insert(trail, 1, {
        x = player.x.pos,
        y = player.y.pos,
        z = player.z.pos
    })

    if #trail > TRAIL_MAX then
        table.remove(trail)
    end

    -- Camera target (center of screen)
    local targetX = player.x.pos + player.meta.player.w / 2 - 320 -- 320 is half-width
    local targetY = player.y.pos + player.meta.player.h / 2 - 180 -- 180 is half-height

    -- Smooth follow (Lerp)
    camX = camX + (targetX - camX) * 5 * dt
    camY = camY + (targetY - camY) * 5 * dt

    -- Constrain to map bounds
    camX = math.max(0, math.min(camX, mapWidth - 640))
    camY = math.max(0, math.min(camY, mapHeight - 360))

    shakeAmount = approach(shakeAmount, 0, 40 * dt)
    uiShake = approach(uiShake, 0, 40 * dt)

    updateParticles(dt)
    damageHandler(dt)
end


function love.draw()
    love.graphics.setCanvas({canvas, stencil = true})
    love.graphics.clear(0.01, 0.01, 0.02)

    love.graphics.push()
    love.graphics.translate(math.random(-shakeAmount, shakeAmount), math.random(-shakeAmount, shakeAmount))
    love.graphics.translate(-math.floor(camX), -math.floor(camY))

    -- ## BASE DRAW PART ##

    -- shadow
    submitDraw(-99, function()
        love.graphics.stencil(function()
            for _, g in ipairs(area.ground) do
                love.graphics.rectangle("fill", g.x, g.y, g.w, g.h)
            end
        end, "replace", 1)
        love.graphics.setStencilTest("equal", 1) -- "Only draw where ground IS"


        local z = player.z.pos
        local pm = player.meta.player

        -- base shadow size from player size
        local baseW = pm.w * 1.2
        local baseH = pm.h * 0.35

        -- shrink with jump
        local shadowZ = math.max(0, player.z.pos) -- Don't go below floor
        local shrink = math.max(0.45, 1 - shadowZ / 80)

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

        love.graphics.setStencilTest()
    end)



    -- player
    submitDraw(player.y.pos, function()
        local pm = player.meta.player
        local vs = player.visual
        
        -- Calculate visual dimensions
        local vw = pm.w * vs.sx
        local vh = pm.h * vs.sy

        local sortY = player.y.pos
        if player.z.pos < -5 then 
            sortY = -998
        end
        
        if player.z.pos < 0 then
            love.graphics.stencil(function()
                for _, g in ipairs(area.ground) do
                    love.graphics.rectangle("fill", g.x, g.y, g.w, g.h-player.meta.player.h)
                end
            end, "replace", 1)
            -- "notequal 1" means: Only draw where the stencil (ground) is NOT
            love.graphics.setStencilTest("notequal", 1)
        end

        Fx.r.rect(
            player.x.pos + (pm.w - vw) / 2,
            player.y.pos - player.z.pos - vh,
            vw, vh,
            {200, 200, 200, 255-math.abs(math.min(0, player.z.pos*6))}
        )

        love.graphics.setStencilTest() -- Reset stencil
    end)

    -- walls
    for _, i in pairs(area.walls) do
        -- I don't want them to flood anything outside of this loop
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

            local jumpFactor = math.max(0.2, 1 - math.max(player.z.pos, 0) / 80)

            local shadowLen = 7 * jumpFactor
            local sx = dx * shadowLen
            local sy = math.min(0, dy * shadowLen)

            local skew = (i.x - px) * 0.02
            skew = math.max(-6, math.min(6, skew))

            local alpha = 80 * jumpFactor

            -- shadow
            Fx.r.rect(
                i.x + sx + skew,
                i.y - i.h - i.t + sy,
                i.w,
                i.h + i.t,
                {0, 0, 0, alpha}
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

            -- Inner Highlight (Top Edge)
            Fx.r.rect(i.x, i.y - i.t - 2, i.w, 2, {0, 100, 200, 50}) 
            -- Inner Shadow (Right Edge)
            Fx.r.rect(i.x + i.w - 2, i.y - i.h - i.t, 2, i.h + i.t, {0, 25, 50, 50})
        end)
    end

    -- Ground
    for _, g in ipairs(area.ground) do
        submitDraw(-999, function()
            -- The Floor
            Fx.r.rect(g.x, g.y, g.w, g.h, {15, 20, 28})

            for gx = g.x, g.x + g.w, 40 do
                for gy = g.y, g.y + g.h, 40 do
                    -- Draw a tiny 1x1 dot or a subtle cross
                    Fx.r.rect(gx, gy, 1, 1, {150, 200, 255, 20})
                end
            end
        end)
        submitDraw(-1000, function()
            -- The Floor
            Fx.r.rect(g.x, g.y+20, g.w, g.h+20, {15, 20, 28, 30})
            Fx.r.rect(g.x, g.y+15, g.w, g.h+15, {15, 20, 28, 30})
            Fx.r.rect(g.x, g.y+10, g.w, g.h+10, {15, 20, 28, 30})
            Fx.r.rect(g.x, g.y+5, g.w, g.h+5, {15, 20, 28, 30})
        end)
    end

    -- Dust
    for _, p in ipairs(particles) do
        submitDraw(p.y, function()
            local alpha = p.life * 180
            local s = p.size * (0.5 + p.life * 0.5) -- Shrink over time
            
            -- Draw the dust puff
            Fx.r.rect(
                p.x - s/2, 
                p.y - p.z - s,
                s, s, 
                {255, 255, 255, alpha}
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
        for _, g in ipairs(area.ground) do
            local gh = getGroundHitbox(g)
            Fx.r.rect(gh.x, gh.y, gh.w, gh.h, {0,255,255}, false)
        end

        local hb = getPlayerHitbox()
        Fx.r.rect(hb.x, hb.y, hb.w, hb.h, {255,0,0}, false)

        for _, w in ipairs(area.walls) do
            local wh = getWallHitbox(w)
            Fx.r.rect(wh.x, wh.y, wh.w, wh.h, {0,255,0}, false)
        end
    end

    love.graphics.pop()

    -- ## USER INERTFACE ##

    love.graphics.push()
    if uiShake > 0 then
        love.graphics.translate(math.random(-1, 1), math.random(-1, 1))
    end

    -- health
    for i = 0, player.hp.max-1 do
        Fx.r.rect(19, Game.height-21-(i+1)*15, 15, 15, {0, 0, 0})
        Fx.r.rect(20, Game.height-20-(i+1)*15, 13, 13, {127, 0, 63})
        if i < player.hp.count then
            Fx.r.rect(20, Game.height-20-(i+1)*15, 13, 13, {255, 0, 127})
        end
    end

    -- coin count
    Fx.r.text(tostring(player.coins) .. "c", Game.width-225, 20, 1, 255, 200, "right")

    -- debug
    if debug then
        Fx.r.text("OkaneRun [" .. Game.version .. "]", 10, 10, 1)
        Fx.r.text("DEBUG (Press K to close)", 10, 20, 1)
        Fx.r.text("---", 10, 30, 1)
        Fx.r.text("FPS - " .. tostring(love.timer.getFPS()), 10, 40, 1)
        Fx.r.text("player.pos - " .. tostring(math.floor(player.x.pos)) .. " / " .. tostring(math.floor(player.y.pos)), 10, 50, 1)
    end

    love.graphics.pop()

    -- ## END OF UI ##

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setCanvas()

    -- Calculate scale to fill the window while keeping aspect ratio
    local screenW, screenH = love.graphics.getDimensions()
    scale = math.min(screenW / 640, screenH / 360)

    -- If integer scaling is ON, we floor the scale (e.g., 2.7x becomes 2.0x)
    if config.integerScaling then
        scale = math.max(1, math.floor(scale))
    end

    -- Calculate shift to the center
    screenX = math.floor((screenW - 640 * scale) / 2)
    screenY = math.floor((screenH - 360 * scale) / 2)

    love.graphics.setShader(myShader)
    love.graphics.draw(canvas, screenX, screenY, 0, scale, scale)
    love.graphics.setShader()
end