local BorderFX = {}

local particles = {}

local height = Game.height

function BorderFX.init(count)
    particles = {}
    for i = 1, count do
        particles[i] = {
            x = math.random(),
            y = math.random(),
            spd = math.random() * 20 + 10,
            a = math.random() * 0.3 + 0.05
        }
    end
end

function BorderFX.update(dt)
    for _, p in ipairs(particles) do
        p.y = (p.y + dt * p.spd / height * Game.baseHeight * 0.01) % 1
    end
end

function BorderFX.draw(x, y, w, h, scale)
    height = h
    for _, p in ipairs(particles) do
        love.graphics.setColor(1, 1, 1, p.a)
        love.graphics.rectangle(
            "fill",
            math.floor(x + p.x * w),
            math.floor(y + p.y * h),
            scale*2, scale*2
        )
    end
end

return BorderFX
