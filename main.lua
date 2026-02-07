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

curScene = "game"
scenes = {
    game = require("src.scenes.game"),
}

camX, camY = 0, 0
shakeAmount = 0
uiShake = 0

particles = {}

player = Fx.obj.player.baseData
area = Fx.obj.world.testArea

GameState = require("src.game.state")
GameState.init(player, area)

-- layers
L = {
    FLOOR      = 0,
    FLOOR_DEC  = 1,
    SHADOW     = 2,
    ACTOR      = 3,
}


BuffUIDat = {
    visible = false,
    x = 10,
    y = 80,
    cols = 8,
    size = 20,
    padding = 4,
    selected = 1,
}

local function actorRenderDepth(x, y, z)
    local depth = y

    for _, w in ipairs(area.walls) do
        local wallMinY = w.y - w.h - w.t
        local wallMaxY = w.y

        local overlappingXY =
            x > w.x and
            x < w.x + w.w and
            y > wallMinY and
            y < wallMaxY

        if overlappingXY then
            local wallTopZ = (w.z or 0) + (w.t or 0)

            if z >= wallTopZ then
                depth = math.max(depth, w.y + 1)
            else
                depth = math.min(depth, w.y - 1)
            end
        end
    end

    return depth
end

-------------------
-- BASE LUA LOVE --
-------------------

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
        BuffUIDat.visible = not BuffUIDat.visible
    elseif BuffUIDat.visible then
        Fx.db.e.keypressed(player, k)
    end
end

function love.update(dt)
    if scenes[curScene] and scenes[curScene].update then scenes[curScene].update(dt) end
end


function love.draw()
    love.graphics.setCanvas({canvas, stencil = true})
    love.graphics.clear(0.01, 0.01, 0.02)

    love.graphics.push()
    love.graphics.translate(math.random(-shakeAmount, shakeAmount), math.random(-shakeAmount, shakeAmount))
    love.graphics.translate(-math.floor(camX), -math.floor(camY))

    -- ## BASE DRAW PART ##

    Fx.obj.player.render() -- render player + shadow

    Fx.obj.world.renderWalls() -- render walls
    Fx.obj.world.renderGround() -- render ground
    Fx.obj.world.renderCoins() -- render coins
    Fx.obj.world.renderCores() -- render cores

    -- Dust
    for _, p in ipairs(particles) do
        Fx.dq.submit(
            L.ACTOR,
            actorRenderDepth(p.x, p.y, p.z),
            function()
                local alpha = p.life * 180
                local s = p.size * (0.5 + p.life * 0.5)

                Fx.r.rect(
                    p.x - s/2,
                    p.y - p.z - s,
                    s, s,
                    {255, 255, 255, alpha}
                )
            end
        )

    end

    -- ## END OF DRAW ##

    Fx.dq.draw() -- draw items in order

    Fx.obj.player.silhuette() -- Player's shiluette


    if debug then
        for _, g in ipairs(area.ground) do
            local gh = Fx.cl.getGroundHitbox(g)
            Fx.r.rect(gh.x, gh.y, gh.w, gh.h, {0,255,255}, false)
        end

        local hb = Fx.cl.getPlayerHitbox()
        Fx.r.rect(hb.x, hb.y, hb.w, hb.h, {255,0,0}, false)

        for _, w in ipairs(area.walls) do
            local wh = Fx.cl.getWallHitbox(w)
            Fx.r.rect(wh.x, wh.y, wh.w, wh.h, {0,255,0}, false)
        end

        for _, c in ipairs(area.cores) do
            Fx.r.rect(c.x, c.y-40, 40, 40, {0,255,0}, false)
        end

        for _, c in ipairs(area.coins) do
            local ch = {x=c.x, y=c.y-3, w=10, h=6}
            Fx.r.rect(ch.x, ch.y, ch.w, ch.h, {255,255,127}, false)
        end
    end

    love.graphics.pop()

    -- ## USER INERTFACE ##

    love.graphics.push()
    if uiShake > 0 then
        love.graphics.translate(math.random(-1, 1), math.random(-1, 1))
    end

    Fx.obj.ui.draw()

    Fx.db.e.draw(player)

    love.graphics.pop()

    -- ## END OF UI ##

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