Fx = {
    r = require("src.utils.renderer"), -- R - Render
    i = require("src.utils.input"), -- I - Input
    m = require("src.utils.math"), -- M - Math
    el = require("src.game.effects"), -- EL - Effect List
    es = require("src.game.effectSystem"), -- ES - Effect System
    dq = require("src.utils.drawqueue"), -- DQ - Draw Queue
    cl = require("src.utils.collision"), -- Cl - Collision
    db = { -- DB - DeBug systems
        e = require("src.game.effectUI"), -- db.E - Effects
    },
    ll = require("src.utils.levelLoader"), -- LL - Level Loader
    t = require("src.utils.transition"), -- T - Transition
    bfx = require("src.systems.borderFX"),
    debug = require("src.systems.debug"),
}

Fx.la = require("src.systems.loading") -- LA - Loading Animator

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

local curScene = "intro"
nextScene = nil
scenes = {
    game = require("src.scenes.game"),
    intro = require("src.scenes.intro"),
    menu = require("src.scenes.menu"),
}

GameState = require("src.game.state").new()
GameState.player = require("src.data.player").new()
GameState.area = {}

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

local lastCanvasW, lastCanvasH = 0, 0

local function rebuildCanvas(w, h)
    if w == lastCanvasW and h == lastCanvasH then return end

    canvas = love.graphics.newCanvas(w, h)
    canvas:setFilter("nearest", "nearest")

    Game.width  = w
    Game.height = h

    lastCanvasW = w
    lastCanvasH = h
end

local function computeInternalResolution()
    local screenW, screenH = love.graphics.getDimensions()

    -- Integer scale only
    local scaleX = math.floor(screenW / Game.baseWidth)
    local scaleY = math.floor(screenH / Game.baseHeight)
    scale = math.max(1, math.min(scaleX, scaleY))

    -- Internal resolution implied by scale
    local idealW = math.floor(screenW / scale)
    local idealH = math.floor(screenH / scale)

    -- Delta from base resolution
    local deltaW = idealW - Game.baseWidth
    local deltaH = idealH - Game.baseHeight

    -- Clamp BOTH directions
    deltaW = math.max(-Game.pixelBank / 2, math.min(deltaW, Game.pixelBank))
    deltaH = math.max(-Game.pixelBank / 2, math.min(deltaH, Game.pixelBank))

    return
        Game.baseWidth + deltaW,
        Game.baseHeight + deltaH
end


-- ###################### --
-- ### MAIN FUNCTIONS ### --
-- ###################### --

function love.load()
    canvas = love.graphics.newCanvas(640, 360)
    canvas:setFilter("nearest", "nearest")
    love.window.setIcon(love.image.newImageData("assets/images/system/icon.png"))

    local font = love.graphics.newFont("assets/fonts/m5x7.ttf", 16)
    font:setFilter("nearest", "nearest")
    love.graphics.setFont(font)

    myShader = love.graphics.newShader("assets/shaders/main.glsl")

    Fx.r.loadImage("missing", "assets/images/buffs/missing.png")
    Fx.r.loadImage("logo", "assets/images/ui/logo-outline.png")

    Fx.r.loadImage("loading1", "assets/images/system/loading1.png")
    Fx.r.loadImage("loading2", "assets/images/system/loading2.png")
    Fx.r.loadImage("loading3", "assets/images/system/loading3.png")
    Fx.r.loadImage("loading4", "assets/images/system/loading4.png")

    love.mouse.setCursor(love.mouse.newCursor(
        love.image.newImageData("assets/images/system/cursor.png"),
        0, 0
    ))

    for id, buff in pairs(Fx.el) do
        local path = "assets/images/buffs/" .. buff.id .. ".png"
        if love.filesystem.getInfo(path) then
            Fx.r.loadImage(buff.id, path)
        end
    end

    Fx.bfx.init(70)
    Fx.db.e.load()

    if scenes[curScene] and scenes[curScene].enter then scenes[curScene].enter() end
end

function love.keypressed(k)
    if scenes[curScene] and scenes[curScene].keypressed then scenes[curScene].keypressed(k) end
    
    if k == "b" then
        Fx.db.e.Data.visible = not Fx.db.e.Data.visible
    elseif Fx.db.e.Data.visible then
        Fx.db.e.keypressed(GameState.player, k)
    end
end

local function keypress()
    if Fx.i.pressed("debug") then
        debug = not debug
        Fx.debug.enabled = debug
    elseif Fx.i.pressed("fullscreen") then
        fullScreen = not fullScreen
        love.window.setFullscreen(fullScreen)
    end
end

function love.joystickadded(j)
    table.insert(Fx.i.joysticks, j)
end

function love.joystickremoved(j)
    for i,v in ipairs(Fx.i.joysticks) do
        if v == j then table.remove(Fx.i.joysticks, i) end
    end
end

function love.update(dt)
    Fx.i.update()
    keypress()
    Fx.t.update(dt)
    Fx.bfx.update(dt)
    if nextScene then
        if scenes[curScene] and scenes[curScene].exit then scenes[curScene].exit() end
        if scenes[nextScene] and scenes[nextScene].enter then scenes[nextScene].enter() end
        curScene = nextScene
        nextScene = nil
    end
    if scenes[curScene] and scenes[curScene].update then scenes[curScene].update(dt) end
end


function love.draw()
    local internalW, internalH = computeInternalResolution()
    rebuildCanvas(internalW, internalH)
    local fw, fh = love.graphics.getDimensions()

    love.graphics.clear(8/255, 15/255, 20/255)
    Fx.bfx.draw(0, 0, fw, fh, scale)

    love.graphics.setCanvas({canvas, stencil = true})
    love.graphics.clear(0.01, 0.01, 0.02)

    if scenes[curScene] and scenes[curScene].draw then scenes[curScene].draw() end

    Fx.t.draw()
    Fx.debug.draw()

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setCanvas()

    local screenW, screenH = love.graphics.getDimensions()
    screenX = math.floor((screenW - internalW * scale) / 2)
    screenY = math.floor((screenH - internalH * scale) / 2)

    love.graphics.setShader(myShader)
    love.graphics.draw(canvas, screenX, screenY, 0, scale, scale)
    love.graphics.setShader()
end