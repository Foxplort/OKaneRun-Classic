local Types = {}

function Types.coloring(c, pA)
    pA = pA or 1
    if not c then return 1, 1, 1, pA end
    local r, g, b, a = 1, 1, 1, 1
    if type(c) == "number" then
        local v = c > 1 and c / 255 or c
        r, g, b = v, v, v
    elseif type(c) == "table" then
        r, g, b, a = c[1] or 255, c[2] or 255, c[3] or 255, c[4] or 255
        if r > 1 or g > 1 or b > 1 or a > 1 then
            r, g, b, a = r/255, g/255, b/255, a/255
        end
    end
    return r, g, b, a * pA
end

function Types.setColor(c)
    love.graphics.setColor(Types.coloring(c))
end

function Types.filling(f)
    if f == nil then f = true end
    if f then f = "fill" else f = "line" end
    return f
end

return Types
