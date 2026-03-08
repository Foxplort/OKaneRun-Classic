---@class SceneManager
---@field scenes table
---@field current table?
---@field next string?

local SceneManager = {}

---Create new scene manager
---@return SceneManager
function SceneManager.new()
    return setmetatable({
        scenes = {},
        current = nil,
        next = nil,
    }, { __index = SceneManager })
end

---Register new scene
---@param name string name in code
---@param path string path to the scene file
function SceneManager:reg(name, path)
    self.scenes[name] = path
end

---Change to scene
---@param name string
function SceneManager:goTo(name)
    if name ~= self.current and self.scenes[name] then
        self.next = name
    end
end

---Update scene manager
---@param dt number delta time
function SceneManager:update(dt)
    if self.next then
        if self.current and self.current.exit then
            self.current.exit()
        end
        self.current = require(self.scenes[self.next])
        self.next = nil
        if self.current.enter then
            self.current.enter()
        end
    end

    if self.current and self.current.update then self.current.update(dt) end
end

---Draw current scene
function SceneManager:draw()
    if self.current and self.current.draw then
        self.current.draw()
    end
end

---Handle key presses
---@param key string key pressed
function SceneManager:keypressed(key)
    if self.current and self.current.keypressed then
        self.current.keypressed(key)
    end
end

return SceneManager
