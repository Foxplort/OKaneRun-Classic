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

    -- debug
    if debug then
        debugLine = 1
        debugText("OkaneRun [" .. tostring(Game.version) .. "]")
        debugText("DEBUG (Press K to close)")
        debugText("---", 10, 40, 1)
        debugText("FPS - " .. tostring(love.timer.getFPS()))
        debugText("player.pos - " .. tostring(math.floor(GameState.player.pos.x)) .. " / " .. tostring(math.floor(GameState.player.pos.y)))

        Fx.r.text(
            string.format(
                "x: %.1f\ny: %.1f\nz: %.1f\nvz: %.2f\ngrounded: %s",
                GameState.player.pos.x,
                GameState.player.pos.y,
                GameState.player.pos.z or 0,
                GameState.player.vel.z or 0,
                tostring(GameState.player.base.move.grounded)
            ),
            Game.width-110,
            Game.height-90, 1, 255, 100, "left"
        )
    end
end

return UI
