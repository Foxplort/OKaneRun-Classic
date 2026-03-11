local Loading = {}

local active = false
local angle = 0
local SPIN_SPEED = 8
local RADIUS = 8
local THICKNESS = 4

function Loading.start()
    active, angle = true, 0
end

function Loading.update(dt)
    if not active then return end
    angle = (angle + dt * SPIN_SPEED) % (math.pi * 2)
end

function Loading.draw()
    if not active then return end

    local x = fore.conf.width - RADIUS - 20
    local y = fore.conf.height - RADIUS - 20

    love.graphics.setLineWidth(THICKNESS)
    
    -- Background "Donut"
    Fx.r.arc(x, y, RADIUS, 0, math.pi * 2, {34, 32, 52}, "open", false)

    -- Moving "White Section"
    Fx.r.arc(x, y, RADIUS, angle, angle + (math.pi / 2), {255, 255, 255}, "open", false)
    
    love.graphics.setLineWidth(1)
end

function Loading.stop()
    active = false
end

return Loading