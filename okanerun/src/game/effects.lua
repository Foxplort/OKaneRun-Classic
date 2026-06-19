local effects = {}

effects.haste = {
    id = "haste",
    type = "buff",
    duration = nil,
    maxAmount = 3,

    onApply = function(player)
        player.mod.move.maxVel.mul = player.mod.move.maxVel.mul * 1.2
    end,

    onRemove = function(player)
        player.mod.move.maxVel.mul = player.mod.move.maxVel.mul / 1.2
    end,
}

effects.fatso = {
    id = "fatso",
    type = "debuff",
    duration = nil,
    maxAmount = 2,
    
    onApply = function(player)
        player.mod.jump.vel.mul = player.mod.jump.vel.mul * 0.8
    end,

    onRemove = function(player)
        player.mod.jump.vel.mul = player.mod.jump.vel.mul / 0.8
    end,
}

effects.winged = {
    id = "winged",
    type = "buff",
    duration = nil,
    maxAmount = 4,

    onApply = function(player)
        player.mod.jump.lim.add = player.mod.jump.lim.add + 1
    end,

    onRemove = function(player)
        player.mod.jump.lim.add = player.mod.jump.lim.add - 1
    end,
}

effects.icy = {
    id = "icy",
    type = "debuff",
    duration = nil,
    maxAmount = 2,
    
    onApply = function(player)
        player.mod.move.fri.mul = player.mod.move.fri.mul * 0.5
        player.mod.move.accel.mul = player.mod.move.accel.mul * 0.9
    end,

    onRemove = function(player)
        player.mod.move.fri.mul = player.mod.move.fri.mul / 0.5
        player.mod.move.accel.mul = player.mod.move.accel.mul / 0.9
    end,
}

effects.coin = {
    id = "coin",
    type = "special_debuff",
    duration = nil,
    maxAmount = 1023,
    
    onApply = function(player)
        player.mod.move.fri.mul = player.mod.move.fri.mul * 0.8
        player.mod.move.accel.mul = player.mod.move.accel.mul * 0.7
        player.mod.move.maxVel.mul = player.mod.move.maxVel.mul * 0.97
        player.mod.jump.vel.mul = player.mod.jump.vel.mul * 0.95
    end,

    onRemove = function(player)
        player.mod.move.fri.mul = player.mod.move.fri.mul / 0.8
        player.mod.move.accel.mul = player.mod.move.accel.mul / 0.7
        player.mod.move.maxVel.mul = player.mod.move.maxVel.mul / 0.97
        player.mod.jump.vel.mul = player.mod.jump.vel.mul / 0.95
    end,
}

effects.healthy = {
    id = "healthy",
    type = "buff",
    duration = nil,
    maxAmount = 9,
    
    onApply = function(player)
        player.hp.count = player.hp.count + 1
        player.hp.max = player.hp.max + 1
    end,

    onRemove = function(player)
        player.hp.count = player.hp.count - 1
        player.hp.max = player.hp.max - 1
    end,
}

effects.scanline = {
    id = "scanline",
    type = "debuff",
    duration = nil,
    maxAmount = 4,

    onApply = function(player, inst)
        inst.h = 15
    end,

    onReset = function(player, inst)
        inst.speed = 80 + (inst.index-1) * 15 + math.random(-3, 3)
        inst.y = -130 + (inst.index-1) * 50
        inst.up = false
        inst.safeTimer = 2
    end,

    onUpdate = function(player, inst, dt)
        if inst.safeTimer then
            inst.safeTimer = inst.safeTimer - dt
            if inst.safeTimer < 0 then inst.safeTimer = nil end
        end

        if inst.up then
            inst.y = inst.y - inst.speed * dt
            if 0 >= inst.y then inst.up = false end
        else
            inst.y = inst.y + inst.speed * dt
            if GameState.area.mapHeight <= inst.y + inst.h then inst.up = true end
        end

        local py = player.pos.y

        if not inst.safeTimer and py > inst.y and py < inst.y + inst.h and player.grounded then
            player.damage(1, 1, "scanline")
        end
    end,

    onDraw = function(player, inst)
        local col = {255,0,0,120}
        if inst.safeTimer then col = {255,0,127,90} end
        fore.queuer.submit(L.ACTOR, inst.y+inst.h, function()
            fore.draw2d.rect(
                -600,
                inst.y,
                GameState.area.mapWidth+1200,
                inst.h,
                col
            )
        end)
    end,
}

