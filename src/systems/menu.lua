local Menu = {}
Menu.__index = Menu

-- ################# --
-- ### VARIABLES ### --
-- ################# --

local PANEL_W = 220
local PANEL_X = 0
local PANEL_TOP = 60

local blurShader = love.graphics.newShader [[
extern number strength;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 px)
{
    vec2 offset = strength / vec2(love_ScreenSize.xy);
    
    // 9-sample Gaussian-like blur
    vec4 sum = vec4(0.0);

    sum += Texel(tex, tc) * 0.2270270270;
    sum += Texel(tex, tc + vec2(offset.x, 0.0)) * 0.1945945946;
    sum += Texel(tex, tc - vec2(offset.x, 0.0)) * 0.1945945946;
    sum += Texel(tex, tc + vec2(2.0*offset.x, 0.0)) * 0.1216216216;
    sum += Texel(tex, tc - vec2(2.0*offset.x, 0.0)) * 0.1216216216;
    sum += Texel(tex, tc + vec2(3.0*offset.x, 0.0)) * 0.0540540541;
    sum += Texel(tex, tc - vec2(3.0*offset.x, 0.0)) * 0.0540540541;
    sum += Texel(tex, tc + vec2(4.0*offset.x, 0.0)) * 0.0162162162;
    sum += Texel(tex, tc - vec2(4.0*offset.x, 0.0)) * 0.0162162162;

    return sum * color;
}
]]

-- ######################## --
-- ### HELPER FUNCTIONS ### --
-- ######################## --

local function drawZigZagPanel(x, y, w, h, scroll, c)
    local spike = 12
    local step  = 24
    y = y - step*1.5
    h = h + step*1.5

    local pts = { x, y, x + w, y }

    local yy = y - step + scroll
    local dir = 1

    while yy < y + h + step do
        pts[#pts+1] = x + w + dir * spike
        pts[#pts+1] = yy + step / 2
        pts[#pts+1] = x + w
        pts[#pts+1] = yy + step
        dir = -dir
        yy = yy + step
    end

    pts[#pts+1] = x
    pts[#pts+1] = y + h

    Fx.r.polygon(pts, c)
end

-- #################### --
-- ### MENU OBJECTS ### --
-- #################### --

function Menu.new(def)
    local m = setmetatable({}, Menu)

    m.title     = def.title or ""
    m.options   = def.options or {}
    m.selection = def.selection or 1
    m.dialogue  = def.dialogue
    m.style     = def.style or "plain"

    m.underline = {}
    for i = 1, #m.options do m.underline[i] = 0 end

    -- animation state
    m.slideX = 1       -- 1 = offscreen left
    m.alpha  = 0

    -- description
    m.comment   = ""
    m.commentT  = 0
    m.commentW  = 300
    m.commentH  = 100

    m.spikeScroll = 0

    return m
end

function Menu:update(dt, focused)
    self.spikeScroll = (self.spikeScroll + dt * 20) % 48

    -- MENU slides LEFT when inactive
    self.slideX = Fx.m.lerp(self.slideX, focused and 0 or 1, dt * 8)
    self.alpha  = Fx.m.lerp(self.alpha,  focused and 1 or 0.15, dt * 10)

    for i, opt in ipairs(self.options) do
        local t = focused and i == self.selection
            and not opt.isLabel and not opt.disabled
            and 1 or 0
        self.underline[i] = Fx.m.lerp(self.underline[i], t, dt * 12)
    end

    local opt = self.options[self.selection]
    local hasDesc = focused and opt and opt.desc
    self.commentT = Fx.m.lerp(self.commentT, hasDesc and 1 or 0, dt * 10)
    if hasDesc then self.comment = opt.desc end
end

function Menu:move(dir)
    local i = self.selection
    repeat
        i = (i + dir - 1) % #self.options + 1
    until not self.options[i].isLabel and not self.options[i].disabled
    self.selection = i
end

function Menu:activate(stack)
    local o = self.options[self.selection]
    if not o or o.disabled then return end
    if o.link then love.system.openURL(o.link) end
    if o.push then stack:push(o.push()) return end
    if o.pop then stack:pop() return end
    if o.action then o.action() end
end

-- ###################### --
-- ### DRAW FUNCTIONS ### --
-- ###################### --

function Menu:drawContent(focused)
    local xOffset = -self.slideX * 60
    local x = PANEL_X + 80 + xOffset
    local y = PANEL_TOP
    local a = self.alpha

    if self.style == "spikes" then
        drawZigZagPanel(
            PANEL_X + xOffset,
            0,
            PANEL_W,
            Game.height,
            self.spikeScroll,
            {0,0,0,a}
        )
    end

    Fx.r.text(self.title, x, y, 2, {1,1,1,a})

    for i, opt in ipairs(self.options) do
        local yy = y + 60 + (i-1)*30
        local c = {0.6,0.6,0.6,a}

        if focused and i == self.selection then c = {1,1,1,a}
        elseif opt.isLabel then c = {0.7,0.7,0.4,a}
        elseif opt.disabled then c = {0.2,0.2,0.2,a} end

        Fx.r.text(opt.txt, x, yy, 1, c)

        local u = self.underline[i]
        if u > 0.01 then
            local tw = Fx.r.getTextWidth(opt.txt, 1)
            Fx.r.rect(x + (tw*(1-u))/2, yy+14, tw*u, 2, {1,1,1,a*u})
        end
    end
end

-- ################### --
-- ### DESCRIPTION ### --
-- ################### --

function Menu:drawDescription()
    if self.commentT < 0.01 then return end

    local freeX = PANEL_W
    local freeW = Game.width - PANEL_W

    local x = freeX + freeW/2 - self.commentW/2
    local y = Game.height - self.commentH - 20
              + (1-self.commentT)*40

    local a = self.commentT

    -- shadow
    Fx.r.rect(x+2, y+2, self.commentW, self.commentH, {1,1,1,a*0.15})
    -- background
    Fx.r.rect(x,   y,   self.commentW, self.commentH, {0,0,0,a})

    Fx.r.text(
        self.comment,
        x+12, y+12,
        1,
        {1,1,1,a},
        self.commentW-24,
        "left"
    )
end

-- ################## --
-- ### MENU STACK ### --
-- ################## --

local MenuStack = {}
MenuStack.__index = MenuStack

function MenuStack.new(root)
    return setmetatable({
        stack = { root },
        canvas = love.graphics.newCanvas(Game.width, Game.height)
    }, MenuStack)
end

function MenuStack:push(menu)
    menu.slideX = 1
    menu.alpha  = 0
    table.insert(self.stack, menu)
end

function MenuStack:pop()
    if #self.stack > 1 then table.remove(self.stack) end
end

function MenuStack:update(dt)
    for i, m in ipairs(self.stack) do
        m:update(dt, i == #self.stack)
    end
end

function MenuStack:draw()
    for i, m in ipairs(self.stack) do
        local focused = (i == #self.stack)

        if not focused then
            --m:drawContent(false)

            love.graphics.setShader(blurShader)
            blurShader:send("strength", 8)
            m:drawContent(false)
            love.graphics.setShader()
        else
            m:drawContent(true)
            m:drawDescription()
        end
    end
end

function MenuStack:input()
    local m = self.stack[#self.stack]
    if Fx.i.pressed("up") then m:move(-1) end
    if Fx.i.pressed("down") then m:move(1) end
    if Fx.i.pressed("cancel") then self:pop() end
    if Fx.i.pressed("accept") then m:activate(self) end
end

return {
    Menu = Menu,
    Stack = MenuStack
}
