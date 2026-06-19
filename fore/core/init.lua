---@class fore
---@field scenes fore.scenes
---@field graphics any
---@field audio fore.audio
---@field math table
---@field conf table
---@field data table
---@field debug any
---@field version string
---@field camera fore.camera
---@field hooks table<string, function[]>
local Fore = {
    version = "1.0.0",
}

---Initialize the engine
---@param config table
---@return fore
function Fore.init(config)
    Fore.channels = {
        loader = love.thread.getChannel("fore_loader"),
        response = love.thread.getChannel("fore_response")
    }

    Fore.loaderThread = love.thread.newThread("fore/utils/loaderThread.lua")
    Fore.loaderThread:start()

    Fore.graphics = require("fore.utils.graphics")
    Fore.graphics.fore = Fore
    Fore.shader = require("fore.utils.shader")
    Fore.math = require("fore.utils.math")
    Fore.audio = require("fore.utils.audio")
    Fore.audio.init(Fore)
    Fore.queuer = require("fore.systems.queuer")
    Fore.levelLoader = require("fore.utils.levelLoader")

    Fore.conf = require("fore.core.config").init(config)
    Fore.data = require("fore.core.data").init(config, Fore.conf)
    Fore.data.OS = love.system.getOS()
    Fore.data.phone = (Fore.data.OS == "Android") or (Fore.data.OS == "iOS")
    Fore.data.devmode = false
    Fore.data.isCatchingUp = false

    Fore.hooks = {
        preUpdate = {},     -- Called before everything
        update = {},        -- Called during update
        postUpdate = {},    -- Called after update
        rawPreDraw = {},    -- Called before drawing without scaling
        preCanvasDraw = {}, -- Called just after their canvas pop
        preDraw = {},       -- Called before drawing
        draw = {},          -- Called after drawing
        postDraw = {},      -- Called after debug
        rawPostDraw = {},   -- Called after debug without scaling
        load = {},          -- Called during loading
    }

    Fore.debug = require("fore.systems.debug")
    Fore.scenes = require("fore.systems.scenes").init(Fore)
    Fore.input = require("fore.utils.input").init(Fore, Fore.data.deadzone)

    Fore.audio.load("system_volume_change", "fore/assets/sounds/volume.ogg", false, "sfx")
    Fore._volumeIndicator = require("fore.systems.volumeUI"):init(Fore)

    Fore.editor = require("fore.systems.editor").init(Fore)

    Fore.save = require("fore.systems.save")
    Fore.save.init(config.save or {}, Fore)

    Fore.transition = require("fore.systems.transition")
    Fore.camera = require("fore.systems.camera")


    return Fore
end


function Fore:start()
    love.window.setMode(
        self.data.width*self.data.scale,
        self.data.height*self.data.scale,
        { 
            fullscreen = self.data.fullscreen,
            vsync = self.data.vsync,
            resizable = self.data.resizable,
            minwidth = self.data.width,
            minheight = self.data.height,
            msaa = (self.conf.pixelated and 4) or 0,
        }
    )

    love.window.setTitle(self.data.title)
    if self.data.icon then
        love.window.setIcon(love.image.newImageData(self.data.icon))
    end

    self.camera.systemInit(self)
    self.graphics.init()
    Fore.transition.init()
    self.scenes.canvas = love.graphics.newCanvas(fore.conf.width, fore.conf.height)
    if self.conf.pixelated then
        self.scenes.canvas:setFilter("nearest", "nearest")
    else
        self.scenes.canvas:setFilter("linear", "linear")
    end

    self.audio.setMasterVolume(self.save.get_engine("volume"))

    love.load = function() self:load() end
    love.update = function(dt) self:update(dt) end
    love.draw = function() self:draw() end
    love.keypressed = function(key) self:keypressed(key) end
    love.mousepressed = function(x, y, button, istouch) self:mousepressed(x, y, button, istouch) end
    love.mousemoved = function(x, y, dx, dy, istouch) self:mousemoved(x, y, dx, dy, istouch) end
    love.mousereleased = function(x, y, button, istouch) self:mousereleased(x, y, button, istouch) end
    love.gamepadpressed = function(j, b) self:gamepadpressed(j, b) end
    love.gamepadaxis = function(j, a, v) self:gamepadaxis(j, a, v) end
    love.joystickadded = function(j) self:joystickadded(j) end
    love.joystickremoved = function (j) self:joystickremoved(j) end
    love.touchpressed = function(id, x, y) self:touchpressed(id, x, y) end
    love.touchreleased = function(id, x, y) self:touchreleased(id, x, y) end
    love.wheelmoved = function(x, y) self:wheelmoved(x, y) end
    love.resize = function(w,h) self:resize(w,h) end
    love.textinput = function(t) self:textinput(t) end
