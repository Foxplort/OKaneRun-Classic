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
    return a + (b - a) * t
end

function MathP.aabb(a, b)
    return a.x < b.x + b.w and
           a.x + a.w > b.x and
           a.y < b.y + b.h and
           a.y + a.h > b.y
end

function MathP.aabb3(a, az, at, b, bz, bt)
    -- X/Y overlap
    if not MathP.aabb(a, b) then return false end

    -- Z overlap
    local aTop = az + at
    local bTop = bz + bt

    return az < bTop and bz < aTop
end

return MathP
