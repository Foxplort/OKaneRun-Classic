local BuffSystem = {} 


function BuffSystem.apply(player, buffDef)
    local id = buffDef.id
    local entry = player.buffs[id]

    -- create entry if missing
    if not entry then
        entry = {
            def = buffDef,
            amount = 0,
            instances = {}
        }
        player.buffs[id] = entry
    end

    -- cap check
    if buffDef.maxAmount and entry.amount >= buffDef.maxAmount then
        return false -- cannot apply
    end

    -- apply effect ONCE PER STACK
    entry.amount = entry.amount + 1
    table.insert(entry.instances, {
        timeLeft = buffDef.duration
    })

    if buffDef.onApply then
        buffDef.onApply(player)
    end

    return true
end

function BuffSystem.update(player, dt)
    for id, inst in pairs(player.buffs) do
        if inst.timeLeft then
            inst.timeLeft = inst.timeLeft - dt
            if inst.timeLeft <= 0 then
                BuffSystem.remove(player, id)
            end
        end

        if inst.def.onUpdate then
            inst.def.onUpdate(player, dt)
        end
    end
end

function BuffSystem.remove(player, id)
    local entry = player.buffs[id]
    if not entry then return end

    -- remove one instance
    table.remove(entry.instances)
    entry.amount = entry.amount - 1

    if entry.def.onRemove then
        entry.def.onRemove(player)
    end

    -- clean up if empty
    if entry.amount <= 0 then
        player.buffs[id] = nil
    end
end


return BuffSystem
