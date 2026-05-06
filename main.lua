ffi = require("ffi")
local game_version = "1.2.0-beta.3-dev"
fore = require("fore.core.init").init({
    name = "OkaneRun Classic",
    title = "OkaneRun Classic v" .. game_version,
    version = game_version,
    startScene = "intro",
    pixelBank = 128,
    icon = "okanerun/assets/images/system/fm.png",
    save = {
        total_runs = 0,
        deaths = 0,
        effects_obtained = 0,
        coins_deposited = 0,
        personal_best = 0,
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
fore.scenes:reg("selection", "okanerun.src.scenes.selection")
fore.scenes:reg("records", "okanerun.src.scenes.records")
fore.scenes:reg("death", "okanerun.src.scenes.death")


fore.input:registerAll({
    accept = {
        keys = { "space", "return" },
        buttons = { "a" }
    },
    cancel = {
        keys = { "backspace", "escape" },
        buttons = { "b" }
    },
    pause = {
        keys = { "backspace", "escape" },
        buttons = { "start" }
    },
    debugEffect = {
        keys = { "b", "f4" },
        buttons = { "rightstick" }
    },
    jump = {
        keys = { "space" },
        buttons = { "a" }
    },
    dash = {
        keys = { "lshift", "rshift" },
        buttons = { "x" }
    },
    attack = {
        keys = { "e", "z" },
        buttons = { "y" }
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
GameState.area = Fx.ll.load("okanerun/src/data/levels/testLevel.lua")

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

fore.editor.onToggle = function(enabled)
    local Objects = require("okanerun.src.data.objects")
    if Objects then
        for _, def in pairs(Objects) do
            if enabled then
                if def.onEditorLoad then def.onEditorLoad() end
            else
                if def.onEditorUnload then def.onEditorUnload() end
            end
        end
    end
end

fore.editor.onPlay = function(levelName)
    love.filesystem.write("play_queue.txt", levelName .. ".4lf")
    if fore.editor.enabled then fore.editor.toggle() end
    fore.scenes:goTo("game")
end

require("okanerun.src.systems.gameEditor").init(fore)

fore:start()
