local UI = {}

local debugLine = 1
local function debugText(text)
    Fx.r.text(text, 10, 10 + 12 * (debugLine-1), 1)
    debugLine = debugLine+1
end

function UI.draw()
    -- health
    for i = 0, GameState.player.hp.max-1 do
        Fx.r.rect(19, Game.height-21-(i+1)*15, 15, 15, {0, 0, 0})
        Fx.r.rect(20, Game.height-20-(i+1)*15, 13, 13, {127, 0, 63})
        if i < GameState.player.hp.count then
            Fx.r.rect(20, Game.height-20-(i+1)*15, 13, 13, {255, 0, 127})
        end
    end

    -- coin count
    Fx.r.text(tostring(GameState.player.coins) .. "c", Game.width-225, 20, 1, 255, 200, "right")
end

return UI
