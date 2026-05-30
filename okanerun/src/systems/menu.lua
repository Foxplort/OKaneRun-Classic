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

local function drawZigZagPanel(x, y, w, h, scroll, c, o)
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

    fore.graphics.polygon(pts, c)
    if o then fore.graphics.polygon(pts, {255,255,255,40}, false) end
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
    m.outline   = def.outline or false

    m.underline = {}

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

    -- scrolling variables
    m.scrollY = 0
    m.targetScrollY = 0
    m.viewBottomOffset = def.viewBottomOffset or 80
    m.scrollPadding = def.scrollPadding or 60
    m.fadeSize = def.fadeSize or 10

    return m
end

function Menu:addOption(opt, index)
    if index then
        table.insert(self.options, index, opt)
    else
        table.insert(self.options, opt)
    end
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
    self.slideX = fore.math.lerp(self.slideX, targetSlide, math.min(dt * slideSpeed, 1))
    
    -- Alpha based on focus and time
    local targetAlpha = focused and 1 or 0.15
    self.alpha = fore.math.lerp(self.alpha, targetAlpha, math.min(dt * 10, 1))
    
    -- Underline and description use the same pattern
    for i, opt in ipairs(self.options) do
        local targetUnderline = focused and i == self.selection 
            and not opt.isLabel and not opt.disabled and 1 or 0
        self.underline[i] = fore.math.lerp(self.underline[i] or 0, targetUnderline, math.min(dt * 12, 1))
    end

    -- Scroll logic
    local yStart = PANEL_TOP + 60
    local itemY = yStart + (self.selection - 1) * 30
    local projectedY = itemY - self.targetScrollY
    
    local safeTop = yStart + self.scrollPadding
    local safeBottom = (fore.data.height - self.viewBottomOffset) - self.scrollPadding
    if safeBottom < safeTop then safeBottom = safeTop end

    if projectedY < safeTop then
        self.targetScrollY = self.targetScrollY + (projectedY - safeTop)
    elseif projectedY > safeBottom then
        self.targetScrollY = self.targetScrollY + (projectedY - safeBottom)
    end
    if self.targetScrollY < 0 then self.targetScrollY = 0 end
    self.scrollY = fore.math.lerp(self.scrollY, self.targetScrollY, math.min(dt * 15, 1))
    
    -- Description
    local opt = self.options[self.selection]
    local hasDesc = focused and opt and opt.desc
    local targetComment = hasDesc and 1 or 0
    self.commentT = fore.math.lerp(self.commentT, targetComment, math.min(dt * 8, 1))
    if hasDesc then self.comment = opt.desc end
end


