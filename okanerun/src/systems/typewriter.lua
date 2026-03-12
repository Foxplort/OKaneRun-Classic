local Typewriter = {}
Typewriter.__index = Typewriter

function Typewriter.new(text, speed)
    return setmetatable({
        text = text,
        speed = speed or 40,
        timer = 0,
        index = 0,
        done = false
    }, Typewriter)
end

function Typewriter:update(dt)
    if self.done then return end
    self.timer = self.timer + dt

    local chars = math.floor(self.timer * self.speed)
    if chars > self.index then
        self.index = chars
        if self.index >= #self.text then
            self.index = #self.text
            self.done = true
        end
    end
end

function Typewriter:get()
    return self.text:sub(1, self.index)
end

return Typewriter