effects.laser = {
    id = "laser",
    type = "debuff",
    duration = nil,
    maxAmount = 2,

    onApply = function(player, inst)
        inst.width = 18
        inst.spawnDuration = 4
        inst.activeDuration = 3
        inst.lasers = {
            {x = 0, state = "spawning", timer = 0},
            {x = 0, state = "spawning", timer = 0}
        }
    end,

    onReset = function(player, inst)
        for i, laser in ipairs(inst.lasers) do
            laser.x = math.random(50, GameState.area.mapWidth - 50)
            laser.state = "spawning"
            laser.timer = (i-1) * -0.5 -- Stagger them slightly
        end
    end,

    onUpdate = function(player, inst, dt)
        if not GameState.area.mapWidth then return end
        
        for _, laser in ipairs(inst.lasers) do
            laser.timer = laser.timer + dt
            
            if laser.timer < 0 then goto continue end

            if laser.state == "spawning" then
                if laser.timer >= inst.spawnDuration then
                    laser.state = "active"
                    laser.timer = 0
                end
            elseif laser.state == "active" then
                if laser.timer >= inst.activeDuration then
                    laser.state = "spawning"
                    laser.timer = 0
                    laser.x = math.random(50, GameState.area.mapWidth - 50)
                else
                    -- Collision
                    local px = player.pos.x + player.base.body.w/2
                    if math.abs(px - laser.x) < inst.width/2 and player.grounded then
                        player.damage(1, 1, "laser")
                    end
                end
            end
            ::continue::
        end
    end,

    onDraw = function(player, inst)
        if not GameState.area.mapHeight then return end

        for _, laser in ipairs(inst.lasers) do
            if laser.timer < 0 then goto next_laser end

            local col = {255, 0, 127, 90}
            local drawWidth = 0
            
            if laser.state == "spawning" then
                local progress = math.max(0, laser.timer / inst.spawnDuration)
                -- Pulse while spawning to look like it's charging
                local pulse = (math.sin(fore.time.getTicks() * 6) + 1) / 2
                col[4] = 50 + 20 * pulse
                drawWidth = inst.width * progress
            elseif laser.state == "active" then
                col = {255, 0, 0, 120}
                drawWidth = inst.width
                local pulse = (math.sin(fore.time.getTicks() * 10) + 1) / 2
                col[4] = 130 + 20 * pulse
            end
            
            if drawWidth > 0 then
                fore.queuer.submit(L.ACTOR, -1000, function()
                    fore.draw2d.rect(
                        laser.x - drawWidth/2,
                        -600,
                        drawWidth,
                        GameState.area.mapHeight + 1200,
                        col
                    )
                end)
            end
            ::next_laser::
        end
    end,
}

