Fx = {
    r = require("src.utils.renderer"), -- R - Render
    i = require("src.utils.input"), -- I - Input
    m = require("src.utils.math"), -- M - Math
    el = require("src.game.buffs"), -- EL - Effect List
    es = require("src.game.buffSystem"), -- ES - Effect System
    dq = require("src.utils.drawqueue"), -- DQ - Draw Queue
    cl = require("src.utils.collision"), -- Cl - Collision
    obj = { -- OBJ - Renderable Objects
        player = require("src.objects.player"),
        world = require("src.objects.world"),
        ui = require("src.objects.ui"),
    },
    db = { -- DB - DeBug systems
        e = require("src.game.buffUI"), -- db.E - Effects
    },
}

local config = {
    integerScaling = true,
    fullScreen = false,
}

local canvas
local scale
local screenX
local screenY

local myShader

-- GAME LOGIC

debug = false

local camX, camY = 0, 0
local shakeAmount = 0
local uiShake = 0

local particles = {}

local trail = {}
local TRAIL_MAX = 30

player = Fx.obj.player.baseData
area = Fx.obj.world.testArea

BuffUIDat = {
    visible = false,
    x = 10,
    y = 80,
    cols = 8,
    size = 20,
    padding = 4,
    selected = 1,
}

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
        p.vx = Fx.m.approach(p.vx, 0, 100 * dt)
        p.vy = Fx.m.approach(p.vy, 0, 100 * dt)
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
    local hb = Fx.cl.getPlayerHitbox()
    hb.x, hb.y = tx + player.meta.player.hitbox.xt, ty + player.meta.player.hitbox.yt
    for _, g in ipairs(area.ground) do
        if Fx.m.aabb(hb, Fx.cl.getGroundHitbox(g)) then return true end
    end
    return false
end


-------------------
-- BASE LUA LOVE --
-------------------

