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
        if selected and active then
            love.graphics.setColor(1, 1, 1.0, 0.9)
        elseif selected then
            love.graphics.setColor(1, 1, 0.4, 0.9)
        elseif active then
            love.graphics.setColor(0.3, 0.8, 0.3, 0.8)
        else
            love.graphics.setColor(0, 0, 0, 0.6)
        end

        love.graphics.rectangle(
            "fill",
            x - 2, y - 2,
            BuffUIDat.size + 4,
            BuffUIDat.size + 4
        )

        -- icon (safe)
        love.graphics.setColor(1, 1, 1, 1)
        Fx.r.imageSafe(
            id, "missing",
            x, y,
            BuffUIDat.size / 16,
            BuffUIDat.size / 16
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
