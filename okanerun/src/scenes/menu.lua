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

local vsyncStatus = true and (love.window.getVSync() == 1 or love.window.getVSync() == -1) or false
mobileContrastStatus = fore.save.get("mobileContrast") -- I am too lazy to make it NOT a global variable
mobileUiStatus = fore.save.get("mobileUi") -- Same as the one above
local skipIntroStatus = fore.save.get("skipIntro")
local noiseStatus = fore.save.get("noise")
local vignetteStatus = fore.save.get("vignette")
local hintsStatus = fore.save.get("hints")

local function createMenus()
    local main, credits, exit, settings

    local devOpt = {}
    devOpt.txt = "Dev Mode"
    devOpt.type = "checkbox"
    devOpt.state = function() return fore.save.get_engine("dev_mode") == true end
    devOpt.action = function()
        local current = fore.save.get_engine("dev_mode") == true
        fore.save.set_engine("dev_mode", not current)
        fore.save.write()
    end

    devOpt.desc = [[
    [c=255,255,0,255]Default: false[/c][br]
    Allows to see object HitBoxes (F3),
    turn on Level Editor (F8),
    and effect debug menu (F4).[br]
    Does not affect score.[br]
    ]]

    local vsyncOpt = {}
    vsyncOpt.txt = "VSync"
    vsyncOpt.type = "checkbox"
    vsyncOpt.state = function() return vsyncStatus end
    vsyncOpt.action = function()
        vsyncStatus = not vsyncStatus
        love.window.setVSync(vsyncStatus)
        fore.save.set("vsync", vsyncStatus)
        fore.save.write()
    end

    vsyncOpt.desc = [[
    [c=255,255,0,255]Default: true[/c][br]
    Limits game's FPS to your monitor's refresh rate.[br]
    Turn it off to unlock higher FPS.
    Not recommended as it uses more power and GPU.[br]
    ]]

    local mobileContrast = {}
    mobileContrast.txt = "Mobile Contrast"
    mobileContrast.type = "checkbox"
    mobileContrast.state = function() return mobileContrastStatus end
    mobileContrast.action = function()
        mobileContrastStatus = not mobileContrastStatus
        fore.save.set("mobileContrast", mobileContrastStatus)
        fore.save.write()
    end

    mobileContrast.desc = [[
    [c=255,255,0,255]Default: false[/c][br]
    Increases the contrast of the game levels in a way, similar to how it looks on the Mobile version.
    ]]

    local mobileUi = {}
    mobileUi.txt = "Mobile UI"
    mobileUi.type = "checkbox"
    mobileUi.state = function() return mobileUiStatus end
    mobileUi.action = function()
        mobileUiStatus = not mobileUiStatus
        fore.save.set("mobileUi", mobileUiStatus)
        fore.save.write()
    end

    mobileUi.desc = [[
    [c=255,255,0,255]Default: false[/c][br]
    Changes the in-game UI in a way, similar to how it looks on the Mobile version.
    ]]

    local skipIntro = {}
    skipIntro.txt = "Skip Intro"
    skipIntro.type = "checkbox"
    skipIntro.state = function() return skipIntroStatus end
    skipIntro.action = function()
        skipIntroStatus = not skipIntroStatus
        fore.save.set("skipIntro", skipIntroStatus)
        fore.save.write()
    end

    skipIntro.desc = [[
    [c=255,255,0,255]Default: false[/c][br]
    Skips the intro screen on startup.[br]
    [c=255,255,255,7]Do you hate me that much? :(
    Or just the warning?
    ~foxplort[/c] 
    ]]

    local noise = {}
    noise.txt = "Noise"
    noise.type = "checkbox"
    noise.state = function() return noiseStatus end
    noise.action = function()
        noiseStatus = not noiseStatus
        fore.save.set("noise", noiseStatus)
        fore.save.write()
    end

    noise.desc = [[
    [c=255,255,0,255]Default: true[/c][br]
    Enables noise effect.[br]
    Used to make game look less flat.
    Disabling it may improve FPS and game recording quality.
    ]]

    local vignette = {}
    vignette.txt = "Vignette"
    vignette.type = "checkbox"
    vignette.state = function() return vignetteStatus end
    vignette.action = function()
        vignetteStatus = not vignetteStatus
        fore.save.set("vignette", vignetteStatus)
        fore.save.write()
    end

    vignette.desc = [[
    [c=255,255,0,255]Default: true[/c][br]
    Enables vignette effect.[br]
    Used to make game look less flat.
    ]]

    local hints = {}
    hints.txt = "Hints"
    hints.type = "checkbox"
    hints.state = function() return hintsStatus end
    hints.action = function()
        hintsStatus = not hintsStatus
        fore.save.set("hints", hintsStatus)
        fore.save.write()
    end

    hints.desc = [[
    [c=255,255,0,255]Default: true[/c][br]
    Enables hints in the game.[br]
    ]]

    local masterVol = {}
    masterVol.txt = "Master Vol"
    masterVol.type = "scroll"
    masterVol.getValue = function()
        return tostring(fore.save.get_engine("volume") or 100) .. "%"
    end
    masterVol.action = function(dir)
        local current = fore.save.get_engine("volume") or 100
        local newVol = math.max(0, math.min(300, current + (dir * 10)))
        fore.audio.setMasterVolume(newVol)
        fore.save.set_engine("volume", newVol)
        fore.save.write()
    end
    masterVol.desc = [[
    [c=255,255,0,255]Default: 100%[/c][br]
    Adjusts the overall game volume.
    ]]

    local fullscreenOpt = {}
    fullscreenOpt.txt = "Fullscreen"
    fullscreenOpt.type = "checkbox"
    fullscreenOpt.state = function() return fore.data.fullscreen end
    fullscreenOpt.action = function()
        fore.data.fullscreen = not fore.data.fullscreen
        love.window.setFullscreen(fore.data.fullscreen, "desktop")
        fore.graphics.updateFonts()
        fore.save.set("fullscreen", fore.data.fullscreen)
        fore.save.write()
    end

    fullscreenOpt.desc = [[
    [c=255,255,0,255]Default: false[/c][br]
    Enables fullscreen mode.
    Does the same thing as pressing F11.
    ]]

    local resolutions = {
        {960, 540},
        {1280, 720},
        {1366, 768},
        {1600, 900},
        {1920, 1080},
        {2560, 1440},
        {3840, 2160}
    }
    
    local function getResIndex()
        local w, h = love.graphics.getDimensions()
        for i, res in ipairs(resolutions) do
            if res[1] == w and res[2] == h then
                return i
            end
        end
        return 2 -- Default to 1280x720
    end
    
    local resolutionOpt = {}
    resolutionOpt.txt = "Resolution"
    resolutionOpt.type = "scroll"
    resolutionOpt.getValue = function()
        if fore.data.fullscreen then return "Desktop" end
        local idx = getResIndex()
        return resolutions[idx][1] .. "x" .. resolutions[idx][2]
    end
    resolutionOpt.action = function(dir)
        if fore.data.fullscreen then return end
        local idx = getResIndex()
        idx = idx + dir
        if idx < 1 then idx = #resolutions end
        if idx > #resolutions then idx = 1 end
        local w, h = resolutions[idx][1], resolutions[idx][2]
        love.window.updateMode(w, h)
        fore.graphics.updateFonts()
    end
    resolutionOpt.desc = [[
    [c=255,255,0,255]Default: 1280x720[/c][br]
    Changes the resolution of the game.[br]
    [c=255,0,0,255]Warning: [/c]Can misbehave, preferably just stretch the game window.
    ]]

    local settingsOptions = {
        { txt = "- GAME -", isLabel = true },
        masterVol,
        hints,
        skipIntro,
    }

    if fore.data.phone then
        table.insert(settingsOptions, vsyncOpt)
    else
        table.insert(settingsOptions, { txt = "- VIDEO -", isLabel = true })
        table.insert(settingsOptions, fullscreenOpt)
        table.insert(settingsOptions, resolutionOpt)
        table.insert(settingsOptions, vsyncOpt)
        table.insert(settingsOptions, noise)
        table.insert(settingsOptions, vignette)
        table.insert(settingsOptions, { txt = "- MISC -", isLabel = true })
        table.insert(settingsOptions, mobileContrast)
        table.insert(settingsOptions, mobileUi)
        table.insert(settingsOptions, { txt = "- ADVANCED -", isLabel = true })
        table.insert(settingsOptions, devOpt)
    end
    
    table.insert(settingsOptions, { txt = "---", isLabel = true })
    table.insert(settingsOptions, { txt = "Back", pop = true })

    settings = Menu:new{
        title = "SETTINGS",
        options = settingsOptions
    }

    credits = Menu:new{
        title = "CREDITS",
        options = {
            { txt = "--- CREW ---", isLabel = true },
            {
                txt = "Foxplort",
                icon = "icon_foxplort",
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
                icon = "icon_fore",
                link = "https://github.com/Foxplort/OKaneRun-Classic",
                desc = [[
                Custom game engine for OKaneRun Classic.
                Available under MPL 2.0 license.[br]
                ]]
            },
            {
                txt = "LÖVE Framework",
                icon = "icon_love",
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
            { txt = "Confirm", action = function() love.event.quit() end, icon = "icon_exit" },
            { txt = "Cancel", pop = true, icon = "icon_back" }
        }
    }

    local mainOptions = {
        {
            txt = "Play",
            icon = "icon_play",
            action = function()
                fore.save.set("total_runs", fore.save.get("total_runs") + 1)
                fore.save.write()
                GameState.score = 0
                fore.transition.start("spike", function()
                    fore.scenes:goTo("selection")
                end, nil, 0, 0.7)
            end,
            desc = string.format([[
            [c=255,255,255,255]Total Runs: %d
            Personal Best: %d
            Overall Progress: %d[/c]
            ]], fore.save.get("total_runs"), fore.save.get("personal_best"), logScore)
        },
        { txt = "Settings", icon = "icon_settings", push = function() return settings end },
        { txt = "Credits", icon = "icon_credits", push = function() return credits end },
        { txt = "Exit", icon = "icon_exit", push = function() return exit end }
    }

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
    fore.graphics.scheduleLoad("checkbox_true", "okanerun/assets/images/ui/checkbox_true.png", "linear")
    fore.graphics.scheduleLoad("checkbox_false", "okanerun/assets/images/ui/checkbox_false.png", "linear")
    fore.graphics.scheduleLoad("icon_play", "okanerun/assets/images/ui/menu/play.png", "linear")
    fore.graphics.scheduleLoad("icon_settings", "okanerun/assets/images/ui/menu/settings.png", "linear")
    fore.graphics.scheduleLoad("icon_credits", "okanerun/assets/images/ui/menu/credits.png", "linear")
    fore.graphics.scheduleLoad("icon_exit", "okanerun/assets/images/ui/menu/exit.png", "linear")
    fore.graphics.scheduleLoad("icon_foxplort", "okanerun/assets/images/ui/menu/foxplort.png", "linear")
    fore.graphics.scheduleLoad("icon_love", "okanerun/assets/images/ui/menu/love.png", "linear")
    fore.graphics.scheduleLoad("icon_fore", "okanerun/assets/images/ui/menu/fore.png", "linear")
    fore.graphics.scheduleLoad("icon_back", "okanerun/assets/images/ui/menu/back.png", "linear")


    fore.audio.load("menu_music", "okanerun/assets/sounds/music/001.ogg", false, "music")

    MP = require("okanerun.src.systems.menuParticles")
    MP.init(0)
    
    breathShader:send("b_intensity", 0.0028)
    breathShader:send("b_speed", 1.6)
    breathShader:send("b_ysize", 5)
    breathShader:send("s_speed", 0.5)
    breathShader:send("s_intensity", 0.004)

    logScore = fore.save.get("deaths")*3 + fore.save.get("coins_deposited") + fore.save.get("effects_obtained")

    local root = createMenus()
    stack = Stack.new(root)

    GameState.player = require("okanerun.src.data.player").new()
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
    fore.graphics.scheduleUnload("checkbox_true")
    fore.graphics.scheduleUnload("checkbox_false")
    fore.graphics.scheduleUnload("icon_play")
    fore.graphics.scheduleUnload("icon_settings")
    fore.graphics.scheduleUnload("icon_credits")
    fore.graphics.scheduleUnload("icon_exit")
    fore.graphics.scheduleUnload("icon_foxplort")
    fore.graphics.scheduleUnload("icon_love")
    fore.graphics.scheduleUnload("icon_fore")
    fore.graphics.scheduleUnload("icon_back")
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

    fore.graphics.rect(0, 0, PANEL_WIDTH, fore.data.height, {5, 35, 35})

    MP.drawFront()

    -- side panel
    fore.graphics.rect(0, 0, PANEL_WIDTH, fore.data.height, {0,0,0,0.7})
    fore.graphics.rect(PANEL_WIDTH - LINE_WIDTH, 0, LINE_WIDTH, fore.data.height, {1,1,1,1})

    -- menus
    stack:draw()
end

return Scene