function love.load()
    canvas = love.graphics.newCanvas(640, 360)
    canvas:setFilter("nearest", "nearest")
    myShader = love.graphics.newShader("assets/shaders/main.glsl")

    Fx.r.loadImage("missing", "assets/images/buffs/missing.png")

    for id, buff in pairs(Fx.el) do
        local path = "assets/images/buffs/" .. buff.id .. ".png"
        if love.filesystem.getInfo(path) then
            Fx.r.loadImage(buff.id, path)
        end
    end

    Fx.db.e.load()
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
    elseif k == "b" then
        BuffUIDat.visible = not BuffUIDat.visible
    elseif BuffUIDat.visible then
        Fx.db.e.keypressed(player, k)
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
        player.x.vel = Fx.m.approach(player.x.vel, 0, player.meta.move.fri * dt)
        player.y.vel = Fx.m.approach(player.y.vel, 0, player.meta.move.fri * dt)
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
    local hb = Fx.cl.getPlayerHitbox()

    hb.x = nextX + player.meta.player.hitbox.xt

    for _, w in ipairs(area.walls) do
        local wh = Fx.cl.getWallHitbox(w)
        if Fx.m.aabb(hb, wh) then
            nextX = player.x.pos
            player.x.vel = 0
            break
        end
    end

    for _, c in ipairs(area.cores) do
        local ch = {x=c.x, y=c.y, w=40, h=40}
        if Fx.m.aabb(hb, ch) then
            nextX = player.x.pos
            player.x.vel = 0
            if #player.coinChain > 0 then
                player.coins = player.coins + #player.coinChain
                Fx.es.remove(player, "coin", #player.coinChain)
                player.coinChain = {}
            end
            break
        end
    end

    player.x.pos = nextX

    -- Apply Y movement
    local nextY = player.y.pos + player.y.vel * dt
    hb = Fx.cl.getPlayerHitbox()
    hb.y = nextY + player.meta.player.hitbox.yt

    for _, w in ipairs(area.walls) do
        local wh = Fx.cl.getWallHitbox(w)
        if Fx.m.aabb(hb, wh) then
            nextY = player.y.pos
            player.y.vel = 0
            break
        end
    end

    for _, c in ipairs(area.cores) do
        local ch = {x=c.x, y=c.y, w=40, h=40}
        if Fx.m.aabb(hb, ch) then
            nextY = player.y.pos
            player.y.vel = 0
            if #player.coinChain > 0 then
                player.coins = player.coins + #player.coinChain
                player.coinChain = {}
                Fx.es.remove(player, "coin")
            end
            break
        end
    end

    player.y.pos = nextY

    -- PIT COLLISION LOGIC
    if player.z.pos < 0 then
        local hb = Fx.cl.getPlayerHitbox()
        local touchingGround = false
        
        for _, g in ipairs(area.ground) do
            if Fx.m.aabb(hb, Fx.cl.getGroundHitbox(g)) then
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
        if Fx.m.aabb(Fx.cl.getPlayerHitbox(), Fx.cl.getGroundHitbox(g)) then
            overPit = false
        end
    end

    -- Collect coins
    for i, c in ipairs(area.coins) do
        if Fx.m.aabb(Fx.cl.getPlayerHitbox(), {x=c.x, y=c.y-3, w=15, h=6}) then
            local coin = {
                x = c.x,
                y = c.y,
                z = player.z.pos,

                followIndex = #player.coinChain * 6 + 6
            }

            table.insert(player.coinChain, coin)
            table.remove(area.coins, i)
            Fx.es.apply(player, Fx.el["coin"])
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
    player.visual.sx = Fx.m.approach(player.visual.sx, 1, 2 * dt)
    player.visual.sy = Fx.m.approach(player.visual.sy, 1, 2 * dt)

    -- Trail
    table.insert(trail, 1, {
        x = player.x.pos,
        y = player.y.pos,
        z = player.z.pos
    })

    if #trail > TRAIL_MAX then
        table.remove(trail)
    end

    for _, coin in ipairs(player.coinChain) do
        local p = trail[coin.followIndex]
        if p then
            coin.x = coin.x + (p.x - coin.x) * 12 * dt
            coin.y = coin.y + (p.y - coin.y) * 12 * dt
            coin.z = coin.z + (p.z - coin.z) * 10 * dt
        end
    end

    -- Camera target (center of screen)
    local targetX = player.x.pos + player.meta.player.w / 2 - 320 -- 320 is half-width
    local targetY = player.y.pos + player.meta.player.h / 2 - 180 -- 180 is half-height

    -- Smooth follow (Lerp)
    camX = camX + (targetX - camX) * 5 * dt
    camY = camY + (targetY - camY) * 5 * dt

    -- Constrain to map bounds
    camX = math.max(0, math.min(camX, area.mapWidth - 640))
    camY = math.max(0, math.min(camY, area.mapHeight - 360))

    shakeAmount = Fx.m.approach(shakeAmount, 0, 40 * dt)
    uiShake = Fx.m.approach(uiShake, 0, 40 * dt)

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

    Fx.obj.player.render() -- render player + shadow

    Fx.obj.world.renderWalls() -- render walls
    Fx.obj.world.renderGround() -- render ground
    Fx.obj.world.renderCoins() -- render coins
    Fx.obj.world.renderCores() -- render cores

    -- Dust
    for _, p in ipairs(particles) do
        Fx.dq.submitDraw(p.y, function()
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

    Fx.dq.draw() -- draw items in order

    Fx.obj.player.shiluette() -- Player's shiluette


    if debug then
        for _, g in ipairs(area.ground) do
            local gh = Fx.cl.getGroundHitbox(g)
            Fx.r.rect(gh.x, gh.y, gh.w, gh.h, {0,255,255}, false)
        end

        local hb = Fx.cl.getPlayerHitbox()
        Fx.r.rect(hb.x, hb.y, hb.w, hb.h, {255,0,0}, false)

        for _, w in ipairs(area.walls) do
            local wh = Fx.cl.getWallHitbox(w)
            Fx.r.rect(wh.x, wh.y, wh.w, wh.h, {0,255,0}, false)
        end

        for _, c in ipairs(area.coins) do
            local ch = {x=c.x, y=c.y-3, w=15, h=6}
            Fx.r.rect(ch.x, ch.y, ch.w, ch.h, {255,255,127}, false)
        end
    end

    love.graphics.pop()

    -- ## USER INERTFACE ##

    love.graphics.push()
    if uiShake > 0 then
        love.graphics.translate(math.random(-1, 1), math.random(-1, 1))
    end

    Fx.obj.ui.draw()

    Fx.db.e.draw(player)

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