local Renderer = {}

local function coloring(c)
    if c == nil then return {1, 1, 1, 1} end
    if c[4] == nil then return {c[1]/255, c[2]/255, c[3]/255, 1} end
    return {c[1]/255, c[2]/255, c[3]/255, c[4]/255}
end

function Renderer.rect(x, y, w, h, c, f)
    if f == nil then f = true end
    if f then f = "fill" else f = "line" end
    c = coloring(c)

    love.graphics.setColor(c)
    love.graphics.rectangle(f, x, y, w, h)
end

return Renderer