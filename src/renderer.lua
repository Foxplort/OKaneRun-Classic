local Renderer = {}

local function coloring(c)
    if c == nil then return {1, 1, 1, 1} end
    if c[4] == nil then return {c[1]/255, c[2]/255, c[3]/255, 1} end
    return {c[1]/255, c[2]/255, c[3]/255, c[4]/255}
end

local function filling(f)
    if f == nil then f = true end
    if f then f = "fill" else f = "line" end
    return f
end

function Renderer.rect(x, y, w, h, c, f)
    f = filling(f)
    c = coloring(c)

    love.graphics.setColor(c)
    love.graphics.rectangle(f, x, y, w, h)
end

function Renderer.circ(x, y, w, h, c, f, s)
    f = filling(f)
    c = coloring(c)
    if s == nil then s = 8 end

    x = x + w/2
    w = w/2
    y = y + h/2
    h = h/2

    love.graphics.setColor(c)
    love.graphics.ellipse(f, x, y, w, h, s)
end

function Renderer.text(text, x, y, w, h, c)
    c = coloring(c)

    love.graphics.setColor(c)
    love.graphics.print(text, x, y, 0, w, h)
end

return Renderer