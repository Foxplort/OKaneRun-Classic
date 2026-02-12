local Scene = {}

local PANEL_WIDTH = 240
local LINE_WIDTH = 2

local underline = {}

local view = "main"
local pause = false
local selection = 1
local slideX, mainAlpha = 0, 1

local MP = nil

local menus = {
    main = {
        title = "MAIN MENU",
        options = {
            {txt = "Play",    action = function() view = "play"; selection = 1 end},
            {txt = "Credits", action = function() view = "credits"; selection = 2 end},
            {txt = "Exit",    action = function() view = "exit"; selection = 2 end},
        }
    },
    play = {
        title = "MODE",
        options = {
            {txt = "Arcade", action = function() pause = true; Fx.t.cover(function() setScene("game") end) end},
            {txt = "Coming Soon...", disabled = true},
            {txt = "---", isLabel = true},
            {txt = "Back", action = function() view = "main"; selection = 1 end},
        }
    },
    credits = {
        title = "CREDITS",
        options = {
            {txt = "--- CREW ---", isLabel = true},
            {txt = "Dev: Foxplort", link = "https://github.com/foxplort"},
            {txt = "Engine: LÖVE",  link = "https://love2d.org/"},
            {txt = "---", isLabel = true},
            {txt = "Back", action = function() view = "main"; selection = 2 end},
        }
    },
    exit = {
        title = "QUIT?",
        options = {
            {txt = "Confirm", action = function() love.event.quit() end},
            {txt = "Cancel",  action = function() view = "main"; selection = 3 end},
        }
    }
}

local function getNextValid(dir, current, list)
    local idx = current
    repeat
        idx = (idx + dir - 1) % #list + 1
    until (not list[idx].isLabel and not list[idx].disabled) or idx == current
    return idx
end

local function renderMenuContent(menuKey, x, alpha, isFocused)
    local menu = menus[menuKey]
    
    Fx.r.text(menu.title, x, 60, 2, {1, 1, 1, alpha})
    
    for i, opt in ipairs(menu.options) do
        local y = 120 + (i-1) * 30
        local color = {0.6, 0.6, 0.6, alpha}

        if isFocused and i == selection then
            color = {1, 1, 1, alpha}
        elseif opt.isLabel then
            color = {0.7, 0.7, 0.4, alpha}
        elseif opt.disabled then
            color = {0.2, 0.2, 0.2, alpha}
        end

        Fx.r.text(opt.txt, x, y, 1, color)

        -- underline
        local sel = underline[menuKey] and underline[menuKey][i] or 0
        if sel > 0.01 then
            local tw = Fx.r.getTextWidth(opt.txt, 1)
            local uw = tw * sel
            local ux = x + (tw - uw) / 2
            local uy = y + 14

            Fx.r.rect(ux, uy, uw, 1, {1, 1, 1, alpha * sel})
        end
    end
end

function Scene.enter()
    view, selection, slideX, mainAlpha, pause = "main", 1, 0, 1, false
    MP = nil
    Fx.r.loadImage("logo", "assets/images/ui/logo-outline.png")

    MP = require("src.systems.menuParticles")
    MP.init(PANEL_WIDTH)

    for viewKey, menu in pairs(menus) do
        underline[viewKey] = {}
        for i = 1, #menu.options do
            underline[viewKey][i] = 0
        end
    end

    GameState.player = require("src.data.player").new()
end

function Scene.exit()
    Fx.r.unloadImage("logo")
end

local function keypressed()
    if not pause then
        local m = menus[view]
        if Fx.i.pressed("up") then selection = getNextValid(-1, selection, m.options)
        elseif Fx.i.pressed("down") then selection = getNextValid(1, selection, m.options)
        elseif Fx.i.pressed("cancel") then
            if view ~= "main" then view = "main"; selection = 1 end
        elseif Fx.i.pressed("accept") then
            local o = m.options[selection]
            if o then
                if o.link then love.system.openURL(o.link) end
                if o.action then o.action() end
            end
        end
    end
end

function Scene.update(dt)
    keypressed()

    local m = menus[view]
    for i, opt in ipairs(m.options) do
        local target = (i == selection and not opt.isLabel and not opt.disabled) and 1 or 0
        underline[view][i] = Fx.m.lerp(underline[view][i], target, dt * 12)
    end

    local targetSlide = (view == "main") and 0 or 100
    local targetAlpha = (view == "main") and 1 or 0.2
    slideX = Fx.m.lerp(slideX, targetSlide, dt * 10)
    mainAlpha = Fx.m.lerp(mainAlpha, targetAlpha, dt * 10)
    MP.update(dt)
end

function Scene.draw()
    -- TITLE
    Fx.r.rect(PANEL_WIDTH, 0, Game.width - PANEL_WIDTH, Game.height, {8, 15, 20})

    MP.draw()

    local logow, logoh = Fx.r.getImage("logo"):getDimensions()
    Fx.r.imageScaled("logo", PANEL_WIDTH + (Game.width - PANEL_WIDTH - logow*2) / 2, 20, 2, 2)
    Fx.r.text("--- V" .. Game.version .. " ---", PANEL_WIDTH, 85, 1, {255, 255, 255}, Game.width - PANEL_WIDTH, "center")

    -- SIDE MENUS
    Fx.r.rect(0, 0, PANEL_WIDTH, Game.height, {0, 0, 0, 1})
    Fx.r.rect(PANEL_WIDTH - LINE_WIDTH, 0, LINE_WIDTH, Game.height, {1, 1, 1, 1})

    -- Main Menu Layer
    local mainX = 40 - (slideX * 0.5)
    if view ~= "main" then
        -- Static "Fake Blur" offset
        renderMenuContent("main", mainX + 1, mainAlpha * 0.3, false)
        renderMenuContent("main", mainX - 1, mainAlpha * 0.3, false)
    else
        renderMenuContent("main", mainX, 1, true)
    end

    -- Sub-Menu Layer
    if view ~= "main" or slideX > 1 then
        local subX = 40 + (100 - slideX)
        renderMenuContent(view == "main" and "play" or view, subX, (slideX / 100), view ~= "main")
    end
end

return Scene