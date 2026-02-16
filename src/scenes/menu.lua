local Scene = {}

local MenuSystem = require("src.systems.menu")
local Menu = MenuSystem.Menu
local Stack = MenuSystem.Stack

local PANEL_WIDTH = 240
local LINE_WIDTH = 2

local stack
local MP

local timer = 1
local fogXShift, fogYShift = 0, 0
local logoY = 0

local glitchShader = love.graphics.newShader("assets/shaders/menu_glitch.glsl")

local function createMenus()
    local main, play, credits, exit

    play = Menu.new{
        title = "MODE",
        options = {
            {
                txt = "Arcade",
                action = function()
                    Fx.t.cover(function()
                        setScene("game")
                    end)
                end,
                desc = "Base gamemode.\nCollect coins, get upgrades at the shop, get cursed,\nand try getting as far as you can!"
            },
            { txt = "Coming Soon...", disabled = true },
            { txt = "---", isLabel = true },
            { txt = "Back", pop = true }
        }
    }

    credits = Menu.new{
        title = "CREDITS",
        options = {
            { txt = "--- CREW ---", isLabel = true },
            { txt = "Dev: Foxplort", link = "https://github.com/foxplort" },
            { txt = "Engine: LÖVE", link = "https://love2d.org/" },
            { txt = "---", isLabel = true },
            { txt = "Back", pop = true }
        }
    }

    exit = Menu.new{
        title = "QUIT?",
        options = {
            { txt = "Confirm", action = function() love.event.quit() end },
            { txt = "Cancel", pop = true }
        }
    }

    main = Menu.new{
        title = "MAIN MENU",
        options = {
            { txt = "Play",    push = function() return play end },
            { txt = "Credits", push = function() return credits end },
            { txt = "Exit",    push = function() return exit end },
        }
    }

    return main
end

function Scene.enter()
    Fx.r.loadImage("logo", "assets/images/ui/logo-smooth.png", "linear")
    Fx.r.loadImage("menu_portrait", "assets/images/ui/menu_portrait.png", "linear")
    Fx.r.loadImage("menu_fog", "assets/images/ui/menu_fog.png", "linear")

    MP = require("src.systems.menuParticles")
    MP.init(PANEL_WIDTH)

    local root = createMenus()
    stack = Stack.new(root)

    GameState.player = require("src.data.player").new()
end

function Scene.exit()
    Fx.r.unloadImage("logo")
end


function Scene.update(dt)
    stack:update(dt)
    stack:input()
    MP.update(dt)

    timer = timer + dt
    glitchShader:send("time", timer)
    glitchShader:send("intensity", 0.003)
    fogXShift = math.sin(timer / 3) * 20
    fogYShift = math.sin(timer) * 4 + 4
    logoY = math.sin(timer / 2) * 4
end

function Scene.draw()
    -- background
    Fx.r.rect(PANEL_WIDTH, 0, Game.width - PANEL_WIDTH, Game.height, {8,15,20})
    MP.drawBack()

    local iw, ih = Fx.r.getImage("menu_portrait"):getDimensions()

    local areaX = PANEL_WIDTH
    local areaW = Game.width - PANEL_WIDTH

    local x = PANEL_WIDTH + areaW / 2
    local y = Game.height

    love.graphics.setShader(glitchShader)
    Fx.r.imageScaled(
        "menu_portrait",
        x,
        y,
        0.3,
        0.3,
        0,
        iw / 2,
        ih
    )

    iw, ih = Fx.r.getImage("menu_fog"):getDimensions()
    Fx.r.imageScaled(
        "menu_fog",
        PANEL_WIDTH + (Game.width - PANEL_WIDTH)/2 + fogXShift,
        Game.height + fogYShift,
        0.4,
        0.4,
        0,
        iw / 2,
        ih,
        {255, 255, 255, 90}
    )

    love.graphics.setShader()

    -- logo
    local logow, logoh = Fx.r.getImage("logo"):getDimensions()
    Fx.r.imageScaled(
        "logo",
        PANEL_WIDTH + (Game.width - PANEL_WIDTH - logow*0.5) / 2,
        20 + logoY,
        0.5, 0.5
    )

    Fx.r.text(
        "--- V" .. Game.version .. " ---",
        PANEL_WIDTH,
        85 + logoY,
        1,
        {255,255,255},
        Game.width - PANEL_WIDTH,
        "center"
    )

    MP.drawFront()

    -- side panel
    Fx.r.rect(0, 0, PANEL_WIDTH, Game.height, {0,0,0,1})
    Fx.r.rect(PANEL_WIDTH - LINE_WIDTH, 0, LINE_WIDTH, Game.height, {1,1,1,1})

    -- menus
    stack:draw()
end

return Scene
