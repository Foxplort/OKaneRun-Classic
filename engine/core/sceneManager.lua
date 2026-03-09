---@class Scene
---@field enter? fun() Called when scene becomes active
---@field exit? fun() Called when scene becomes inactive
---@field update? fun(dt: number) Called every frame with delta time
---@field draw? fun() Called every frame for rendering
---@field keypressed? fun(key: string) Called on key press

---@class SceneManager
---@field scenes table
---@field current Scene?
---@field next string?
---@field minDT number?

local SceneManager = {}

---Create new scene manager
---@param minDT? number|boolean delta time threshold to switch to the fixed timestep system to avoid math issues. (default 1/20)
---@return SceneManager
function SceneManager.new(minDT)
    if minDT == nil or minDT == true then minDT = 1/20
    elseif minDT == false or minDT == 0 then minDT = nil end

    return setmetatable({
        scenes = {},
        current = nil,
        next = nil,
        minDT = minDT,
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

    if self.current and self.current.update then
        -- if framerate is too low - switch to fixed timestep system
        if self.minDT and dt > self.minDT then
            for i=1, math.floor(dt/self.minDT) do
                self.current.update(self.minDT)
                dt = dt - self.minDT
            end
        end
        self.current.update(dt)
    end
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
