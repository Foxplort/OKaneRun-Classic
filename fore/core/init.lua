---@class fore
local Fore = {
    version = "2.0.0-dev",
}

local backend = nil
local miscUtil = nil

---Initialize the engine
---@param config table
---@return fore
function Fore.init(config)
    Fore.backend = nil
    if love then
        Fore.backend = "love"
    elseif rl then
        Fore.backend = "raylib"
    end

    if Fore.backend == nil then error("Fore Error: Not running on a supported backend.") end
    backend = Fore.backend

    -- Threads (AKA Worker)
    Fore.worker = require("fore.backend." .. backend .. ".worker")
    Fore.worker.init(Fore)

    -- Graphics and Audio
    Fore.assets = require("fore.systems.assets")
    Fore.assets.init(Fore)
    
    Fore.text = require("fore.backend." .. backend .. ".graphics.text")
    Fore.draw2d = require("fore.backend." .. backend .. ".graphics.draw2d")
    Fore.shader = require("fore.backend." .. backend .. ".graphics.shader")
    Fore.canvas = require("fore.backend." .. backend .. ".graphics.canvas").init(Fore)

    Fore.audio = require("fore.backend." .. backend .. ".audio")
    Fore.audio.init(Fore)

    -- Utils
    Fore.math = require("fore.utils.math")
    Fore.queuer = require("fore.systems.queuer")
    Fore.levelLoader = require("fore.utils.levelLoader")
    Fore.time = require("fore.backend." .. backend .. ".time")
    Fore.task = require("fore.systems.task")

    -- Core
    Fore.conf = require("fore.core.config").init(config)
    Fore.data = require("fore.core.data").init(config, Fore.conf)
    miscUtil = require("fore.backend." .. backend .. ".misc").init(Fore)
    Fore.data.OS = miscUtil.platform()
    Fore.data.phone = miscUtil.isMobile()
    Fore.data.devmode = false
    Fore.data.isCatchingUp = false
    Fore.window = require("fore.backend." .. backend .. ".window")

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
    Fore.camera2d = require("fore.systems.camera2d")


    return Fore
end

---Starts up the engine's work
function Fore:start()
    math.randomseed(os.time()) 
    self.window.init(self)
    self.camera2d.systemInit(self)
    self.text.init(self)
    self.draw2d.init(self)
    self.transition.init()

    self.scenes.canvas = self.canvas.new(self.conf.width, self.conf.height, {
        pixelated = self.conf.pixelated,
        msaa = self.conf.msaa,
    })

    self.audio.setMasterVolume(self.save.get_engine("volume"))

    local init_setup = require("fore.backend." .. backend .. ".hooks")
    init_setup.register(self)
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

    self.assets.update_loading()
    self.input:update()
    self.task.update(dt)
    if self.mobileControls then self.mobileControls:update(dt) end
    
    if self.input:pressed("debug") then self.debug.enabled = not self.debug.enabled end
    if self.input:pressed("editor") and self.data.devmode then self.editor.toggle() end
    if self.input:pressed("fullscreen") then
        self.window.setFullscreen(not self.data.fullscreen)
        self.text.updateFonts()
    end

    if self.editor.enabled then
        self.editor.update(dt)
        return -- Skip the rest of game updates
    end

    -- Update hooks
    for _, cb in ipairs(self.hooks.update) do
        cb(dt)
    end

    if self.debug.enabled then self.debug.update(dt)
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

function Fore:draw()
    --COMPUTE RESOLUTION
    local pW, pH, vW, vH = self:computeInternalResolution()
    self:rebuildCanvas(pW, pH)
    self.data.width = vW
    self.data.height = vH
    local screenW, screenH = self.window.getResolution()

    -- CLEAR SCREEN
    self.window.clear({8, 15, 20})

    -- Raw-pre-draw hooks (UNSCALED, DIRECT TO SCREEN)
    for _, cb in ipairs(self.hooks.rawPreDraw) do
        cb()
    end

    -- RENDER TO CANVAS (SCALED CONTENT)
    self.canvasInstance:clear(0.01, 0.01, 0.02)
    self.canvasInstance:beginRender()

    self.window.pushMatrix()
    self.window.scaleMatrix(self.data.scale, self.data.scale)
    
    -- Pre-draw hooks
    for _, cb in ipairs(self.hooks.preDraw) do cb() end

    -- Game rendering
    if not self.editor.enabled then
        self.scenes:draw()

        -- Draw hooks
        for _, cb in ipairs(self.hooks.draw) do cb() end
        
        self.transition.draw()
    else
        self.editor.drawWorld()
    end

    if self.mobileControls then self.mobileControls:draw() end

    -- Post-draw hooks
    for _, cb in ipairs(self.hooks.postDraw) do cb() end

    self.window.popMatrix()
    self.canvasInstance:endRender()

    -- Pre-cavas-draw hooks
    for _, cb in ipairs(self.hooks.preCanvasDraw) do cb() end

    -- DRAW CANVAS TO SCREEN
    self.window.drawCanvasToScreen(
        self.canvasInstance,
        math.floor((screenW - pW) / 2),
        math.floor((screenH - pH) / 2)
    )

    -- Raw-post-draw hooks (UNSCALED, DIRECT TO SCREEN)
    for _, cb in ipairs(self.hooks.rawPostDraw) do cb() end

    if self.editor.enabled then
        self.editor.drawUI()
    end

    -- Debug and Volume UIs
    self._volumeIndicator:draw()

    if self.debug.enabled then
        self.debug.draw()
        self.debug.dc = self.window.getDrawCalls()
    end
end

---Creates a new canvas based on current size of the window
---@param w number
---@param h number
---@return nil
function Fore:rebuildCanvas(w, h)
    if w == self.lastCanvasW and h == self.lastCanvasH then return end

    self.canvasInstance = self.canvas.new(w, h, { pixelated = false })

    self.lastCanvasW = w
    self.lastCanvasH = h
end

---Computes the internal graphics scale
---@return number, number, number, number #actual W, actual H, canvas W, canvas H 
function Fore:computeInternalResolution()
    self.data.windowWidth, self.data.windowHeight = self.window.getResolution()
    
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