end

---Introduces new functions into the main loop
---@param when "preUpdate"|"update"|"postUpdate"|"rawPreDraw"|"preCanvasDraw"|"preDraw"|"draw"|"postDraw"|"rawPostDraw"|"load"
---@param callback function
---@return nil
function Fore:introduce(when, callback)
    if self.hooks[when] then
        table.insert(self.hooks[when], callback)
    else
        print("Unknown hook point: " .. when)
    end
end

function Fore:load()
    for _, cb in ipairs(self.hooks.load) do
        cb()
    end

    -- Go to starting scene
    self.transition.start("dither", function()
        self.scenes:goTo(self.conf.startScene)
    end, nil, 0, 0.5)
end

function Fore:update(dt)
    -- Pre-update hooks
    for _, cb in ipairs(self.hooks.preUpdate) do
        cb(dt)
    end

    self.graphics.update_loading()
    self.input:update()
    if self.mobileControls then self.mobileControls:update(dt) end
    
    if self.input:pressed("debug") then self.debug.enabled = not self.debug.enabled end
    if self.input:pressed("editor") and self.data.devmode then self.editor.toggle() end
    if self.input:pressed("fullscreen") then
        self.data.fullscreen = not self.data.fullscreen
        love.window.setFullscreen(self.data.fullscreen, "desktop")
        self.graphics.updateFonts()
    end

    if self.editor.enabled then
        self.editor.update(dt)
        return -- Skip the rest of game updates
    end

    -- Update hooks
    for _, cb in ipairs(self.hooks.update) do
        cb(dt)
    end

    if self.debug.enabled then self.debug.update()
    else
        local changedVol = false
        local vol = self.audio.masterVolume
        if self.input:pressed("volumeUp") then changedVol = 1 end
        if self.input:pressed("volumeDown") then changedVol = -1 end
        if changedVol then
            if vol < 100 then
                self.audio.setMasterVolume(vol + (20*changedVol))
            else
                self.audio.setMasterVolume(vol + (40*changedVol))
            end
            self.save.set_engine("volume", self.audio.masterVolume)
            self.save.write()
            self.audio.play("system_volume_change")
            self._volumeIndicator:show(self.audio.masterVolume)
        end
    end
    self.audio.update(dt)
    self.scenes:update(dt)
    self._volumeIndicator:update(dt)
    self.transition.update(dt)

    -- Post-update hooks
    for _, cb in ipairs(self.hooks.postUpdate) do
        cb(dt)
    end
end

function Fore:resize(w,h)
    self.graphics.updateFonts()
    self.last_font_scale = self.data.scale
end

function Fore:draw()
    --COMPUTE RESOLUTION
    local pW, pH, vW, vH = self:computeInternalResolution()
    self:rebuildCanvas(pW, pH)
    self.data.width = vW
    self.data.height = vH
    local screenW, screenH = love.graphics.getDimensions()

    -- CLEAR SCREEN
    love.graphics.clear(8/255, 15/255, 20/255)

    -- Raw-pre-draw hooks (UNSCALED, DIRECT TO SCREEN)
    for _, cb in ipairs(self.hooks.rawPreDraw) do
        cb()
    end

    -- RENDER TO CANVAS (SCALED CONTENT)
    love.graphics.setCanvas({self.canvas, stencil = true})
    love.graphics.clear(0.01, 0.01, 0.02)

    love.graphics.push()
    love.graphics.scale(self.data.scale, self.data.scale)
    
    -- Pre-draw hooks
    for _, cb in ipairs(self.hooks.preDraw) do
        cb()
    end

    -- Game rendering
    if not self.editor.enabled then
        self.scenes:draw()

        -- Draw hooks
        for _, cb in ipairs(self.hooks.draw) do
            cb()
        end
        
        self.transition.draw()
    else
        self.editor.drawWorld()
    end

    -- Post-draw hooks
    if self.mobileControls then self.mobileControls:draw() end

    for _, cb in ipairs(self.hooks.postDraw) do
        cb()
    end

    love.graphics.pop()
    love.graphics.setCanvas()

    -- Pre-cavas-draw hooks
    for _, cb in ipairs(self.hooks.preCanvasDraw) do
        cb()
    end

    -- DRAW CANVAS TO SCREEN
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        self.canvas,
        math.floor((screenW - pW) / 2),
        math.floor((screenH - pH) / 2)
    )

    -- Raw-post-draw hooks (UNSCALED, DIRECT TO SCREEN)
    for _, cb in ipairs(self.hooks.rawPostDraw) do
        cb()
    end

    if self.editor.enabled then
        self.editor.drawUI()
    end

    -- Debug UI
    if self.debug.enabled then
        self.debug.draw()
    end
    self._volumeIndicator:draw()

    -- Update debug draw calls
    if self.debug.enabled then
        self.debug.dc = love.graphics.getStats().drawcalls
    end
