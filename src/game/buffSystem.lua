local BuffSystem = {} 


function BuffSystem.apply(player, buffDef)
    -- one-shot buff
    -- if buffDef.kind == "oneshot" then
    --     if buffDef.onApply then
    --         buffDef.onApply(player)
    --     end
    --     return
    -- end

    -- prevent duplicates (optional)
    -- if player.buffs[buffDef.id] then
    --     return
    -- end

    local inst = {
        id = buffDef.id,
        def = buffDef,
        timeLeft = buffDef.duration,
    }

    player.buffs[buffDef.id] = inst

    if buffDef.onApply then
        buffDef.onApply(player)
    end
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
    local inst = player.buffs[id]
    if not inst then return end

    if inst.def.onRemove then
        inst.def.onRemove(player)
    end

    player.buffs[id] = nil
end


return BuffSystem
