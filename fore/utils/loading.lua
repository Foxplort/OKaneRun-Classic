local Loading = {}

local active = false
local angle = 0
local SPIN_SPEED = 8
local RADIUS = 8
local THICKNESS = 4

function Loading.start()
    active, angle = true, 0
    if fore.data.phone then
        RADIUS = 10
        THICKNESS = 8
    else
        RADIUS = 8
        THICKNESS = 4
    end
end

function Loading.update(dt)
    if not active then return end
    angle = (angle + dt * SPIN_SPEED) % (math.pi * 2)
end

function Loading.draw()
    if not active then return end

    local x = fore.data.width - RADIUS - 20
    local y = fore.data.height - RADIUS - 20

    love.graphics.setLineWidth(THICKNESS)
    
    -- Background "Donut"
    fore.draw2d.arc(x, y, RADIUS, 0, math.pi * 2, {34, 32, 52}, "open", false)

    -- Moving "White Section"
    fore.draw2d.arc(x, y, RADIUS, angle, angle + (math.pi / 2), {255, 255, 255}, "open", false)
    
    love.graphics.setLineWidth(1)
end

function Loading.stop()
    active = false
end

return Loading