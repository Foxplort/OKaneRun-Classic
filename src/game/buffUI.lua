local BuffUI = {}

local buffList = {}

function BuffUI.load()
    for id in pairs(Fx.el) do
        table.insert(buffList, id)
    end
    table.sort(buffList)
end

function BuffUI.draw(player)
    if not BuffUIDat.visible then return end

    for i, id in ipairs(buffList) do
        local buff = Fx.el[id]

        local col = (i - 1) % BuffUIDat.cols
        local row = math.floor((i - 1) / BuffUIDat.cols)

        local x = BuffUIDat.x + col * (BuffUIDat.size + BuffUIDat.padding)
        local y = BuffUIDat.y + row * (BuffUIDat.size + BuffUIDat.padding)

        local active = player.buffs[id] ~= nil
        local selected = i == BuffUIDat.selected

        -- background
        local color = {0, 0, 0, 70}
        if active then
            if Fx.el[id].type == "debuff" then
                color = {180, 0, 0, 110}
            else
                color = {0, 180, 0, 110}
            end
        end

        Fx.r.rect(
            x - 2, y - 2,
            BuffUIDat.size + 4,
            BuffUIDat.size + 4,
            color,
            true
        )

        local entry = player.buffs[id]
        local amountApplied = entry and entry.amount or 0
        Fx.r.text(tostring(amountApplied), x+2, 100, 1)

        if selected then
            Fx.r.rect(
                x - 2, y - 2,
                BuffUIDat.size + 4,
                BuffUIDat.size + 4,
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
            BuffUIDat.size,
            BuffUIDat.size 
        )

        -- duration
        local inst = player.buffs[id]
        if inst and inst.timeLeft then
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.print(
                string.format("%.1f", inst.timeLeft),
                x, y + BuffUIDat.size + 2,
                0, 0.7, 0.7
            )
        end
    end
end

function BuffUI.keypressed(player, key)
    if not BuffUIDat.visible then return end

    local max = #buffList

    if key == "left" then
        BuffUIDat.selected = math.max(1, BuffUIDat.selected - 1)

    elseif key == "right" then
        BuffUIDat.selected = math.min(max, BuffUIDat.selected + 1)

    elseif key == "up" then
        BuffUIDat.selected = math.max(1, BuffUIDat.selected - BuffUIDat.cols)

    elseif key == "down" then
        BuffUIDat.selected = math.min(max, BuffUIDat.selected + BuffUIDat.cols)

    elseif key == "return" then
        local id = buffList[BuffUIDat.selected]
        Fx.es.apply(player, Fx.el[id])

    elseif key == "backspace" then
        local id = buffList[BuffUIDat.selected]
        Fx.es.remove(player, id)
    end
end

return BuffUI
