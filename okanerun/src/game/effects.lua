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
            player.damage(1)
        end
    end,

    onDraw = function(player, inst)
        local col = {255,0,0,120}
        if inst.safeTimer then col = {255,0,127,90} end
        fore.queuer.submit(L.ACTOR, inst.y+inst.h, function()
            fore.graphics.rect(
                -600,
                inst.y,
                GameState.area.mapWidth+1200,
                inst.h,
                col
            )
        end)
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
                player.damage(1)
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

            fore.graphics.line(vertices, {255,0,0,120}, 6)

            love.graphics.setStencilTest()
        end)
    end,
}

return effects
