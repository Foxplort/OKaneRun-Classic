local Particles = {}

local list = {}

function Particles.spawnDust(x, y, z, vx, vy)
    for i = 1, 4 do -- Spawn a small cluster
        table.insert(list, {
            x = x + math.random(-5, 5),
            y = y,
            z = z,
            vx = math.random(-40, 40) + (vx or 0) / 2,
            vy = math.random(-20, 20) + (vy or 0) / 3,
            vz = math.random(10, 30),  -- initial "puff" upward
            life = 1.0,
            size = math.random(2, 4)
        })
    end
end

function Particles.spawnLandingDust(x, y, z)
    local count = 8
    for i = 1, count do
        local a = (i / count) * math.pi * 2
        local r = math.random(30, 60)

        table.insert(list, {
            x = x,
            y = y,
            z = z,
            vx = math.cos(a) * r,
            vy = math.sin(a) * r/2,
            vz = math.random(2, 10),
            life = 1.0,
            size = math.random(2, 4)
        })
    end
end

function Particles.updateParticles(dt)
    for i = #list, 1, -1 do
        local p = list[i]
        
        -- Air resistance (drag)
        p.vx = fore.math.approach(p.vx, 0, 100 * dt)
        p.vy = fore.math.approach(p.vy, 0, 100 * dt)
        p.vz = p.vz - 20 * dt -- very light gravity for dust
        
        -- Move
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.z = p.z + p.vz * dt
        
        p.life = p.life - dt
        if p.life <= 0 then table.remove(list, i) end
    end
end

function Particles.draw(depthFn)
    for _, p in ipairs(list) do
        fore.queuer.submit(
            L.ACTOR,
            p.y,
            function()
                local alpha = p.life * 180
                local s = p.size * (0.5 + p.life * 0.5)
                local speed = math.sqrt(p.vx*p.vx + p.vy*p.vy)
                local stretch = math.min(speed * 0.02, 2)

                fore.graphics.circ(
                    p.x - s/2,
                    p.y - p.z - s,
                    s + stretch,
                    s,
                    {255,255,255,alpha},
                    true, 6
                )
            end
        )
    end
end

function Particles.reset()
    list = {}
end

return Particles
