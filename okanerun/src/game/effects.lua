local effects = {}

effects.haste = {
    id = "haste",
    type = "buff",
    duration = nil,
    maxAmount = 2,

    onApply = function(player)
        player.mod.move.maxVel.mul = player.mod.move.maxVel.mul * 1.3
    end,

    onRemove = function(player)
        player.mod.move.maxVel.mul = player.mod.move.maxVel.mul / 1.3
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
    maxAmount = 2,

    onApply = function(player, inst)
        inst.speed = 80 + (inst.index-1) * 10
        inst.h = 20
        inst.t = 15
        inst.z = 0
    end,

    onReset = function(player, inst)
        inst.y = -50 + (inst.index-1) * 50
        inst.up = false
    end,

    onUpdate = function(player, inst, dt)
        if inst.up then
            inst.y = inst.y - inst.speed * dt
            if 0 >= inst.y then inst.up = false end
        else
            inst.y = inst.y + inst.speed * dt
            if GameState.area.mapHeight <= inst.y + inst.h then inst.up = true end
        end

        local py = player.pos.y

        if py > inst.y and py < inst.y + inst.h and player.grounded then
            player.damage(1)
        end
    end,

    onDraw = function(player, inst)
        fore.queuer.submit(L.ACTOR, inst.y+inst.z, function()
            fore.graphics.rect(
                0,
                inst.y,
                GameState.area.mapWidth,
                inst.h,
                {255,0,0,120}
            )
        end)
    end,
}

return effects
