local MP = {}

local particles = {}
local dots = {}
local scroll = 0

local PANEL_WIDTH

function MP.init(pw)
    particles = {}
    PANEL_WIDTH = pw
    for i = 1, 60 do
        particles[i] = {
            x = math.random(PANEL_WIDTH, Game.baseWidth+Game.pixelBank),
            y = math.random(0, Game.baseHeight+Game.pixelBank),
            spd = math.random() * 10 + 5,
            size = math.random() * 1.5 + 0.5,
            a = math.random() * 0.4 + 0.1
        }
    end

    dots = {}
    for x = PANEL_WIDTH, Game.baseWidth+Game.pixelBank, 16 do
        for y = 0, Game.baseHeight+Game.pixelBank, 16 do
            table.insert(dots, {x=x, y=y})
        end
    end
end

function MP.update(dt)
    for _, p in ipairs(particles) do
        p.y = p.y + p.spd * dt
        if p.y > Game.height then
            p.y = -5
            p.x = math.random(PANEL_WIDTH, Game.width)
        end
    end
    scroll = (scroll + dt * 5) % 16
end

function MP.draw()
    for _, p in ipairs(particles) do
        love.graphics.setColor(1, 1, 1, p.a)
        love.graphics.rectangle("fill", math.floor(p.x), math.floor(p.y), p.size, p.size)
    end

    love.graphics.setColor(1, 1, 1, 0.06)
    for _, d in ipairs(dots) do
        love.graphics.rectangle(
            "fill",
            math.floor(d.x),
            math.floor(d.y + scroll),
            1, 1
        )
    end
end

return MP
