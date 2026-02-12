local Menu = {}
Menu.__index = Menu

local PANEL_W = 220
local PANEL_X = 0
local PANEL_Y = -60
local PANEL_H = Game.height+Game.pixelBank+60
local spikeScroll = 0

local function drawZigZagPanel(x, y, w, h, scroll, c)
    local spike = 12
    local step  = 24

    local pts = {
        x, y,
        x + w, y,
    }

    local yy = y - step + scroll
    local dir = 1

    while yy < y + h + step do
        table.insert(pts, x + w + dir * spike)
        table.insert(pts, yy + step / 2)

        table.insert(pts, x + w)
        table.insert(pts, yy + step)

        dir = -dir
        yy = yy + step
    end

    table.insert(pts, x)
    table.insert(pts, y + h)

    Fx.r.polygon(pts, c)
end


function Menu.new(def)
    local m = setmetatable({}, Menu)
    m.title = def.title
    m.options = def.options
    m.selection = def.selection or 1
    m.underline = {}
    for i = 1, #m.options do m.underline[i] = 0 end
    return m
end

function Menu:update(dt, focused)
    spikeScroll = (spikeScroll + dt * 20) % 48

    for i, opt in ipairs(self.options) do
        local target = (focused and i == self.selection and not opt.isLabel and not opt.disabled) and 1 or 0
        self.underline[i] = Fx.m.lerp(self.underline[i], target, dt * 12)
    end
end


function Menu:move(dir)
    local idx = self.selection
    repeat
        idx = (idx + dir - 1) % #self.options + 1
    until (not self.options[idx].isLabel and not self.options[idx].disabled)
    self.selection = idx
end

function Menu:activate()
    local o = self.options[self.selection]
    if not o or o.disabled then return end
    if o.link then love.system.openURL(o.link) end
    if o.action then o.action() end
end

function Menu:draw(alpha, focused)
    local x = 80
    drawZigZagPanel(PANEL_X+2, PANEL_Y, PANEL_W, PANEL_H, spikeScroll, {255, 255, 255})
    drawZigZagPanel(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, spikeScroll, {0, 0, 0})

    Fx.r.text(self.title, x, 60, 2, {1,1,1,alpha})

    for i, opt in ipairs(self.options) do
        local y = 120 + (i-1)*30
        local col = {0.6,0.6,0.6,alpha}

        if focused and i == self.selection then col = {1,1,1,alpha}
        elseif opt.isLabel then col = {0.7,0.7,0.4,alpha}
        elseif opt.disabled then col = {0.2,0.2,0.2,alpha} end

        Fx.r.text(opt.txt, x, y, 1, col)

        local sel = self.underline[i]
        if sel > 0.01 then
            local tw = Fx.r.getTextWidth(opt.txt, 1)
            local uw = tw * sel
            Fx.r.rect(x + (tw-uw)/2, y+14, uw, 2, {1,1,1,alpha*sel})
        end
    end
end

return Menu
