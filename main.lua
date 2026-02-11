Fx = {
    r = require("src.utils.renderer"), -- R - Render
    i = require("src.utils.input"), -- I - Input
    m = require("src.utils.math"), -- M - Math
    dq = require("src.utils.drawqueue"), -- DQ - Draw Queue
    cl = require("src.utils.collision"), -- Cl - Collision
    ll = require("src.utils.levelLoader"), -- LL - Level Loader
    t = require("src.utils.transition"), -- T - Transition
    bfx = require("src.systems.borderFX"),
    debug = require("src.systems.debug"),
}

Fx.la = require("src.systems.loading") -- LA - Loading Animator (needs renderer to work)

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
    -- Now the canvas size matches the actual screen/window dimensions
    if w == lastCanvasW and h == lastCanvasH then return end

    canvas = love.graphics.newCanvas(w, h)
    -- We use "linear" because we want high-res smoothness, not chunky pixels
    canvas:setFilter("linear", "linear")

    lastCanvasW = w
    lastCanvasH = h
end

local function computeInternalResolution()
    local screenW, screenH = love.graphics.getDimensions()
    
    -- 1. How much are we scaling the base resolution to fit the screen?
    scale = math.min(screenW / Game.baseWidth, screenH / Game.baseHeight)

    -- 2. Calculate what the internal size WOULD be to fill the screen
    local idealW = screenW / scale
    local idealH = screenH / scale

    -- 3. Clamp that size using your pixelBank (The "Freedom" limit)
    -- This ensures we don't show more of the game than intended.
    local canvasW = math.min(idealW, Game.baseWidth + (Game.pixelBank or 0))
    local canvasH = math.min(idealH, Game.baseHeight + (Game.pixelBank or 0))

    -- 4. Return physical pixels (canvas resolution)
    -- We multiply by scale so the canvas is native-resolution high-res
    return math.floor(canvasW * scale), math.floor(canvasH * scale), canvasW, canvasH
end


-- ###################### --
-- ### MAIN FUNCTIONS ### --
-- ###################### --

function love.load()
    canvas = love.graphics.newCanvas(640, 360)
    canvas:setFilter("linear", "linear")
    love.window.setIcon(love.image.newImageData("assets/images/system/icon.png"))

    local font = love.graphics.newFont("assets/fonts/JetBrainsMono.ttf", 8, 'light', 8)
    font:setFilter("linear", "linear")
    love.graphics.setFont(font)

    myShader = love.graphics.newShader("assets/shaders/main.glsl")

    Fx.r.loadImage("missing", "assets/images/buffs/missing.png")

    love.mouse.setCursor(love.mouse.newCursor(
        love.image.newImageData("assets/images/system/cursor.png"),
        0, 0
    ))

    Fx.bfx.init(70)

    if scenes[curScene] and scenes[curScene].enter then scenes[curScene].enter() end
end

function love.keypressed(k)
    if scenes[curScene] and scenes[curScene].keypressed then scenes[curScene].keypressed(k) end
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
    -- pW/pH = Physical pixels | vW/vH = Virtual game units
    local pW, pH, vW, vH = computeInternalResolution()
    rebuildCanvas(pW, pH)
    
    -- IMPORTANT: Update your global Game object so scenes know their bounds!
    -- This is what your Menu and UI code already use.
    Game.width = vW
    Game.height = vH

    local screenW, screenH = love.graphics.getDimensions()

    -- 1. Render to High-Res Canvas
    love.graphics.setCanvas({canvas, stencil = true})
    love.graphics.clear(0.01, 0.01, 0.02)

    love.graphics.push()
        -- Scale coordinate system so 1 unit = 1 base game pixel
        love.graphics.scale(scale, scale)
        
        -- Draw scene (Now Game.width is the full elastic width)
        if scenes[curScene] and scenes[curScene].draw then 
            scenes[curScene].draw() 
        end
        
        Fx.t.draw()
        Fx.debug.draw()
    love.graphics.pop()
    
    love.graphics.setCanvas()

    -- 2. Final Presentation
    love.graphics.clear(8/255, 15/255, 20/255)
    Fx.bfx.draw(0, 0, screenW, screenH, scale)

    -- Center the canvas on the physical screen
    screenX = math.floor((screenW - pW) / 2)
    screenY = math.floor((screenH - pH) / 2)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader(myShader)
    love.graphics.draw(canvas, screenX, screenY) 
    love.graphics.setShader()
end