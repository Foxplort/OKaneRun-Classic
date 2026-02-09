local Camera = {}

local camX, camY = 0, 0
local shakeAmount = 0
local uiShake = 0

function Camera.update(dt)
    shakeAmount = Fx.m.approach(shakeAmount, 0, 40 * dt)
    uiShake = Fx.m.approach(uiShake, 0, 40 * dt)

    -- Camera target (center of screen)
    local targetX = GameState.player.pos.x + GameState.player.stat.body.w / 2 - 320
    local targetY = GameState.player.pos.y + GameState.player.stat.body.h / 2 - 180

    -- Smooth follow (Lerp)
    camX = camX + (targetX - camX) * 5 * dt
    camY = camY + (targetY - camY) * 5 * dt

    -- Clamping (limiting)
    camX = math.max(0, math.min(camX, GameState.area.mapWidth - 640))
    camY = math.max(0, math.min(camY, GameState.area.mapHeight - 360))
end

function Camera.applyWorld()
    love.graphics.push()
    love.graphics.translate(math.random(-shakeAmount, shakeAmount), math.random(-shakeAmount, shakeAmount))
    love.graphics.translate(-math.floor(camX), -math.floor(camY))
end

function Camera.applyUI()
    love.graphics.push()
    if uiShake > 0 then
        love.graphics.translate(math.random(-1, 1), math.random(-1, 1))
    end
end

function Camera.pop()
    love.graphics.pop()
end

function Camera.addShake(num)
    shakeAmount = shakeAmount + num
end

function Camera.addUIShake(num)
    uiShake = uiShake + num
end

return Camera
