local MP = {}

local particles = {}
local dots = {}
local scroll = 0

local PANEL_WIDTH

function MP.init(pw)
    particles = {}
    PANEL_WIDTH = pw

    for i = 1, 80 do
        local z = math.random() -- depth

        particles[i] = {
            x = math.random(PANEL_WIDTH, fore.conf.baseWidth + fore.conf.pixelBank),
            y = math.random(0, fore.conf.baseHeight + fore.conf.pixelBank),
            z = z,

            spd = 10 + z * 30,          -- deeper = faster
            drift = (math.random()-0.5) * (5 + z*20),

            size = math.random(0.4, 0.8) + z * 1.5,
            a = 0.1 + z * 0.4
        }
    end

    dots = {}
    for x = PANEL_WIDTH, fore.conf.baseWidth+fore.conf.pixelBank, 16 do
        for y = 0, fore.conf.baseHeight+fore.conf.pixelBank, 16 do
            table.insert(dots, {x=x, y=y})
        end
    end
end

function MP.update(dt)
    local wind = math.sin(love.timer.getTime() * 0.6) * 10

    for _, p in ipairs(particles) do
        p.y = p.y + p.spd * dt
        p.x = p.x + (p.drift + wind * p.z) * dt

        if p.y > fore.conf.baseHeight + 10 + fore.conf.pixelBank then
            p.y = -10
            p.x = math.random(PANEL_WIDTH, fore.conf.baseWidth)
        end

        if p.x < PANEL_WIDTH then
            p.x = fore.conf.baseWidth
        elseif p.x > fore.conf.baseWidth + fore.conf.pixelBank then
            p.x = PANEL_WIDTH
        end
    end

    scroll = (scroll + dt * 5) % 16
end

function MP.drawBack()
    for _, d in ipairs(dots) do Fx.r.rect(d.x, d.y + scroll, 1, 1, {255, 255, 255, 20}) end

    for _, p in ipairs(particles) do
        if p.z < 0.5 then
            Fx.r.circ(p.x, p.y, p.size, p.size, {1,1,1,p.a})
        end
    end
end

function MP.drawFront()
    for _, p in ipairs(particles) do
        if p.z >= 0.5 then
            Fx.r.circ(p.x, p.y, p.size, p.size, {1,1,1,p.a})
        end
    end
end

return MP
