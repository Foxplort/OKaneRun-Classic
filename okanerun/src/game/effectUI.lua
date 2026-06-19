local EffectUI = {}

local effectList = {}
local effectRef = nil
local effectFun = nil

EffectUI.Data = {
    visible = false,
    x = 10,
    y = 80,
    cols = 8,
    size = 20,
    padding = 4,
    selected = 1,
}

function EffectUI.load(el, ef)
    effectRef = el
    effectFun = ef
    effectList = {}
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
        local y = EffectUI.Data.y + row * (EffectUI.Data.size + EffectUI.Data.padding + 10)

        local active = player.effects[id] ~= nil
        local selected = i == EffectUI.Data.selected

        -- background
        local color = {0, 0, 0, 70}
        if active then
            if effectRef[id].type == "debuff" then
                color = {220, 50, 0, 110}
            elseif effectRef[id].type == "buff" then
                color = {0, 210, 90, 110}
            else
                color = {180, 0, 180, 110}
            end
        end

        fore.draw2d.rect(
            x - 2, y - 2,
            EffectUI.Data.size + 4,
            EffectUI.Data.size + 4,
            color,
            true
        )

        local entry = player.effects[id]
        local amountApplied = entry and entry.amount or 0
        fore.text.text(tostring(amountApplied), x+2, y+22, 1)

        if selected then
            fore.draw2d.rect(
                x - 2, y - 2,
                EffectUI.Data.size + 4,
                EffectUI.Data.size + 4,
                255,
                false
            )

            fore.text.text(tostring(id), 10, 65, 1)
            fore.text.text("Debug; press B to return", 10, 55, 1)
        end

        -- icon (safe)
        love.graphics.setColor(1, 1, 1, 1)
        fore.draw2d.imageSafe(
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

    if fore.input:pressed("left") then
        EffectUI.Data.selected = math.max(1, EffectUI.Data.selected - 1)

    elseif fore.input:pressed("right") then
        EffectUI.Data.selected = math.min(max, EffectUI.Data.selected + 1)

    elseif fore.input:pressed("up") then
        EffectUI.Data.selected = math.max(1, EffectUI.Data.selected - EffectUI.Data.cols)

    elseif fore.input:pressed("down") then
        EffectUI.Data.selected = math.min(max, EffectUI.Data.selected + EffectUI.Data.cols)

    elseif fore.input:pressed("accept") then
        local id = effectList[EffectUI.Data.selected]
        effectFun.apply(player, effectRef[id])

    elseif fore.input:pressed("cancel") then
        local id = effectList[EffectUI.Data.selected]
        effectFun.remove(player, id)
    end
end

return EffectUI
