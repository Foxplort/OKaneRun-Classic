local Scene = {}

-- ### HELPER FUNCTIONS ###

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

local function spawnLandingDust(x, y, z)
    local count = 8
    for i = 1, count do
        local a = (i / count) * math.pi * 2
        local r = math.random(30, 60)

        table.insert(particles, {
            x = x,
            y = y,
            z = z,
            vx = math.cos(a) * r,
            vy = math.sin(a) * r/2,
            vz = math.random(2, 10),
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

local function followTarget(coin, tx, ty, tz, dt)
    local dx = coin.x - tx
    local dy = coin.y - ty
    local dz = coin.z - tz

    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
    if dist == 0 then return end

    local desired = coin.spacing
    local diff = dist - desired

    -- Soft clamp
    local pull = Fx.m.clamp(diff * 8, -200, 200)

    coin.x = coin.x - (dx / dist) * pull * dt
    coin.y = coin.y - (dy / dist) * pull * dt
    --coin.z = coin.z - (dz / dist) * pull * dt
    coin.z = coin.z + (tz - coin.z) * 6 * dt
end

local function damageHandler(dt)
    -- Fall into the pit
    if player.z.pos <= -150 then
        player.hp.count = player.hp.count - 1

        -- Safe Teleport
        player.x.pos = 100
        player.y.pos = 100
        player.z.pos = 40

        -- Coins teleport
        for i, coin in ipairs(player.coinChain) do
            coin.x = player.x.pos
            coin.y = player.y.pos
            coin.z = player.z.pos
        end

        -- Effects
        shakeAmount = shakeAmount + 3
        uiShake = uiShake + 3
    end

    -- Getting the results
    if player.hp.count <= 0 then
        player.dead = true
    end
end

-- ### MAIN FUNCTIONS ###

function Scene.load()
end

function Scene.keypressed(k)
    if k == "space" then
        if player.jump.cons < player.meta.jump.lim then
            player.jump.cons = player.jump.cons + 1
            player.z.vel = player.meta.jump.vel
            player.jump.timer = player.meta.jump.cd
            player.visual.sx = 0.7 -- Thin
            player.visual.sy = 1.4 -- Tall
            if true then -- P.S. ADD CHECK IF ON THE GROUND!
                spawnDust(player.x.pos + 10, player.y.pos, player.z.pos)
            end
        end
    end
end

function Scene.update(dt)
    local lastX = player.x.pos
    local lastY = player.y.pos
    local lastZ = player.z.pos
    
    local isSubmerged = player.z.pos < 0
    local mx, my = 0, 0

    if not player.dead then
        if Fx.i.i("d") then mx = mx + 1 end
        if Fx.i.i("a") then mx = mx - 1 end
        if Fx.i.i("w") then my = my - 1 end
        if Fx.i.i("s") then my = my + 1 end
    end

    local targetVX = mx * player.meta.move.maxVel
    local targetVY = my * player.meta.move.maxVel

    local accel = player.meta.move.accel
    local decel = player.meta.move.fri

    -- X axis
    if targetVX ~= 0 then
        player.x.vel = Fx.m.approach(player.x.vel, targetVX, accel * dt)
    else
        player.x.vel = Fx.m.approach(player.x.vel, 0, decel * dt)
    end

    -- Y axis
    if targetVY ~= 0 then
        player.y.vel = Fx.m.approach(player.y.vel, targetVY, accel * dt)
    else
        player.y.vel = Fx.m.approach(player.y.vel, 0, decel * dt)
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

        if Fx.m.aabb3(
            hb,
            player.z.pos,
            player.meta.player.hitbox.t,
            wh,
            w.z or 0,
            w.t or math.huge
        ) then
            nextX = player.x.pos
            player.x.vel = 0
            break
        end
    end

    for _, c in ipairs(area.cores) do
        local ch = {x=c.x, y=c.y-40, w=40, h=40}
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

        if Fx.m.aabb3(
            hb,
            player.z.pos,
            player.meta.player.hitbox.t,
            wh,
            w.z or 0,
            w.t or math.huge
        ) then
            nextY = player.y.pos
            player.y.vel = 0
            break
        end
    end

    for _, c in ipairs(area.cores) do
        local ch = {x=c.x, y=c.y-40, w=40, h=40}
        if Fx.m.aabb(hb, ch) then
            nextY = player.y.pos
            player.y.vel = 0
            if #player.coinChain > 0 then
                player.coins = player.coins + #player.coinChain
                Fx.es.remove(player, "coin", #player.coinChain)
                player.coinChain = {}
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

    -- PLATFORM / WALL TOP LANDING
    if player.z.vel <= 0 then -- only when falling
        local hb = Fx.cl.getPlayerHitbox()
        local playerBottom = player.z.pos
        local playerTop = player.z.pos + player.meta.player.hitbox.t

        for _, w in ipairs(area.walls) do
            local wh = Fx.cl.getWallHitbox(w)
            local wallTop = (w.z or 0) + (w.t or 0)

            -- XY overlap?
            if Fx.m.aabb(hb, wh) then
                -- Did we cross the top this frame?
                if lastZ >= wallTop and playerBottom <= wallTop then
                    -- LAND
                    if player.z.vel < -50 then 
                        player.visual.sx = 1.5 -- Wide
                        player.visual.sy = 0.5 -- Short
                        spawnLandingDust(player.x.pos + 10, player.y.pos, wallTop)
                    end
                    player.z.pos = wallTop
                    player.z.vel = 0
                    player.jump.cons = 0
                    break
                end
            end
        end
    end

    -- CEILING / UNDERSIDE COLLISION
    if player.z.vel > 0 then -- only when moving upward
        local hb = Fx.cl.getPlayerHitbox()
        local playerTop = player.z.pos + player.meta.player.hitbox.t

        for _, w in ipairs(area.walls) do
            local wh = Fx.cl.getWallHitbox(w)
            local wallBottom = (w.z or 0)

            -- XY overlap?
            if Fx.m.aabb(hb, wh) then
                -- Did we hit the underside?
                if lastZ + player.meta.player.hitbox.t <= wallBottom
                and playerTop >= wallBottom then

                    player.z.pos = wallBottom - player.meta.player.hitbox.t
                    player.z.vel = 0
                    break
                end
            end
        end
    end

    local overPit = true
    for _, g in ipairs(area.ground) do
        if Fx.m.aabb(Fx.cl.getPlayerHitbox(), Fx.cl.getGroundHitbox(g)) then
            overPit = false
        end
    end

    -- Collect coins
    for i, c in ipairs(area.coins) do
        if Fx.m.aabb(Fx.cl.getPlayerHitbox(), {x=c.x, y=c.y-3, w=10, h=6}) and player.z.pos < 16 then
            local SPACING = 10

            local coin = {
                x = c.x,
                y = c.y,
                z = player.z.pos,
                spacing = SPACING --* (#player.coinChain + 1)
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
            spawnLandingDust(player.x.pos + 10, player.y.pos, 0)
        end
        player.z.pos = 0
        player.z.vel = 0
        player.jump.cons = 0
    end

    -- Visual recovery (bring scale back to 1)
    player.visual.sx = Fx.m.approach(player.visual.sx, 1, 2 * dt)
    player.visual.sy = Fx.m.approach(player.visual.sy, 1, 2 * dt)

    -- Trail
    for i, coin in ipairs(player.coinChain) do
        local tx, ty, tz

        if i == 1 then
            tx = player.x.pos
            ty = player.y.pos
            tz = player.z.pos + 4
        else
            local prev = player.coinChain[i - 1]
            tx = prev.x
            ty = prev.y
            tz = prev.z
        end

        followTarget(coin, tx, ty, tz, dt)
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

function Scene.draw()
end

return Scene