function Menu:move(dir)
    local i = self.selection
    fore.audio.play("select", {
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
    fore.audio.play("accept_alt", {
        pitch = 1.0 + math.random(43, 48)/100,
        volume = 0.1
    })
    fore.audio.play("accept", {
        pitch = 1.0 + math.random(-3, 3)/100,
        volume = 0.4
    })
    if o.link then love.system.openURL(o.link) end
    if o.push then stack:push(o.push()) return end
    if o.pop then stack:pop() return end
    if o.type == "checkbox" and o.action then
        o.action()
    elseif o.type == "scroll" then
        -- scroll is operated with left/right
    elseif o.action then 
        o.action() 
    end
end

function Menu:interact(dir, stack)
    local o = self.options[self.selection]
    if not o or o.disabled then return end
    if o.type == "scroll" and o.action then
        fore.audio.play("select", {
            volume = 0.08,
            pitch = 1.0 + math.random(-10, 10)/100
        })
        o.action(dir)
    end
end

function Menu:click(tx, ty, stack)
    local xOffset = -self.slideX * 60
    local panelX = PANEL_X + 40 + xOffset - 15
    local panelW = PANEL_W - 40
    local y = PANEL_TOP

    for i, opt in ipairs(self.options) do
        if not opt.isLabel and not opt.disabled then
            local yy = y + 60 + (i-1)*30
            local fullText = opt.txt
            if opt.type == "scroll" and opt.getValue then
                fullText = opt.txt .. " < " .. opt.getValue() .. " >"
            end
            
            local textWidth = fore.graphics.getTextWidth(fullText, 1)
            local textHeight = fore.graphics.getTextHeight(1)
            local iconSize = textHeight * 1.2
            
            local logicalWidth = textWidth
            if opt.type == "checkbox" then
                logicalWidth = logicalWidth + iconSize + 8
            end
            if opt.icon then
                logicalWidth = logicalWidth + iconSize + 8
            end
            
            local textX = getTextX(self.align, panelX, panelW, logicalWidth)
            
            -- Hitbox: expand a bit for easier tapping
            if tx >= textX - 20 and tx <= textX + logicalWidth + 20 and
               ty >= yy and ty <= yy + 25 then
                if self.selection == i then
                    if opt.type == "scroll" then
                        local relativeX = tx - textX
                        if opt.icon then relativeX = relativeX - (iconSize + 8) end
                        if relativeX < textWidth / 2 then
                            self:interact(-1, stack)
                        else
                            self:interact(1, stack)
                        end
                    else
                        self:activate(stack)
                    end
                else
                    self.selection = i
                    fore.audio.play("select", { volume = 0.1 })
                end
                return true
            end
        end
    end
    return false
end

function Menu:resetAnimation()
    self.slideX = 1
    self.alpha  = 0
    self.selection = self:findFirstSelectable()

    local yStart = PANEL_TOP + 60
    local itemY = yStart + (self.selection - 1) * 30
    local safeTop = yStart + self.scrollPadding
    local safeBottom = (fore.data.height - self.viewBottomOffset) - self.scrollPadding
    if safeBottom < safeTop then safeBottom = safeTop end

    self.targetScrollY = math.max(0, itemY - safeTop)
    self.scrollY = self.targetScrollY
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
            fore.data.height,
            self.spikeScroll,
            {0,0,0,a},
            self.outline
        )
    end

    local titleWidth = fore.graphics.getTextWidth(self.title, 2)
    local titleX = getTextX(self.align, panelX, panelW, titleWidth)
    fore.graphics.text(self.title, titleX, y, 2, {1,1,1,a})

    local viewTop = y + 60 - 10
    local viewBottom = fore.data.height - self.viewBottomOffset
    local fontSize = fore.data.phone and 1.2 or 1

    for i, opt in ipairs(self.options) do
        local yy = y + 60 + (i-1)*30 - self.scrollY

        local positionAlpha = 1
        if yy < viewTop + self.fadeSize then
            positionAlpha = math.max(0, (yy - viewTop) / self.fadeSize)
        elseif yy > viewBottom - self.fadeSize then
            positionAlpha = math.max(0, (viewBottom - yy) / self.fadeSize)
        end

        if positionAlpha > 0 then
            local optionAlpha = a * positionAlpha
            local c = {0.6,0.6,0.6,optionAlpha}

            if focused and i == self.selection then c = {1,1,1,optionAlpha}
            elseif opt.isLabel then c = {0.7,0.7,0.4,optionAlpha}
            elseif opt.disabled then c = {0.2,0.2,0.2,optionAlpha} end

            -- Calculate text width
            local fullText = opt.txt
            if opt.type == "scroll" and opt.getValue then
                fullText = opt.txt .. " < " .. opt.getValue() .. " >"
            end
            local textWidth = fore.graphics.getTextWidth(fullText, 1) * fontSize
            local textHeight = fore.graphics.getTextHeight(fontSize)
            local iconSize = textHeight * 1.2
            
            local logicalWidth = textWidth
            if opt.type == "checkbox" then
                logicalWidth = logicalWidth + iconSize + 8
            end
            if opt.icon then
                logicalWidth = logicalWidth + iconSize + 8
            end
            
            local startX = getTextX(self.align, panelX, panelW, logicalWidth)
            local currentX = startX

            if opt.icon then
                fore.graphics.imageSafe(opt.icon, opt.icon, currentX, yy + (textHeight - iconSize)/2, iconSize, iconSize, 0, 0, 0, c)
                currentX = currentX + iconSize + 8
            end

            fore.graphics.text(fullText, currentX, yy, fontSize, c)
            
            if opt.type == "checkbox" and opt.state then
                local cbIcon = opt.state() and "checkbox_true" or "checkbox_false"
                fore.graphics.imageSafe(cbIcon, cbIcon, currentX + textWidth + 8, yy + (textHeight - iconSize)/2, iconSize, iconSize, 0, 0, 0, c)
            end

            -- Underline positioned based on alignment
            local u = self.underline[i] or 0
            if u > 0.01 then
                local underlineX
                if self.align == "center" then
                    underlineX = panelX + (panelW - logicalWidth * u) / 2
                elseif self.align == "right" then
                    underlineX = panelX + panelW - logicalWidth * u
                else -- left
                    underlineX = startX
                end
                fore.graphics.rect(underlineX, yy+14, logicalWidth * u, 2, {1,1,1,optionAlpha*u})
            end
        end
    end
end

-- ################### --
-- ### DESCRIPTION ### --
-- ################### --

function Menu:drawDescription()
    if self.commentT < 0.01 then return end

    local freeX = PANEL_W
    local freeW = fore.data.width - PANEL_W

    local x = freeX + freeW/2 - self.commentW/2
    local y = fore.data.height - self.commentH - 20
              + (1-self.commentT)*60

    local a = self.commentT * 0.627

    -- shadow
    fore.graphics.rect(x, y, self.commentW, self.commentH, {0,0,0,a})
    -- background
    fore.graphics.rect(x-1, y-1, self.commentW+2, self.commentH+2, {1,1,1,a}, false)

    fore.graphics.textEx(
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
        canvas = love.graphics.newCanvas(fore.data.width, fore.data.height)
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

    if fore.save.get("hints") then
        local input_hint = "DPad - select\nA - confirm\nB - back"
        if fore.input:getMethod() == "keyboard" then
            input_hint = "WASD / Arrow Keys - select\nSpace - confirm\nEscape - back"
        elseif fore.input:getMethod() == "touch" then
            input_hint = "Swipe - select\nTap - confirm"
        end

        if fore.data.phone then
            fore.graphics.textEx(
                input_hint,
                20, fore.data.height - 40, 1, {255, 255, 255, 120}
            )
        else
            fore.graphics.textEx(
                input_hint,
                20, fore.data.height - 40, 0.75, {255, 255, 255, 70}
            )
        end
    end
end

function MenuStack:input()
    local m = self.stack[#self.stack]
    if fore.input:pressed("up") then m:move(-1) end
    if fore.input:pressed("down") then m:move(1) end
    if fore.input:pressed("left") then m:interact(-1, self) end
    if fore.input:pressed("right") then m:interact(1, self) end
    if fore.input:pressed("cancel") then self:pop() end
    if fore.input:pressed("accept") then m:activate(self) end

    if fore.input.gestures.taps.any then
        m:click(fore.input.gestures.taps.x, fore.input.gestures.taps.y, self)
    end
end

return {
    Menu = Menu,
    Stack = MenuStack
}
