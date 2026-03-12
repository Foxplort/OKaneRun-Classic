---@class fore
---@field scenes fore.scenes
---@field graphics any
---@field audio fore.audio
---@field math table
---@field conf table
---@field data table
---@field debug any
---@field version string
---@field hooks table
local Fore = {
    version = "0.0.0",
}

---Initialize the engine
---@param config table
---@return fore
function Fore.init(config)
    Fore.graphics = require("fore.utils.graphics")
    Fore.math = require("fore.utils.math")
    Fore.audio = require("fore.utils.audio")
    Fore.queuer = require("fore.utils.queuer")

    Fore.conf = require("fore.core.config").init(config)
    Fore.data = require("fore.core.data").init(config, Fore.conf)

    Fore.hooks = {
        preUpdate = {},   -- Called before everything
        update = {},      -- Called during update
        postUpdate = {},  -- Called after update
        preDraw = {},     -- Called before drawing
        draw = {},        -- Called after drawing
        postDraw = {},    -- Called after debug
    }

    Fore.debug = require("fore.systems.debug")
    Fore.scenes = require("fore.core.scenes").init(Fore)
    Fore.input = require("fore.utils.input").init(Fore.data.deadzone)

    return Fore
end


function Fore:start()
    love.window.setMode(
        self.data.width*self.conf.scale,
        self.data.height*self.conf.scale,
        { 
            fullscreen = self.data.fullscreen,
            vsync = self.data.vsync,
            resizable = self.data.resizable,
            minwidth = self.data.width,
            minheight = self.data.height,
        }
    )

    love.window.setTitle(self.data.title)
    if self.data.icon then
        love.window.setIcon(love.image.newImageData(self.data.icon))
    end

    love.load = function() self:load() end
    love.update = function(dt) self:update(dt) end
    love.draw = function() self:draw() end
    love.keypressed = function(key) self:keypressed(key) end
end

---Introduces new functions into the main loop
---@param when "preUpdate"|"update"|"postUpdate"|"preDraw"|"draw"|"postDraw" #PRE AND POST DRAW FUNCTIONS DO NOT INCLUDE SCALING
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
    -- Go to starting scene
    self.scenes:goTo(self.conf.startScene)
end

function Fore:update(dt)
    -- Pre-update hooks
    for _, cb in ipairs(self.hooks.preUpdate) do
        cb(dt)
    end

    self.input:update()
    if self.input:pressed("debug") then self.debug.enabled = not self.debug.enabled end
    if self.input:pressed("fullscreen") then
        self.data.fullscreen = not self.data.fullscreen
        love.window.setFullscreen(self.data.fullscreen, "desktop")
    end

    -- Update hooks
    for _, cb in ipairs(self.hooks.update) do
        cb(dt)
    end

    if self.debug.enabled then self.debug.update() end
    self.audio.update(dt)
    self.scenes:update(dt)

    -- Post-update hooks
    for _, cb in ipairs(self.hooks.postUpdate) do
        cb(dt)
    end
end

function Fore:draw()
    self.scenes:draw()
end

function Fore:keypressed(key)
    self.debug.keypressed(key)
    self.scenes:keypressed(key)
end

return Fore
