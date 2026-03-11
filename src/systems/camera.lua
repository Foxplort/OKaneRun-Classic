local Camera = {}

local camX, camY = 0, 0
local halfW = fore.conf.width / 2
local halfH = fore.conf.height / 2

local followSpeed = 8

local shake = {
    world = {
        amount = 0,
        x = 0,
        y = 0,
    },
    ui = {
        amount = 0,
        x = 0,
        y = 0,
    },
}

local worldWidth, worldHeight

function Camera.init(worldW, worldH)
    worldWidth, worldHeight = worldW, worldH
end

local function randf(a)
    return (love.math.random() * 2 - 1) * a
end

function Camera.update(targetX, targetY, dt)
    halfW = fore.conf.width / 2
    halfH = fore.conf.height / 2

    for group in pairs(shake) do
        shake[group].amount = Fx.m.approach(shake[group].amount, 0, 40 * dt)
        shake[group].x = randf(shake[group].amount)
        shake[group].y = randf(shake[group].amount)
    end

    -- Smooth follow (Lerp)
    local follow = 1 - math.exp(-followSpeed * dt)

    camX = Fx.m.lerp(camX, targetX, follow)
    camY = Fx.m.lerp(camY, targetY, follow)

    -- Clamping (limiting)
    camX = Fx.m.clamp(camX, halfW, worldWidth - halfW)
    camY = Fx.m.clamp(camY, halfH, worldHeight - halfH)
end

function Camera.push(cam, move)
    love.graphics.push()

    if cam and shake[cam] then
        love.graphics.translate(shake[cam].x, shake[cam].y)
    end

    if move then
        love.graphics.translate(-(camX-halfW), -(camY-halfH))
    end
end

function Camera.pop()
    love.graphics.pop()
end

function Camera.addShake(cam, num)
    if cam and shake[cam] then
        shake[cam].amount = shake[cam].amount + num
    end
end

function Camera.resetShake(cam)
    if cam and shake[cam] then
        shake[cam].amount = 0
    end
end

return Camera
