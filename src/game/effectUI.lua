local EffectUI = {}

local effectList = {}
local effectRef = nil

EffectUI.Data = {
    visible = false,
    x = 10,
    y = 80,
    cols = 8,
    size = 20,
    padding = 4,
    selected = 1,
}

function EffectUI.load(el)
    effectRef = el
    for id in pairs(effectRef) do
        table.insert(effectList, id)
    end
    table.sort(effectList)
end

function EffectUI.draw(player)
    if not EffectUI.Data.visible then return end

    for i, id in ipairs(effectList) do
        local buff = effectRef[id]

        local col = (i - 1) % EffectUI.Data.cols
        local row = math.floor((i - 1) / EffectUI.Data.cols)

        local x = EffectUI.Data.x + col * (EffectUI.Data.size + EffectUI.Data.padding)
        local y = EffectUI.Data.y + row * (EffectUI.Data.size + EffectUI.Data.padding)

        local active = player.effects[id] ~= nil
        local selected = i == EffectUI.Data.selected

        -- background
        local color = {0, 0, 0, 70}
        if active then
            if effectRef[id].type == "debuff" then
                color = {180, 0, 0, 110}
            else
                color = {0, 180, 0, 110}
            end
        end

        Fx.r.rect(
            x - 2, y - 2,
            EffectUI.Data.size + 4,
            EffectUI.Data.size + 4,
            color,
            true
        )

        local entry = player.effects[id]
        local amountApplied = entry and entry.amount or 0
        Fx.r.text(tostring(amountApplied), x+2, 100, 1)

        if selected then
            Fx.r.rect(
                x - 2, y - 2,
                EffectUI.Data.size + 4,
                EffectUI.Data.size + 4,
                255,
                false
            )

            Fx.r.text(tostring(id), 10, 110, 1)
        end

        -- icon (safe)
        love.graphics.setColor(1, 1, 1, 1)
        Fx.r.imageSafe(
            id, "missing",
            x, y,
            EffectUI.Data.size,
            EffectUI.Data.size 
        )

        -- duration
        local inst = player.effects[id]
        if inst and inst.timeLeft then
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.print(
                string.format("%.1f", inst.timeLeft),
                x, y + EffectUIDat.size + 2,
                0, 0.7, 0.7
            )
        end
    end
end

function EffectUI.keypressed(player)
    if not EffectUI.Data.visible then return end

    local max = #effectList

    if Fx.i.pressed("left") then
        EffectUI.Data.selected = math.max(1, EffectUI.Data.selected - 1)

    elseif Fx.i.pressed("right") then
        EffectUI.Data.selected = math.min(max, EffectUI.Data.selected + 1)

    elseif Fx.i.pressed("up") then
        EffectUI.Data.selected = math.max(1, EffectUI.Data.selected - EffectUI.Data.cols)

    elseif Fx.i.pressed("down") then
        EffectUI.Data.selected = math.min(max, EffectUI.Data.selected + EffectUI.Data.cols)

    elseif Fx.i.pressed("accept") then
        local id = effectList[EffectUI.Data.selected]
        Fx.es.apply(player, effectRef[id])

    elseif Fx.i.pressed("cancel") then
        local id = effectList[EffectUI.Data.selected]
        Fx.es.remove(player, id)
    end
end

return EffectUI
