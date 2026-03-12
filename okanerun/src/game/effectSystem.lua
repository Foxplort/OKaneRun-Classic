local EffectSystem = {} 


function EffectSystem.apply(player, buffDef)
    local id = buffDef.id
    local entry = player.effects[id]

    -- create entry if missing
    if not entry then
        entry = {
            def = buffDef,
            amount = 0,
            instances = {}
        }
        player.effects[id] = entry
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

function EffectSystem.update(player, dt)
    for id, inst in pairs(player.effects) do
        if inst.timeLeft then
            inst.timeLeft = inst.timeLeft - dt
            if inst.timeLeft <= 0 then
                EffectSystem.remove(player, id)
            end
        end

        if inst.def.onUpdate then
            inst.def.onUpdate(player, dt)
        end
    end
end

function EffectSystem.remove(player, id, amount)
    local entry = player.effects[id]
    if not entry then return end

    amount = amount or 1

    for i = 1, amount do
        if entry.amount <= 0 then break end

        -- remove one instance
        table.remove(entry.instances)
        entry.amount = entry.amount - 1

        if entry.def.onRemove then
            entry.def.onRemove(player)
        end

        -- clean up if empty
        if entry.amount <= 0 then
            player.effects[id] = nil
            break
        end
    end
end


return EffectSystem