end

function Fore:keypressed(key)
    self.input:setMethod("keyboard")
    self.debug.keypressed(key)
    if self.editor.enabled then self.editor.keypressed(key) end
    self.scenes:keypressed(key)
end

function Fore:mousepressed(x, y, button, istouch)
    if istouch then return end
    self.input:setMethod("keyboard")
    if self.editor.enabled then self.editor.mousepressed(x, y, button, istouch) end
end

function Fore:mousemoved(x, y, dx, dy, istouch)
    if istouch then return end
    if math.abs(dx) > 0.1 or math.abs(dy) > 0.1 then
        self.input:setMethod("keyboard")
    end
    if self.editor.enabled then self.editor.mousemoved(x, y, dx, dy, istouch) end
end

function Fore:mousereleased(x, y, button, istouch)
    if self.editor.enabled then self.editor.mousereleased(x, y, button, istouch) end
end

function Fore:wheelmoved(x, y)
    if self.editor.enabled then self.editor.wheelmoved(x, y) end
end

function Fore:textinput(t)
    if self.editor.enabled and self.editor.textinput then self.editor.textinput(t) end
end

function Fore:gamepadpressed(joystick, button)
    self.input:setMethod("gamepad")
end

function Fore:gamepadaxis(joystick, axis, value)
    if math.abs(value) > self.input.deadzone then
        self.input:setMethod("gamepad")
    end
end

function Fore:joystickadded(j)
    self.input:addJoystick(j)
end

function Fore:joystickremoved(j)
    self.input:removeJoystick(j)
end

function Fore:touchpressed(id, x, y)
    -- Convert screen coordinates to canvas coordinates if necessary
    local pW, pH, vW, vH = self:computeInternalResolution()
    local screenW, screenH = love.graphics.getDimensions()
    local offsetX = (screenW - pW) / 2
    local offsetY = (screenH - pH) / 2
    
    local tx = (x * screenW - offsetX) / self.data.scale
    local ty = (y * screenH - offsetY) / self.data.scale
    
    if self.mobileControls and self.mobileControls:isHit(tx, ty) then
        return
    end

    self.input:touchpressed(id, tx, ty)
end

function Fore:touchreleased(id, x, y)
    local pW, pH, vW, vH = self:computeInternalResolution()
    local screenW, screenH = love.graphics.getDimensions()
    local offsetX = (screenW - pW) / 2
    local offsetY = (screenH - pH) / 2
    
    local tx = (x * screenW - offsetX) / self.data.scale
    local ty = (y * screenH - offsetY) / self.data.scale
    
    self.input:touchreleased(id, tx, ty)
end

---Creates a new canvas based on current size of the window
---@param w number
---@param h number
---@return nil
function Fore:rebuildCanvas(w, h)
    if w == self.lastCanvasW and h == self.lastCanvasH then return end

    self.canvas = love.graphics.newCanvas(w, h)
    self.canvas:setFilter("linear", "linear")

    self.lastCanvasW = w
    self.lastCanvasH = h
end

---Computes the internal graphics scale
---@return number, number, number, number #actual W, actual H, canvas W, canvas H 
function Fore:computeInternalResolution()
    self.data.windowWidth, self.data.windowHeight = love.graphics.getDimensions()
    
    -- How much are we need to scale the base resolution to fit the screen
    self.data.scale = math.min(self.data.windowWidth / self.conf.width, self.data.windowHeight / self.conf.height)

    -- Calculate what the internal size would be to fill the screen
    local idealW = self.data.windowWidth / self.data.scale
    local idealH = self.data.windowHeight / self.data.scale

    -- Clamp size using pixelBank
    local canvasW = math.min(idealW, self.conf.width + (self.data.pixelBank or 0))
    local canvasH = math.min(idealH, self.conf.height + (self.data.pixelBank or 0))

    -- Return physical pixels (canvas resolution)
    return math.floor(canvasW * self.data.scale), math.floor(canvasH * self.data.scale), canvasW, canvasH
end

return Fore