effects.trail = {
    id = "trail",
    type = "debuff",
    duration = nil,
    maxAmount = 1,

    onApply = function(player, inst)
        inst.maxLength = 40 + inst.index * 30
        inst.spacing = 5
    end,

    onReset = function(player, inst)
        inst.points = {}
    end,

    onUpdate = function(player, inst, dt)
        local px = player.pos.x + player.base.body.w/2
        local py = player.pos.y

        local last = inst.points[#inst.points]

        if not last then
            table.insert(inst.points, {x=px, y=py})
        else
            local dx = px - last.x
            local dy = py - last.y
            local dist = math.sqrt(dx*dx + dy*dy)

            if dist > inst.spacing then
                table.insert(inst.points, {x=px, y=py})
            end
        end

        while #inst.points > inst.maxLength do
            table.remove(inst.points, 1)
        end

        for i = 1, #inst.points-5 do
            local p = inst.points[i]

            local dx = player.pos.x - p.x
            local dy = player.pos.y - p.y

            if dx*dx + dy*dy < 16 and player.grounded then
                player.damage(1, 1, "trail")
                break
            end
        end
    end,

    onDraw = function(player, inst)
        if #inst.points < 2 then return end

        local vertices = {}

        for i = 1, #inst.points do
            local p = inst.points[i]
            table.insert(vertices, p.x)
            table.insert(vertices, p.y)
        end

        local depth = inst.points[#inst.points].y - 3

        fore.queuer.submit(L.ACTOR, depth, function()
            love.graphics.stencil(function()
                for _, g in ipairs(GameState.area.ground) do
                    love.graphics.rectangle("fill", g.x, g.y, g.w, g.h)
                end
            end, "replace", 1)
            love.graphics.setStencilTest("equal", 1)

            fore.draw2d.line(vertices, {255,0,0,120}, 6)

            love.graphics.setStencilTest()
        end)
    end,
}

effects.zoomed = {
    id = "zoomed",
    type = "debuff",
    duration = nil,
    maxAmount = 3,
    
    onApply = function(player)
        player.camZoom = player.camZoom + 0.1
    end,

    onRemove = function(player)
        player.camZoom = player.camZoom - 0.1
    end,
}

effects.explosive = {
    id = "explosive",
    type = "debuff",
    duration = nil,
    maxAmount = 3,
    
    onApply = function(player, inst)
        inst.size = 16
        inst.spawnDelay = 1.5
        inst.minDistanceFromPlayer = 140
        inst.maxMines = 5
    end,
    
    onReset = function(player, inst)
        inst.mines = {}
        inst.spawnTimer = 0
    end,
    
    onUpdate = function(player, inst, dt)
        inst.spawnTimer = inst.spawnTimer + dt

        if inst.spawnTimer >= inst.spawnDelay and #inst.mines < inst.maxMines then
            inst.spawnTimer = 0
            local attempts = 0
            local maxAttempts = 20
            local spawned = false
            
            while not spawned and attempts < maxAttempts do
                local x = math.random(50, GameState.area.mapWidth - 50)
                local y = math.random(50, GameState.area.mapHeight - 50)
                
                local dx = x - player.pos.x
                local dy = y - player.pos.y
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist >= inst.minDistanceFromPlayer then
                    local tooClose = false
                    for _, mine in ipairs(inst.mines) do
                        local mdx = x - mine.x
                        local mdy = y - mine.y
                        if math.sqrt(mdx*mdx + mdy*mdy) < inst.size * 2 then
                            tooClose = true
                            break
                        end
                    end
                    
                    if not tooClose then
                        table.insert(inst.mines, {
                            x = x,
                            y = y,
                            state = "idle",
                            timer = 0,
                            blinkDuration = 1.0,
                            blinkInterval = 0.15,
                            explodeRadius = 60,
                            explodeDamage = 2,
                            colorShift = math.random()
                        })
                        spawned = true
                    end
                end
                
                attempts = attempts + 1
            end
        end
        
        for i = #inst.mines, 1, -1 do
            local mine = inst.mines[i]
            mine.timer = mine.timer + dt
            local px = player.pos.x + player.base.body.w/2
            local py = player.pos.y + player.base.body.h/2
            local dx = px - (mine.x + inst.size/2)
            local dy = py - (mine.y + inst.size/2)
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist < inst.size and player.grounded then
                if mine.state == "idle" then
                    mine.state = "blinking"
                    mine.timer = 0
                    player.damage(1, 1, "explosive_contact")
                elseif mine.state == "blinking" then
                    player.damage(1, 1, "explosive_contact")
                end
            end

            if mine.state == "idle" then
                if mine.timer > math.random(3, 6) then
                    mine.state = "blinking"
                    mine.timer = 0
                end
            elseif mine.state == "blinking" then
                if mine.timer >= mine.blinkDuration then
                    mine.state = "exploding"
                    mine.timer = 0
                end
            elseif mine.state == "exploding" then
                if mine.timer < 0.1 then
                    local dx = px - mine.x
                    local dy = py - mine.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    
                    if dist < mine.explodeRadius*0.9 and player.pos.z > mine.explodeRadius*-0.9 and player.pos.z < mine.explodeRadius*0.9 then
                        player.damage(mine.explodeDamage, 2, "explosive_explosion")
                    end
                end
                
                if mine.timer > 0.3 then
                    table.remove(inst.mines, i)
                end
            end
        end
    end,
    
    onDraw = function(player, inst)
        for _, mine in ipairs(inst.mines) do
            local r, g, b
            
            if mine.state == "idle" then
                local shift = (math.sin(mine.timer * 2 + mine.colorShift * 10) + 1) / 2
                r = math.floor(200 + 55 * shift)
                g = math.floor(0)
                b = math.floor(100 + 27 * (1 - shift))
            elseif mine.state == "blinking" then
                local blinkPhase = (math.floor(mine.timer / mine.blinkInterval) % 2)
                if blinkPhase == 0 then r, g, b = 255, 0, 127
                else r, g, b = 190, 0, 190 end
            elseif mine.state == "exploding" then
                local progress = mine.timer / 0.3  -- 0 to 1
                local size = inst.size + (mine.explodeRadius - inst.size) * progress
                local alpha = math.floor(255 * (1 - progress))
                
                fore.queuer.submit(L.ACTOR, mine.y + size, function()
                    fore.draw2d.circ(
                        mine.x-size,
                        mine.y-size,
                        size*2,
                        size*2,
                        {255, 255, 200, alpha},
                        true, math.floor(5 + (size/9))
                    )
                end)
                
                goto continue
            end
            
            fore.queuer.submit(L.ACTOR, mine.y + inst.size, function()
                -- Body
                fore.draw2d.rect(
                    mine.x,
                    mine.y,
                    inst.size,
                    inst.size,
                    {r, g, b, 200}
                )
                
                -- Highlight
                fore.draw2d.rect(
                    mine.x + 1,
                    mine.y + 1,
                    inst.size - 2,
                    inst.size - 2,
                    {255, 255, 255, 70}
                )
                
                -- Lines
                if mine.state == "blinking" then
                    fore.draw2d.line(
                        {mine.x + 1, mine.y + 1,
                        mine.x + inst.size - 1, mine.y + inst.size - 1},
                        {255, 255, 255, 100}
                    )
                    fore.draw2d.line(
                        {mine.x + inst.size - 1, mine.y + 1,
                        mine.x + 1, mine.y + inst.size - 1},
                        {255, 255, 255, 100}
                    )
                end
            end)
            
            ::continue::
        end
    end,
}

effects.bloodloss = {
    id = "bloodloss",
    type = "debuff",
    duration = nil,
    maxAmount = 2,

    -- Makes invincibility frames last 40% less. In the damaged code.
    onApply = function(player)
        if not player.effectRef.bloodloss then player.effectRef.bloodloss = 0 end
        player.effectRef.bloodloss = player.effectRef.bloodloss + 1
    end,

    onRemove = function(player)
        player.effectRef.bloodloss = player.effectRef.bloodloss - 1
    end,
}

effects.confused = {
    id = "confused",
    type = "debuff",
    duration = 40,
    maxAmount = 1,

    -- Reverse controls. In player controls.
    onApply = function(player)
        player.effectRef.confused = true
    end,

    onRemove = function(player)
        player.effectRef.confused = false
    end,
}

effects.sticky = {
    id = "sticky",
    type = "debuff",
    duration = nil,
    maxAmount = 2,

    -- Delays the jump by 0.15 seconds. In player controls.
    onApply = function(player)
        if not player.effectRef.sticky then player.effectRef.sticky = 0 end
        player.effectRef.sticky = player.effectRef.sticky + 1
    end,

    onRemove = function(player)
        player.effectRef.sticky = player.effectRef.sticky - 1
    end,
}

effects.windy = {
    id = "windy",
    type = "debuff",
    maxAmount = 1,

    onApply = function(player)
        player.effectRef.windy = {
            dir = 0,
            strength = 0,
            targetStrength = 0,
            timer = 0
        }
    end,

    onReset = function(player)
        local w = player.effectRef.windy
        w.dir = math.random() * math.pi * 2
        w.targetStrength = math.random(20, 70)
        w.timer = math.random(1.5, 3)
    end,

    onRemove = function(player)
        player.effectRef.windy = nil
    end,
}

effects.slippery = {
    id = "slippery",
    type = "buff",
    duration = nil,
    maxAmount = 2,

    onApply = function(player)
        player.dash.time = player.dash.time + 0.1
        player.dash.mult = player.dash.mult + 0.2
    end,

    onRemove = function(player)
        player.dash.time = player.dash.time - 0.1
        player.dash.mult = player.dash.mult - 0.2
    end,
}

effects.charged = {
    id = "charged",
    type = "debuff",
    duration = nil,
    maxAmount = 1,

    onApply = function(player)
        player.effectRef.charged = 0
    end,

    onRemove = function(player)
        player.effectRef.charged = nil
    end,

    onDraw = function(player, inst)
        local charge = player.effectRef.charged
        if charge and charge > 0 then
            local px = player.pos.x + player.base.body.w/2
            local py = player.pos.y - player.pos.z
            local progress = math.min(charge / 0.8, 1)
            
            fore.queuer.submit(L.ACTOR, py + 10, function()
                local w, h = 24, 4
                local x, y = px - w/2, py + 5
                
                -- BG
                fore.draw2d.rect(x - 1, y - 1, w + 2, h + 2, {0, 0, 0, 150})
                
                -- Progress
                local r, g, b = 100, 200, 255
                if charge >= 0.8 then
                    r, g, b = 255, 200, 50
                    local pulse = (math.sin(fore.time.getTicks() * 15) + 1) / 2
                    r = r + (255-r) * pulse
                end
                
                fore.draw2d.rect(x, y, w * progress, h, {r, g, b, 200})
            end)
        end
    end,
}

effects.chance = {
    id = "chance",
    type = "buff",
    duration = nil,
    maxAmount = 2,

    onApply = function(player)
        if not player.effectRef.chance then player.effectRef.chance = 0 end
        player.effectRef.chance = player.effectRef.chance + 1
    end,

    onRemove = function(player)
        player.effectRef.chance = player.effectRef.chance - 1
    end,
}



return effects
