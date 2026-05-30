local MobileControls = {}
MobileControls.__index = MobileControls

function MobileControls.init(fore)
    local self = setmetatable({
        fore = fore,
        visible = false,
        opacity = 0.4,
        stick = {
            baseX = 80,
            baseY = 0, -- Dynamic
            knobX = 0,
            knobY = 0,
            radius = 60,
            knobRadius = 30,
            deadzone = 15,
            vX = 0,
            vY = 0,
            active = false
        },
        buttons = {
            jump = { x = 0, y = 0, radius = 40, action = "jump", label = "JMP" },
            dash = { x = 0, y = 0, radius = 40, action = "dash", label = "DSH" },
            pause = { x = 0, y = 0, radius = 30, action = "pause", label = "" }
        }
    }, MobileControls)
    
    return self
end

function MobileControls:show() self.visible = true and self.fore.data.phone end
function MobileControls:hide() self.visible = false and self.fore.data.phone end

function MobileControls:updatePositions()
    local width = self.fore.data.width
    local height = self.fore.data.height
    
    self.stick.baseY = height - 80
    self.buttons.jump.x = width - 70
    self.buttons.jump.y = height - 120
    self.buttons.dash.x = width - 150
    self.buttons.dash.y = height - 60
    self.buttons.pause.x = width - 40
    self.buttons.pause.y = 40
end

function MobileControls:isHit(tx, ty)
    if not self.visible then return false end
    self:updatePositions()
    
    -- Stick check
    local sdx = tx - self.stick.baseX
    local sdy = ty - self.stick.baseY
    if sdx*sdx + sdy*sdy < (self.stick.radius * 2.5)^2 then
        return true
    end
    
    -- Buttons check
    for _, btn in pairs(self.buttons) do
        local bdx = tx - btn.x
        local bdy = ty - btn.y
        if bdx*bdx + bdy*bdy < btn.radius*btn.radius then
            return true
        end
    end
    
    return false
end

function MobileControls:update(dt)
    if not self.visible then return end
    self:updatePositions()

    local touches = love.touch.getTouches()
    
    self.stick.vX = 0
    self.stick.vY = 0
    self.stick.active = false
    
    for _, id in ipairs(touches) do
        local x, y = love.touch.getPosition(id)
        
        -- Screen to Canvas translation
        -- Note: love.touch.getPosition returns pixels, not normalized [0, 1]
        local pW, pH, vW, vH = self.fore:computeInternalResolution()
        local screenW, screenH = love.graphics.getDimensions()
        local offsetX = (screenW - pW) / 2
        local offsetY = (screenH - pH) / 2
        local tx = (x - offsetX) / self.fore.data.scale
        local ty = (y - offsetY) / self.fore.data.scale
        
        -- Buttons
        for _, btn in pairs(self.buttons) do
            local dx = tx - btn.x
            local dy = ty - btn.y
            if dx*dx + dy*dy < btn.radius*btn.radius then
                self.fore.input.state[btn.action] = true
            end
        end
        
        -- Stick (Left side of screen)
        if not self.stick.active and tx < self.fore.data.width / 2 then
            local dx = tx - self.stick.baseX
            local dy = ty - self.stick.baseY
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist < self.stick.radius * 2.5 then
                self.stick.active = true
                if dist > self.stick.radius then
                    dx = dx / dist * self.stick.radius
                    dy = dy / dist * self.stick.radius
                    dist = self.stick.radius
                end
                
                self.stick.knobX = dx
                self.stick.knobY = dy
                
                if dist > self.stick.deadzone then
                    self.stick.vX = dx / self.stick.radius
                    self.stick.vY = dy / self.stick.radius
                end
            end
        end
    end
    
    if not self.stick.active then
        self.stick.knobX = 0
        self.stick.knobY = 0
    end
    
    -- Map stick to actions (Threshold 0.4)
    if self.stick.vX > 0.4 then self.fore.input.state["right"] = true end
    if self.stick.vX < -0.4 then self.fore.input.state["left"] = true end
    if self.stick.vY > 0.4 then self.fore.input.state["down"] = true end
    if self.stick.vY < -0.4 then self.fore.input.state["up"] = true end
end

function MobileControls:draw()
    if not self.visible then return end
    
    love.graphics.push("all")
    love.graphics.setLineWidth(2)
    
    local a = self.opacity
    
    -- Stick Base
    love.graphics.setColor(1, 1, 1, a * 0.3)
    love.graphics.circle("line", self.stick.baseX, self.stick.baseY, self.stick.radius)
    love.graphics.circle("fill", self.stick.baseX, self.stick.baseY, self.stick.deadzone)
    
    -- Stick Knob
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.circle("fill", self.stick.baseX + self.stick.knobX, self.stick.baseY + self.stick.knobY, self.stick.knobRadius)
    
    -- Buttons
    for _, btn in pairs(self.buttons) do
        local isDown = self.fore.input.state[btn.action]
        local ba = isDown and a or a * 0.5
        
        love.graphics.setColor(1, 1, 1, ba)
        love.graphics.circle("line", btn.x, btn.y, btn.radius)
        if isDown then
            love.graphics.setColor(1, 1, 1, ba * 0.3)
            love.graphics.circle("fill", btn.x, btn.y, btn.radius)
        end
        
        love.graphics.setColor(1, 1, 1, ba)
        local font = love.graphics.getFont()
        local tw = font:getWidth(btn.label)
        local th = font:getHeight()
        love.graphics.print(btn.label, math.floor(btn.x - tw/2), math.floor(btn.y - th/2))
    end
    
    love.graphics.pop()
end

return MobileControls
