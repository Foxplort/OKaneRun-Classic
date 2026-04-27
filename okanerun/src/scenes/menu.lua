local Scene = {}

local MenuSystem = require("okanerun.src.systems.menu")
local Menu = MenuSystem.Menu
local Stack = MenuSystem.Stack

local PANEL_WIDTH = 240
local LINE_WIDTH = 2

local stack
local MP

local timer = 1
local fogXShift, fogYShift = 0, 0
local logoY = 0

local breathShader = love.graphics.newShader("okanerun/assets/shaders/menu_breathing.glsl")

local logScore = 0

local function createMenus()
    local main, credits, exit, settings

    local devOpt = {}
    devOpt.txt = "Dev Mode: " .. tostring(fore.save.get_engine("dev_mode") == true)
    devOpt.action = function()
        local current = fore.save.get_engine("dev_mode") == true
        fore.save.set_engine("dev_mode", not current)
        fore.save.write()
        devOpt.txt = "Dev Mode: " .. tostring(not current)
    end

    settings = Menu:new{
        title = "SETTINGS",
        options = {
            devOpt,
            { txt = "Back", pop = true }
        }
    }

    credits = Menu:new{
        title = "CREDITS",
        options = {
            { txt = "--- CREW ---", isLabel = true },
            {
                txt = "Foxplort",
                link = "https://www.foxplort.com",
                desc = [[
                Code, Art, Music, Sounds.[br]
                Hello! I hope you enjoy this little project
                and have a great day <3
                ]]
            },
            { txt = "--- TECH ---", isLabel = true },
            {
                txt = "FÖRE Engine",
                link = "https://github.com/Foxplort/OkaneRun-Classic",
                desc = [[
                Custom game engine for OkaneRun Classic.
                Available under MPL 2.0 license.[br]
                ]]
            },
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

    local mainOptions = {
        {
            txt = "Play",
            action = function()
                fore.save.set("total_runs", fore.save.get("total_runs") + 1)
                fore.save.write()
                GameState.score = 0
                fore.transition.start("spike", function()
                    fore.scenes:goTo("selection")
                end, nil, 0, 0.7)
            end,
        },
        { txt = "Credits", push = function() return credits end },
    }

    if not fore.data.phone then
        table.insert(mainOptions, { txt = "Settings", push = function() return settings end })
    end

    table.insert(mainOptions, { txt = "Exit", push = function() return exit end })

    main = Menu:new{
        title = "MAIN MENU",
        options = mainOptions
    }

    return main
end

function Scene.enter()
    fore.graphics.scheduleLoad("logo", "okanerun/assets/images/ui/OkaneRun_classic.png", "linear")
    fore.graphics.scheduleLoad("menu_portrait", "okanerun/assets/images/ui/menu_portrait.png", "linear")
    fore.graphics.scheduleLoad("menu_fog", "okanerun/assets/images/ui/menu_fog.png", "linear")

    fore.audio.load("menu_music", "okanerun/assets/sounds/music/001.ogg", false, "music")

    MP = require("okanerun.src.systems.menuParticles")
    MP.init(0)
    
    breathShader:send("b_intensity", 0.0028)
    breathShader:send("b_speed", 1.6)
    breathShader:send("b_ysize", 5)
    breathShader:send("s_speed", 0.5)
    breathShader:send("s_intensity", 0.004)

    local root = createMenus()
    stack = Stack.new(root)

    GameState.player = require("okanerun.src.data.player").new()

    logScore = fore.save.get("deaths")*3 + fore.save.get("coins_deposited") + fore.save.get("effects_obtained")
end

function Scene.onComplete()
    if not fore.audio.isPlaying("menu_music") then
        fore.audio.play("menu_music", {volume = 2.0, loop = true, fadeIn = 2.0})
    end
end

function Scene.exit()
    fore.graphics.scheduleUnload("logo")
    fore.graphics.scheduleUnload("menu_portrait")
    fore.graphics.scheduleUnload("menu_fog")
    if fore.scenes.next ~= "records" then
        fore.audio.fadeOutAndUnload("menu_music", 2.0)
    end
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
    fore.graphics.rect(PANEL_WIDTH, 0, fore.data.width - PANEL_WIDTH, fore.data.height, {8,15,20})
    MP.drawBack()

    local iw, ih = fore.graphics.getImage("menu_portrait"):getDimensions()

    local areaX = PANEL_WIDTH
    local areaW = fore.data.width - PANEL_WIDTH

    local x = PANEL_WIDTH + areaW / 2
    local y = fore.data.height

    love.graphics.setShader(breathShader)
    fore.graphics.imageScaled(
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

    iw, ih = fore.graphics.getImage("menu_fog"):getDimensions()
    fore.graphics.imageScaled(
        "menu_fog",
        PANEL_WIDTH + (fore.data.width - PANEL_WIDTH)/2 + fogXShift,
        fore.data.height + fogYShift,
        0.4,
        0.4,
        0,
        iw / 2,
        ih,
        {255, 255, 255, 90}
    )

    -- logo
    local logow, logoh = fore.graphics.getImage("logo"):getDimensions()
    fore.graphics.imageScaled(
        "logo",
        PANEL_WIDTH + (fore.data.width - PANEL_WIDTH - logow*0.35) / 2,
        20 + logoY,
        0.35, 0.35
    )

    fore.graphics.text(
        "--- v" .. fore.conf.version .. " ---",
        PANEL_WIDTH,
        85 + logoY,
        1,
        {255,255,255},
        fore.data.width - PANEL_WIDTH,
        "center"
    )

    fore.graphics.text(
        "High Score: " .. fore.save.get("personal_best"),
        PANEL_WIDTH + 10,
        fore.data.height - 35,
        1,
        {255,255,255},
        fore.data.width - PANEL_WIDTH,
        "left"
    )

    fore.graphics.text(
        "Overall Progress: " .. logScore,
        PANEL_WIDTH + 10,
        fore.data.height - 20,
        1,
        {255,255,255},
        fore.data.width - PANEL_WIDTH,
        "left"
    )

    fore.graphics.rect(0, 0, PANEL_WIDTH, fore.data.height, {5, 35, 35})

    MP.drawFront()

    -- side panel
    fore.graphics.rect(0, 0, PANEL_WIDTH, fore.data.height, {0,0,0,0.7})
    fore.graphics.rect(PANEL_WIDTH - LINE_WIDTH, 0, LINE_WIDTH, fore.data.height, {1,1,1,1})

    -- menus
    stack:draw()
end

return Scene
