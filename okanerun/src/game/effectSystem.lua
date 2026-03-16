local EffectSystem = {} 


function EffectSystem.apply(player, buffDef)
    local id = buffDef.id
    local entry = player.effects[id]

    if not entry then
        entry = {
            def = buffDef,
            amount = 0,
            instances = {}
        }
        player.effects[id] = entry
    end

    if buffDef.maxAmount and entry.amount >= buffDef.maxAmount then
        return false
    end

    -- create instance
    local inst = {
        timeLeft = buffDef.duration
    }

    table.insert(entry.instances, inst)
    inst.index = #entry.instances
    entry.amount = entry.amount + 1

    if buffDef.onApply then
        buffDef.onApply(player, inst)
    end
    if buffDef.onReset then
        buffDef.onReset(player, inst)
    end

    return true
end

function EffectSystem.update(player, dt)
    for id, entry in pairs(player.effects) do

        for _, inst in ipairs(entry.instances) do

            if inst.timeLeft then
                inst.timeLeft = inst.timeLeft - dt
                if inst.timeLeft <= 0 then
                    EffectSystem.remove(player, id, 1)
                end
            end

            if entry.def.onUpdate then
                entry.def.onUpdate(player, inst, dt)
            end

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
