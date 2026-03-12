---@class Scene
---@field enter? fun() Called when scene becomes active
---@field exit? fun() Called when scene becomes inactive
---@field update? fun(dt: number) Called every frame with delta time
---@field draw? fun() Called every frame for rendering
---@field keypressed? fun(key: string) Called on key press

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
        next = nil,
        minDT = minDT,
        canvas = love.graphics.newCanvas(fore.conf.width, fore.conf.height),
        conf = fore.conf,
        data = fore.data,
        lastCanvasW = 0,
        lastCanvasH = 0,
        scale = fore.conf.scale,
        debug = fore.debug,
        hooks = fore.hooks,
    }, { __index = SceneManager })

    if fore.conf.pixelated then
        self.canvas:setFilter("nearest", "nearest")
    else
        self.canvas:setFilter("linear", "linear")
    end

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
    end
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
---@return nil
function SceneManager:draw()
    local pW, pH, vW, vH = self:computeInternalResolution()
    self:rebuildCanvas(pW, pH)

    self.data.width = vW
    self.data.height = vH

    local screenW, screenH = love.graphics.getDimensions()

    love.graphics.setCanvas({self.canvas, stencil = true})
    love.graphics.clear(0.01, 0.01, 0.02)

    love.graphics.push()
    love.graphics.scale(self.scale, self.scale)
    -- Pre-draw hooks
    for _, cb in ipairs(self.hooks.preDraw) do
        cb()
    end
    
    --Current scene
    if self.current and self.current.draw then
        self.current.draw()
    end

    -- Draw hooks
    for _, cb in ipairs(self.hooks.draw) do
        cb()
    end

    --Debug UI
    if self.debug.enabled then
        self.debug.draw()
    end

    -- Post-draw hooks
    for _, cb in ipairs(self.hooks.postDraw) do
        cb()
    end
    love.graphics.pop()

    love.graphics.setCanvas()

    love.graphics.clear(8/255, 15/255, 20/255)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        self.canvas,
        math.floor((screenW - pW) / 2),
        math.floor((screenH - pH) / 2)
    )

    if self.debug.enabled then
        self.debug.dc = love.graphics.getStats().drawcalls
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

---Creates a new canvas based on current size of the window
---@param w number
---@param h number
---@return nil
function SceneManager:rebuildCanvas(w, h)
    if w == self.lastCanvasW and h == self.lastCanvasH then return end

    self.canvas = love.graphics.newCanvas(w, h)
    self.canvas:setFilter("linear", "linear")

    self.lastCanvasW = w
    self.lastCanvasH = h
end

---Computes the internal graphics scale
---@return number, number, number, number #actual W, actual H, canvas W, canvas H 
function SceneManager:computeInternalResolution()
    local screenW, screenH = love.graphics.getDimensions()
    
    -- How much are we need to scale the base resolution to fit the screen
    self.scale = math.min(screenW / self.conf.width, screenH / self.conf.height)

    -- Calculate what the internal size would be to fill the screen
    local idealW = screenW / self.scale
    local idealH = screenH / self.scale

    -- Clamp size using pixelBank
    local canvasW = math.min(idealW, self.conf.width + (self.data.pixelBank or 0))
    local canvasH = math.min(idealH, self.conf.height + (self.data.pixelBank or 0))

    -- Return physical pixels (canvas resolution)
    return math.floor(canvasW * self.scale), math.floor(canvasH * self.scale), canvasW, canvasH
end

return SceneManager
