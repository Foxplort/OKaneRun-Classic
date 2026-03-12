local PlayerTail = {}

function PlayerTail.applyTailWave(tail, speed, t)
    local moveAmp = math.min(speed / 6000, 0.02) 
    local idleAmp = 0.04

    for i = 2, #tail do
        local a = tail[i - 1]
        local b = tail[i]

        local dx = b.x - a.x
        local dy = b.y - a.y
        local len = math.sqrt(dx*dx + dy*dy)
        if len == 0 then len = 0.001 end

        -- Calculate Normal (perpendicular)
        local nx, ny = -dy / len, dx / len

        -- Wave logic: use a lower multiplier on 't' for a slower wag
        local frequency = 3.0
        local waveSpread = 0.4
        local phase = t * frequency - i * waveSpread
        
        -- Tail is stiffer at the base and flexible at the tip
        local stiffness = (i / #tail) 
        local amp = (idleAmp + moveAmp) * stiffness * 1.5

        b.x = b.x + nx * math.sin(phase) * amp
        b.y = b.y + ny * math.sin(phase) * amp
    end
end

function PlayerTail.updateTail(tail, anchorX, anchorY, dt)
    local damping = 0.8
    if math.abs(GameState.player.vel.z) > 10 then
        damping = 0.6 -- More drag during jumps/falls
    end

    for i, s in ipairs(tail) do
        if i > 1 then
            local vx = (s.x - s.px) * damping
            local vy = (s.y - s.py) * damping
            s.px, s.py = s.x, s.y
            s.x, s.y = s.x + vx, s.y + vy
        end
    end

    -- Anchor
    tail[1].x = anchorX
    tail[1].y = anchorY
    tail[1].px = anchorX
    tail[1].py = anchorY

    -- Constraint Solver (Firmness)
    for _ = 1, 4 do
        for i = 2, #tail do
            local a = tail[i-1]
            local b = tail[i]
            local dx, dy = b.x - a.x, b.y - a.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist == 0 then dist = 0.001 end
            
            local percentage = (dist - b.spacing) / dist
            
            -- Move the segment towards the previous one
            b.x = b.x - dx * percentage
            b.y = b.y - dy * percentage
        end
    end
end

return PlayerTail
