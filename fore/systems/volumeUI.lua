local VolumeIndicator = {
    visible = false,
    volume = 100,
    alpha = 0,
    y = -50,
    timer = 0,
    DISPLAY_TIME = 1.5,
    WIDTH = 200,
    HEIGHT = 40,
    PADDING = 10
}

function VolumeIndicator:init(fore)
    self.fore = fore
    return self
end

function VolumeIndicator:show(volume)
    self.volume = volume
    self.visible = true
    self.alpha = 1
    self.timer = self.DISPLAY_TIME
    self.y = self.PADDING
end

function VolumeIndicator:update(dt)
    if not self.visible then return end
    
    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.alpha = math.max(0, self.alpha - dt * 2)
        if self.alpha <= 0 then
            self.visible = false
            self.y = -self.HEIGHT
        end
    end
    
    if self.y < self.PADDING then
        self.y = math.min(self.PADDING, self.y + dt * 400)
    end
end

function VolumeIndicator:draw()
    if not self.visible then return end
    
    self:update(fore.time.getDelta())
    
    local uiScale = math.max(1, self.fore.data.scale / 1.5)
    local screenW = love.graphics.getWidth()
    local width, height, padding = self.WIDTH * uiScale, self.HEIGHT * uiScale, self.PADDING * uiScale
    
    local x = screenW - width - padding
    local y = self.y * uiScale
    local alpha255 = math.floor(self.alpha * 255)
    
    self.fore.draw2d.rect(x, y, width, height, {0, 0, 0, 204 * self.alpha})
    self.fore.draw2d.rect(x, y, width, height, {100, 100, 100, 128 * self.alpha}, false)
    
    local volumePercent = math.floor(self.volume)
    local textColor
    
    if self.volume >= 250 then
        textColor = {255, 100, 100, alpha255}
    elseif self.volume >= 150 then
        textColor = {255, 200, 100, alpha255}
    elseif self.volume >= 70 then
        textColor = {200, 255, 200, alpha255}
    else
        textColor = {150, 150, 255, alpha255}
    end
    
    self.fore.text.text("Volume: " .. volumePercent .. "%", x + 10 * uiScale, y + 12 * uiScale, uiScale, textColor)
    
    local barX, barY, barH = x + 10 * uiScale, y + height - 15 * uiScale, 8 * uiScale
    local fullBarW = width - 20 * uiScale
    self.fore.draw2d.rect(barX, barY, fullBarW, barH, {50, 50, 50, 128 * self.alpha})
    
    local barWidth = fullBarW * (self.volume / 2.0 / 100 / 1.5)
    self.fore.draw2d.rect(barX, barY, barWidth, barH, {255, 255, 255, alpha255})
    
    local lineX = barX + fullBarW * 0.333
    self.fore.draw2d.line({lineX, barY - 4 * uiScale, lineX, barY + barH + 4 * uiScale}, {150, 150, 150, 77 * self.alpha}, 1 * uiScale)
end

return VolumeIndicator