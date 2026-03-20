ffi = require("ffi")
fore = require("fore.core.init").init({
    name = "OkaneRun",
    version = "0.1.0-dev",
    startScene = "intro",
    pixelBank = 64,
    icon = "okanerun/assets/images/system/icon.png",
    save = {
        total_runs = 0,
        deaths = 0,
        effects_obtained = 0,
        coint_deposited = 0,
    },
})

Fx = {}
Fx.cl = require("okanerun.src.utils.collision") -- Cl - Collision
Fx.ll = require("okanerun.src.utils.levelLoader") -- LL - Level Loader
Fx.bfx = require("okanerun.src.systems.borderFX")

fore.audio.load("select", "okanerun/assets/sounds/ui/select.wav", false, "sfx")
fore.audio.load("accept", "okanerun/assets/sounds/ui/accept.wav", false, "sfx")
fore.audio.load("accept_alt", "okanerun/assets/sounds/ui/accept_alt.wav", false, "sfx")
fore.scenes:reg("intro", "okanerun.src.scenes.intro")
fore.scenes:reg("menu", "okanerun.src.scenes.menu")
fore.scenes:reg("game", "okanerun.src.scenes.game")
fore.scenes:reg("shop", "okanerun.src.scenes.shop")

fore.input:registerAll({
    accept = {
        keys = { "space", "return" },
        buttons = { "a" }
    },
    cancel = {
        keys = { "backspace", "escape" },
        buttons = { "b" }
    },
    
    debugEffect = {
        keys = { "b", "f4" },
        buttons = { "rightstick" }
    },
    jump = {
        keys = { "space", "up" },
        buttons = { "a" }
    },
    dash = {
        keys = { "lshift", "rshift" },
        buttons = { "b" }
    },
    attack = {
        keys = { "e", "z" },
        buttons = { "x" }
    },
    left = {
        keys = { "a", "left" },
        buttons = { "dpleft" },
        axes = { { axis = "leftx", dir = -1 } }
    },
    right = {
        keys = { "d", "right" },
        buttons = { "dpright" },
        axes = { { axis = "leftx", dir = 1 } }
    },
    up = {
        keys = { "w", "up" },
        buttons = { "dpup" },
        axes = { { axis = "lefty", dir = -1 } }
    },
    down = {
        keys = { "s", "down" },
        buttons = { "dpdown" },
        axes = { { axis = "lefty", dir = 1 } }
    },
})

GameState = require("okanerun.src.game.state").new()
GameState.player = require("okanerun.src.data.player").new()
GameState.area = {}

local bgfx = require("okanerun.src.systems.borderFX")

-- layers
L = {
    FLOOR_DEC  = 0,
    FLOOR      = 1,
    SHADOW     = 2,
    ACTOR      = 3,
}

bgfx.init(70)

local vignetteShader
fore:introduce("load", function()
    vignetteShader = love.graphics.newShader("okanerun/assets/shaders/main.glsl")

    love.mouse.setCursor(love.mouse.newCursor(
        love.image.newImageData("okanerun/assets/images/system/cursor.png"),
        0, 0
    ))
end)

fore:introduce("update", function(dt)
    bgfx.update(dt)
end)

fore:introduce("rawPreDraw", function()
    bgfx.draw(0, 0, fore.data.windowWidth, fore.data.windowHeight, fore.data.scale)
end)

fore:introduce("preCanvasDraw", function()
    love.graphics.setShader(vignetteShader)
    vignetteShader:send("time", love.timer.getTime())
end)

fore:introduce("rawPostDraw", function() love.graphics.setShader() end)

fore:start()
