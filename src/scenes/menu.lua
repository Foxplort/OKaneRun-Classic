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

local breathShader = love.graphics.newShader("assets/shaders/menu_breathing.glsl")

local function createMenus()
    local main, credits, exit

    credits = Menu:new{
        title = "CREDITS",
        options = {
            { txt = "--- CREW ---", isLabel = true },
            {
                txt = "Foxplort",
                link = "https://github.com/foxplort",
                desc = [[
                Director, Code, Music, Sounds.[br]
                Hello! I hope you enjoy this little project
                and have a great day <3
                ]]
            },
            { txt = "--- TECH ---", isLabel = true },
            {
                txt = "LÖVE Framework",
                link = "https://love2d.org/",
                desc = [[
                Thanks to all LÖVE developers & contributors
                for this wonderful framework that makes
                game development so fun and accessible![br]
                ]]
            },
            { txt = "--- ---- ---", isLabel = true },
            { txt = "Back", pop = true }
        }
    }

    exit = Menu:new{
        title = "QUIT?",
        options = {
            { txt = "Confirm", action = function() love.event.quit() end },
            { txt = "Cancel", pop = true }
        }
    }

    main = Menu:new{
        title = "MAIN MENU",
        options = {
            {
                txt = "Play",
                action = function()
                    Fx.t.cover(function()
                        setScene("game")
                    end)
                end,
            },
            { txt = "Options", disabled = true },
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

    Fx.s.loadSound("menu_music", "assets/sounds/music/001.wav", "music")
    Fx.s.fadeIn("menu_music", 2.0, nil, {loop = true})

    MP = require("src.systems.menuParticles")
    MP.init(0)
    
    breathShader:send("b_intensity", 0.0028)
    breathShader:send("b_speed", 1.6)
    breathShader:send("b_ysize", 5)
    breathShader:send("s_speed", 0.5)
    breathShader:send("s_intensity", 0.004)

    local root = createMenus()
    stack = Stack.new(root)

    GameState.player = require("src.data.player").new()
end

function Scene.exit()
    Fx.r.unloadImage("logo")
    Fx.r.unloadImage("menu_portrait")
    Fx.r.unloadImage("menu_fog")
    Fx.s.fadeOutAndUnload("menu_music", 2.0)
end


function Scene.update(dt)
    stack:update(dt)
    stack:input()
    MP.update(dt)

    timer = timer + dt
    breathShader:send("time", timer)
    fogXShift = math.sin(timer / 3) * 20
    fogYShift = math.sin(timer) * 4 + 4
    logoY = math.sin(timer / 2) * 4
end

function Scene.draw()
    -- background
    Fx.r.rect(PANEL_WIDTH, 0, fore.conf.width - PANEL_WIDTH, fore.conf.height, {8,15,20})
    MP.drawBack()

    local iw, ih = Fx.r.getImage("menu_portrait"):getDimensions()

    local areaX = PANEL_WIDTH
    local areaW = fore.conf.width - PANEL_WIDTH

    local x = PANEL_WIDTH + areaW / 2
    local y = fore.conf.height

    love.graphics.setShader(breathShader)
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
    love.graphics.setShader()

    iw, ih = Fx.r.getImage("menu_fog"):getDimensions()
    Fx.r.imageScaled(
        "menu_fog",
        PANEL_WIDTH + (fore.conf.width - PANEL_WIDTH)/2 + fogXShift,
        fore.conf.height + fogYShift,
        0.4,
        0.4,
        0,
        iw / 2,
        ih,
        {255, 255, 255, 90}
    )

    -- logo
    local logow, logoh = Fx.r.getImage("logo"):getDimensions()
    Fx.r.imageScaled(
        "logo",
        PANEL_WIDTH + (fore.conf.width - PANEL_WIDTH - logow*0.5) / 2,
        20 + logoY,
        0.5, 0.5
    )

    Fx.r.text(
        "--- V" .. fore.conf.version .. " ---",
        PANEL_WIDTH,
        85 + logoY,
        1,
        {255,255,255},
        fore.conf.width - PANEL_WIDTH,
        "center"
    )

    Fx.r.rect(0, 0, PANEL_WIDTH, fore.conf.height, {5, 35, 35})

    MP.drawFront()

    -- side panel
    Fx.r.rect(0, 0, PANEL_WIDTH, fore.conf.height, {0,0,0,0.7})
    Fx.r.rect(PANEL_WIDTH - LINE_WIDTH, 0, LINE_WIDTH, fore.conf.height, {1,1,1,1})

    -- menus
    stack:draw()
end

return Scene
