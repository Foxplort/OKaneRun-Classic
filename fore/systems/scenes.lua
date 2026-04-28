---@class Scene
---@field enter? fun() Called when scene becomes active
---@field exit? fun() Called when scene becomes inactive
---@field update? fun(dt: number) Called every frame with delta time
---@field draw? fun() Called every frame for rendering
---@field keypressed? fun(key: string) Called on key press
---@field onComplete? fun() Called as soon as all assets are loaded in

---@class fore.scenes
---@field scenes table
---@field current Scene?
---@field next string?
---@field minDT number?
---@field canvas Canvas #Lua Love's canvas
---@field conf table
---@field data table
---@field debug table
---@field hooks table
---@field fore fore
local SceneManager = {}

---Create new scene manager
---@param fore fore
---@return fore.scenes
function SceneManager.init(fore)
    local minDT = fore.conf.minDT
    if minDT == nil or minDT == true then minDT = 1/20
    elseif minDT == false or minDT == 0 then minDT = nil end

    local self = setmetatable({
        scenes = {},
        current = nil,
        last = nil,
        next = nil,
        minDT = minDT,
        canvas = nil,
        conf = fore.conf,
        data = fore.data,
        lastCanvasW = 0,
        lastCanvasH = 0,
        debug = fore.debug,
        hooks = fore.hooks,
        fore = fore,
        frameOne = false,
    }, { __index = SceneManager })

    return self
end

---Register new scene
---@param name string name in code
---@param path string path to the scene file
---@return nil
function SceneManager:reg(name, path)
    self.scenes[name] = path
end

---Change to scene
---@param name string
---@return nil
function SceneManager:goTo(name)
    if name ~= self.current and self.scenes[name] then
        self.next = name
        self.last = name
    end
end

function SceneManager:reload()
    self.next = self.last
end

---Get scene
---@param name string
---@return table
function SceneManager:get(name)
    return self.scenes[name]
end

---Update scene manager
---@param dt number delta time
---@return nil
function SceneManager:update(dt)
    if self.next then
        if self.current and self.current.exit then
            self.current.exit()
        end

        self.current = require(self.scenes[self.next])

        if self.current.debug then
            self.fore.debug.add("Scene", function()
                return self.current.debug()
            end)
        end
        
        self.next = nil
        
        if self.current.enter then
            self.current.enter()
        end
        self.frameOne = true
        self.fore.graphics.flushAssetSchedule()
    end

    -- Waiting for the assets to load
    if self.fore.graphics.pending_assets > 0 then
        return
    end

    if self.frameOne and self.current.onComplete then self.current.onComplete() end

    if self.current and self.current.update and (not self.fore.transition.is_frozen or self.frameOne) then
        -- if framerate is too low - switch to fixed timestep system
        if self.minDT and dt > self.minDT then
            for i=1, math.floor(dt/self.minDT) do
                self.current.update(self.minDT)
                dt = dt - self.minDT
            end
        end
        self.current.update(dt)
        if self.frameOne then self.frameOne = false end
    end
end

---Draw current scene
---@return nil
function SceneManager:draw()
    -- Waiting for the assets to load
    if self.fore.graphics.pending_assets > 0 then
        return
    end
    --Current scene
    if self.current and self.current.draw then
        self.current.draw()
    end
end

---Handle key presses
---@param key string key pressed
---@return nil
function SceneManager:keypressed(key)
    if self.current and self.current.keypressed then
        self.current.keypressed(key)
    end
end

return SceneManager
