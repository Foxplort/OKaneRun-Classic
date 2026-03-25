local PlayerTail = {}

function PlayerTail.applyTailWave(tail, speed, t, dt)
    local dtScale = (dt or (1/60)) * 60
    
    -- Wave intensity scales UP with speed for "fluttering" effect
    local flutterFactor = math.min(speed / 400, 1.0)
    local idleFactor = 1.0 - flutterFactor
    
    for i = 2, #tail do
        local s = tail[i]
        
        -- High frequency for running, slow for idle
        local frequency = 3.0 * idleFactor + 12.0 * flutterFactor
        local phase = t * frequency - i * 0.3
        
        -- Fluttering amp
        local waveAmp = (0.08 * idleFactor + 0.15 * flutterFactor) * (i / #tail) * dtScale
        
        s.x = s.x + math.sin(phase) * waveAmp
        s.y = s.y + math.cos(phase * 0.7) * waveAmp * 0.4
    end
end

function PlayerTail.updateTail(tail, anchorX, anchorY, dt)
    -- Drag
    local damping = 0.3
    damping = damping ^ ((dt or (1/60)) * 60)

    -- Update anchor (Head)
    tail[1].px, tail[1].py = tail[1].x, tail[1].y
    tail[1].x, tail[1].y = anchorX, anchorY

    -- Update segments
    for i = 2, #tail do
        local s = tail[i]
        local prev = tail[i-1]

        -- Physics (Inertia)
        local vx = (s.x - s.px) * damping
        local vy = (s.y - s.py) * damping

        -- Store current as previous
        s.px, s.py = s.x, s.y

        -- Apply "air-y" force: slight lift and follow
        local lift = 0.08 * ((24-i)/24) * (dt or 1/60) * 60
        
        s.x = s.x + vx
        s.y = s.y + vy - lift
        
        -- Link Constraint
        local dx, dy = s.x - prev.x, s.y - prev.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist == 0 then dist = 0.001 end

        -- If the segment is too far, pull it back
        local goalDist = s.spacing or 1.9
        if dist > goalDist then
            local ratio = goalDist / dist
            s.x = prev.x + dx * ratio
            s.y = prev.y + dy * ratio
        end
    end
end

return PlayerTail
