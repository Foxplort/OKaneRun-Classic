local UI = {}

function UI.draw()
    -- health
    for i = 0, player.hp.max-1 do
        Fx.r.rect(19, Game.height-21-(i+1)*15, 15, 15, {0, 0, 0})
        Fx.r.rect(20, Game.height-20-(i+1)*15, 13, 13, {127, 0, 63})
        if i < player.hp.count then
            Fx.r.rect(20, Game.height-20-(i+1)*15, 13, 13, {255, 0, 127})
        end
    end

    -- coin count
    Fx.r.text(tostring(player.coins) .. "c", Game.width-225, 20, 1, 255, 200, "right")

    -- debug
    if debug then
        Fx.r.text("OkaneRun [" .. tostring(Game.version) .. "]", 10, 10, 1)
        Fx.r.text("DEBUG (Press K to close)", 10, 20, 1)
        Fx.r.text("---", 10, 30, 1)
        Fx.r.text("FPS - " .. tostring(love.timer.getFPS()), 10, 40, 1)
        Fx.r.text("player.pos - " .. tostring(math.floor(player.x.pos)) .. " / " .. tostring(math.floor(player.y.pos)), 10, 50, 1)
    end
end

return UI
