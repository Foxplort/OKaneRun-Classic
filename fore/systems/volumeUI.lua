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
    
    self:update(love.timer.getDelta())
    
    local x = self.fore.data.width - self.WIDTH - self.PADDING
    local y = self.y
    local alpha255 = math.floor(self.alpha * 255)
    
    self.fore.graphics.rect(x, y, self.WIDTH, self.HEIGHT, {0, 0, 0, 204 * self.alpha})
    self.fore.graphics.rect(x, y, self.WIDTH, self.HEIGHT, {100, 100, 100, 128 * self.alpha}, false)
    
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
    
    self.fore.graphics.text("Volume: " .. volumePercent .. "%", x + 10, y + 12, 1, textColor)
    
    self.fore.graphics.rect(x + 10, y + self.HEIGHT - 15, self.WIDTH - 20, 8, {50, 50, 50, 128 * self.alpha})
    
    local barWidth = (self.WIDTH - 20) * (self.volume / 2.0 / 100 / 1.5)
    self.fore.graphics.rect(x + 10, y + self.HEIGHT - 15, barWidth, 8, {255, 255, 255, alpha255})
    
    self.fore.graphics.line({x + 10 + (self.WIDTH - 20) * 0.333, y + self.HEIGHT - 19, x + 10 + (self.WIDTH - 20) * 0.333, y + self.HEIGHT - 11}, {150, 150, 150, 77 * self.alpha}, 1)
end

return VolumeIndicator