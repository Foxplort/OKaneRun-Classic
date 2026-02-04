local buffs = {}

buffs.haste = {
    id = "haste",
    type = "buff",
    duration = nil,
    maxAmount = 2,

    onApply = function(player)
        player.meta.move.maxVel = player.meta.move.maxVel * 1.3
    end,

    onRemove = function(player)
        player.meta.move.maxVel = player.meta.move.maxVel / 1.3
    end,
}

buffs.fatso = {
    id = "fatso",
    type = "debuff",
    duration = nil,
    maxAmount = 2,
    
    onApply = function(player)
        player.meta.jump.vel = player.meta.jump.vel * 0.8
    end,

    onRemove = function(player)
        player.meta.jump.vel = player.meta.jump.vel / 0.8
    end,
}

buffs.winged = {
    id = "winged",
    type = "buff",
    duration = nil,
    maxAmount = 4,

    onApply = function(player)
        player.meta.jump.lim = player.meta.jump.lim + 1
    end,

    onRemove = function(player)
        player.meta.jump.lim = player.meta.jump.lim - 1
    end,
}

buffs.icy = {
    id = "icy",
    type = "debuff",
    duration = nil,
    maxAmount = 2,
    
    onApply = function(player)
        player.meta.move.fri = player.meta.move.fri * 0.5
        player.meta.move.accel = player.meta.move.accel * 0.9
    end,

    onRemove = function(player)
        player.meta.move.fri = player.meta.move.fri / 0.5
        player.meta.move.accel = player.meta.move.accel / 0.9
    end,
}

buffs.coin = {
    id = "coin",
    type = "debuff",
    duration = nil,
    maxAmount = 1023,
    
    onApply = function(player)
        player.meta.move.fri = player.meta.move.fri * 0.8
        player.meta.move.accel = player.meta.move.accel * 0.7
        player.meta.move.maxVel = player.meta.move.maxVel * 0.97
        player.meta.jump.vel = player.meta.jump.vel * 0.95
    end,

    onRemove = function(player)
        player.meta.move.fri = player.meta.move.fri / 0.8
        player.meta.move.accel = player.meta.move.accel / 0.7
        player.meta.move.maxVel = player.meta.move.maxVel / 0.97
        player.meta.jump.vel = player.meta.jump.vel / 0.95
    end,
}

return buffs
