Fx = {
    r = require("src.utils.renderer"), -- R - Render
    i = require("src.utils.input"), -- I - Input
    m = require("src.utils.math"), -- M - Math
    el = require("src.game.buffs"), -- EL - Effect List
    es = require("src.game.buffSystem"), -- ES - Effect System
    dq = require("src.utils.drawqueue"), -- DQ - Draw Queue
    cl = require("src.utils.collision"), -- Cl - Collision
    obj = { -- OBJ - Renderable Objects
        player = require("src.objects.player"),
        world = require("src.objects.world"),
        ui = require("src.objects.ui"),
    },
    db = { -- DB - DeBug systems
        e = require("src.game.buffUI"), -- db.E - Effects
    },
}

local config = {
    integerScaling = true,
    fullScreen = false,
}

local canvas
local scale
local screenX
local screenY

local myShader

-- GAME LOGIC

debug = false

local curScene = "game"
nextScene = nil
scenes = {
    game = require("src.scenes.game"),
}

GameState = require("src.game.state").new()
GameState.player = Fx.obj.player.baseData
GameState.area = Fx.obj.world.testArea

-- layers
L = {
    FLOOR      = 0,
    FLOOR_DEC  = 1,
    SHADOW     = 2,
    ACTOR      = 3,
}

function setScene(name)
    if name ~= curScene then
        nextScene = name
    end
end

-- ###################### --
-- ### MAIN FUNCTIONS ### --
-- ###################### --

function love.load()
    canvas = love.graphics.newCanvas(640, 360)
    canvas:setFilter("nearest", "nearest")
    love.window.setIcon(love.image.newImageData("assets/images/icon.png"))

    myShader = love.graphics.newShader("assets/shaders/main.glsl")

    Fx.r.loadImage("missing", "assets/images/buffs/missing.png")

    for id, buff in pairs(Fx.el) do
        local path = "assets/images/buffs/" .. buff.id .. ".png"
        if love.filesystem.getInfo(path) then
            Fx.r.loadImage(buff.id, path)
        end
    end

    Fx.db.e.load()
end

function love.keypressed(k)
    if scenes[curScene] and scenes[curScene].keypressed then scenes[curScene].keypressed(k) end
    
    if k == "k" then
        debug = not debug
    elseif k == "f11" then
        fullScreen = not fullScreen
        love.window.setFullscreen(fullScreen)
    elseif k == "b" then
        Fx.db.e.Data.visible = not Fx.db.e.Data.visible
    elseif Fx.db.e.Data.visible then
        Fx.db.e.keypressed(GameState.player, k)
    end
end

function love.update(dt)
    if nextScene then
        if scenes[curScene] and scenes[curScene].exit then scenes[curScene].exit() end
        if scenes[nextScene] and scenes[nextScene].enter then scenes[nextScene].enter() end
        curScene = nextScene
        nextScene = nil
    end
    if scenes[curScene] and scenes[curScene].update then scenes[curScene].update(dt) end
end


function love.draw()
    love.graphics.setCanvas({canvas, stencil = true})
    love.graphics.clear(0.01, 0.01, 0.02)

    if scenes[curScene] and scenes[curScene].draw then scenes[curScene].draw() end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setCanvas()

    -- Calculate scale to fill the window while keeping aspect ratio
    local screenW, screenH = love.graphics.getDimensions()
    scale = math.min(screenW / 640, screenH / 360)

    -- If integer scaling is ON, we floor the scale (e.g., 2.7x becomes 2.0x)
    if config.integerScaling then
        scale = math.max(1, math.floor(scale))
    end

    -- Calculate shift to the center
    screenX = math.floor((screenW - 640 * scale) / 2)
    screenY = math.floor((screenH - 360 * scale) / 2)

    love.graphics.setShader(myShader)
    love.graphics.draw(canvas, screenX, screenY, 0, scale, scale)
    love.graphics.setShader()
end