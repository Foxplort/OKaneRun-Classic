local Menu = {}
Menu.__index = Menu

-- ################# --
-- ### VARIABLES ### --
-- ################# --

local PANEL_W = 220
local PANEL_X = 0
local PANEL_TOP = 60

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

function Menu:findFirstSelectable()
    for i, opt in ipairs(self.options) do
        if not opt.isLabel and not opt.disabled then
            return i
        end
    end
    return 1
end

local function getTextX(align, panelX, panelW, textWidth)
    if align == "center" then
        return panelX + (panelW - textWidth) / 2
    elseif align == "right" then
        return panelX + panelW - textWidth
    else -- "left"
        return panelX + 20  -- Add left padding
    end
end

-- #################### --
-- ### MENU OBJECTS ### --
-- #################### --

function Menu:new(def)
    local m = setmetatable({}, Menu)

    m.title     = def.title or ""
    m.options   = def.options or {}
    m.selection = def.selection or 1
    m.dialogue  = def.dialogue
    m.style     = def.style or "plain"
    m.align     = def.align or "left"

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

    self.animTime = 0
    self.lastFocused = false

    return m
end

function Menu:update(dt, focused)
    self.spikeScroll = (self.spikeScroll + dt * 20) % 48
    
    -- Track focus state with time
    if self.lastFocused ~= focused then
        self.animTime = 0  -- Reset timer on focus change
        self.lastFocused = focused
    else
        self.animTime = self.animTime + dt
    end
    
    -- MENU slides LEFT when inactive
    local targetSlide = focused and 0 or 1
    local slideSpeed = 12
    self.slideX = Fx.m.lerp(self.slideX, targetSlide, math.min(dt * slideSpeed, 1))
    
    -- Alpha based on focus and time
    local targetAlpha = focused and 1 or 0.15
    self.alpha = Fx.m.lerp(self.alpha, targetAlpha, math.min(dt * 10, 1))
    
    -- Underline and description use the same pattern
    for i, opt in ipairs(self.options) do
        local targetUnderline = focused and i == self.selection 
            and not opt.isLabel and not opt.disabled and 1 or 0
        self.underline[i] = Fx.m.lerp(self.underline[i], targetUnderline, math.min(dt * 12, 1))
    end
    
    -- Description
    local opt = self.options[self.selection]
    local hasDesc = focused and opt and opt.desc
    local targetComment = hasDesc and 1 or 0
    self.commentT = Fx.m.lerp(self.commentT, targetComment, math.min(dt * 8, 1))
    if hasDesc then self.comment = opt.desc end
end


function Menu:move(dir)
    local i = self.selection
    Fx.s.play("select", {
        volume = 0.08,
        pitch = 1.0 + math.random(-10, 10)/100
    })
    repeat
        i = (i + dir - 1) % #self.options + 1
    until not self.options[i].isLabel and not self.options[i].disabled
    self.selection = i
end

function Menu:activate(stack)
    local o = self.options[self.selection]
    if not o or o.disabled then return end
    Fx.s.play("accept_alt", {
        pitch = 1.0 + math.random(43, 48)/100,
        volume = 0.1
    })
    Fx.s.play("accept", {
        pitch = 1.0 + math.random(-3, 3)/100,
        volume = 0.4
    })
    if o.link then love.system.openURL(o.link) end
    if o.push then stack:push(o.push()) return end
    if o.pop then stack:pop() return end
    if o.action then o.action() end
end

function Menu:resetAnimation()
    self.slideX = 1
    self.alpha  = 0
    self.selection = self:findFirstSelectable()
end

-- ###################### --
-- ### DRAW FUNCTIONS ### --
-- ###################### --

function Menu:drawContent(focused)
    local xOffset = -self.slideX * 60
    local panelX = PANEL_X + 40 + xOffset - 15
    local panelW = PANEL_W - 40
    local y = PANEL_TOP
    local a = self.alpha

    if self.style == "spikes" then
        drawZigZagPanel(
            PANEL_X + xOffset,
            0,
            PANEL_W,
            fore.conf.height,
            self.spikeScroll,
            {0,0,0,a}
        )
    end

    local titleWidth = Fx.r.getTextWidth(self.title, 2)
    local titleX = getTextX(self.align, panelX, panelW, titleWidth)
    Fx.r.text(self.title, titleX, y, 2, {1,1,1,a})

    for i, opt in ipairs(self.options) do
        local yy = y + 60 + (i-1)*30
        local c = {0.6,0.6,0.6,a}

        if focused and i == self.selection then c = {1,1,1,a}
        elseif opt.isLabel then c = {0.7,0.7,0.4,a}
        elseif opt.disabled then c = {0.2,0.2,0.2,a} end

        -- Calculate text width
        local textWidth = Fx.r.getTextWidth(opt.txt, 1)
        local textX = getTextX(self.align, panelX, panelW, textWidth)

        Fx.r.text(opt.txt, textX, yy, 1, c)

        -- Underline positioned based on alignment
        local u = self.underline[i]
        if u > 0.01 then
            local underlineX
            if self.align == "center" then
                underlineX = panelX + (panelW - textWidth * u) / 2
            elseif self.align == "right" then
                underlineX = panelX + panelW - textWidth * u
            else -- left
                underlineX = panelX + 20
            end
            Fx.r.rect(underlineX, yy+14, textWidth * u, 2, {1,1,1,a*u})
        end
    end
end

-- ################### --
-- ### DESCRIPTION ### --
-- ################### --

function Menu:drawDescription()
    if self.commentT < 0.01 then return end

    local freeX = PANEL_W
    local freeW = fore.conf.width - PANEL_W

    local x = freeX + freeW/2 - self.commentW/2
    local y = fore.conf.height - self.commentH - 20
              + (1-self.commentT)*60

    local a = self.commentT * 0.627

    -- shadow
    Fx.r.rect(x, y, self.commentW, self.commentH, {0,0,0,a})
    -- background
    Fx.r.rect(x-1, y-1, self.commentW+2, self.commentH+2, {1,1,1,a}, false)

    Fx.r.textEx(
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
        canvas = love.graphics.newCanvas(fore.conf.width, fore.conf.height)
    }, MenuStack)
end

function MenuStack:push(menu)
    menu:resetAnimation()
    table.insert(self.stack, menu)
end

function MenuStack:pop()
    if #self.stack > 1 then
        table.remove(self.stack)
        local top = self.stack[#self.stack]
        top:resetAnimation()
    end
end

function MenuStack:update(dt)
    for i, m in ipairs(self.stack) do
        m:update(dt, i == #self.stack)
    end
end

function MenuStack:draw()
    for i, m in ipairs(self.stack) do
        local focused = (i == #self.stack)

        m:drawContent(focused)
        if focused then m:drawDescription() end
    end
end

function MenuStack:input()
    local m = self.stack[#self.stack]
    if Fx.i:pressed("up") then m:move(-1) end
    if Fx.i:pressed("down") then m:move(1) end
    if Fx.i:pressed("cancel") then self:pop() end
    if Fx.i:pressed("accept") then m:activate(self) end
end

return {
    Menu = Menu,
    Stack = MenuStack
}
