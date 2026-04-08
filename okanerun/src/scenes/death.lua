local Scene = {}

local MenuSystem = require("okanerun.src.systems.menu")
local Menu = MenuSystem.Menu
local Stack = MenuSystem.Stack

local PANEL_WIDTH = 240
local LINE_WIDTH = 2

local stack
local MP
local timer = 0
local PB = fore.save.get("personal_best")

local damageText = {
    pit = {"LOST IN THE ABYSS"},
    scanline = {"ERASED"},
    trail = {"NO WAY BACK", "TRAPPED IN TRACE"},
    explosive_contact = {"STEPPED TOO FAR"},
    explosive_explosion = {"NO TRACE REMAINS", "OBLITERATED"}
}

local reason = "THE FATE IS UNKNOWN"

local function createMenus()
    local main = Menu:new{
        title = "THE END",
        style = "plain",
        options = {
            {
                txt = "Retry",
                action = function()
                    require(fore.scenes:get("menu")).enter()
                    fore.save.set("total_runs", fore.save.get("total_runs") + 1)
                    fore.save.write()
                    GameState.score = 0
                    fore.transition.start("spike", function()
                        fore.scenes:goTo("selection")
                    end, nil, 0, 0.6)
                end
            },
            {
                txt = "Main Menu",
                action = function()
                    fore.transition.start("spike", function()
                        fore.scenes:goTo("menu")
                    end, nil, 0, 0.6)
                end
            },
            {
                txt = "Exit",
                action = function()
                    love.event.quit()
                end
            }
        }
    }

    return main
end

function Scene.enter()
    MP = require("okanerun.src.systems.menuParticles")
    MP.init(0)

    local root = createMenus()
    stack = Stack.new(root)
    
    fore.audio.stopCategory("music")
    fore.audio.load("death_music", "okanerun/assets/sounds/music/001.ogg", false, "music")
    PB = fore.save.get("personal_best")

    reason = "THE FATE IS UNKNOWN"
    if GameState.player.lastDamageSource then
        reason = damageText[GameState.player.lastDamageSource][math.random(#damageText[GameState.player.lastDamageSource])]
    end
end

function Scene.onComplete()
    fore.audio.play("death_music", {volume = 0.8, loop = true, pitch = 0.6, fadeIn = 4.0})
end

function Scene.exit()
    fore.audio.fadeOutAndUnload("death_music", 2.0)
end

function Scene.update(dt)
    stack:update(dt)
    stack:input()
    MP.update(dt)
    timer = timer + dt
end

function Scene.draw()
    -- background
    fore.graphics.rect(PANEL_WIDTH, 0, fore.data.width - PANEL_WIDTH, fore.data.height, {20, 5, 5})
    MP.drawBack()

    fore.graphics.rect(0, 0, PANEL_WIDTH, fore.data.height, {35, 5, 5})

    MP.drawFront()

    -- side panel
    fore.graphics.rect(0, 0, PANEL_WIDTH, fore.data.height, {0,0,0,0.7})
    fore.graphics.rect(PANEL_WIDTH - LINE_WIDTH, 0, LINE_WIDTH, fore.data.height, {1,0,0,1})

    -- menus
    stack:draw()

    -- Large "GAME OVER" text on the right
    local x = PANEL_WIDTH + (fore.data.width - PANEL_WIDTH) / 2
    local y = fore.data.height / 2
    local alpha = math.min(1, timer * 2)
    
    fore.graphics.text(
        reason,
        PANEL_WIDTH,
        y - 20,
        2,
        {255, 50, 50, alpha * 255},
        fore.data.width - PANEL_WIDTH,
        "center"
    )
    
    fore.graphics.text(
        "score : " .. GameState.score,
        PANEL_WIDTH,
        y + 20,
        1,
        {255, 50, 50, alpha * 200},
        fore.data.width - PANEL_WIDTH,
        "center"
    )

    fore.graphics.text(
        "person best : " .. PB,
        PANEL_WIDTH,
        y + 40,
        1,
        {255, 50, 50, alpha * 200},
        fore.data.width - PANEL_WIDTH,
        "center"
    )
end

return Scene
