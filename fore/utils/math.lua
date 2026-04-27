local MathP = {} 

function MathP.approach(v, target, amount)
    if v < target then
        return math.min(v + amount, target)
    elseif v > target then
        return math.max(v - amount, target)
    end
    return target
end

function MathP.clamp(value, min_val, max_val)
    return math.max(min_val, math.min(max_val, value))
end

function MathP.lerp(a, b, t)
    -- If the change is very small, snap to target
    local diff = b - a
    if math.abs(diff) < 0.0001 then
        return b
    end
    return a + diff * t
end

function MathP.aabb(a, b)
    return a.x < b.x + b.w and
           a.x + a.w > b.x and
           a.y < b.y + b.h and
           a.y + a.h > b.y
end

function MathP.hsvToRgb(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return r, g, b
end

return MathP
