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

return effects
