local Scene = {}

-- ################# --
-- ### VARIABLES ### --
-- ################# --

local state = "warning"
local timer = 0
local hold = 0
local HOLD_TIME = 0.8

local textLine = 1
local textAlpha = 255

local BAR_WIDTH = 160
local BAR_HEIGHT = 2
local BAR_Y = 230

local capH = BAR_HEIGHT + 4

-- ######################## --
-- ### HELPER FUNCTIONS ### --
-- ######################## --

local function lineText(text)
    c = {255, 255, 255, textAlpha}
    Fx.r.text(text, 0, 115 + 15 * (textLine-1), 1, c, Game.width, "center")
    textLine = textLine+1
end

-- ###################### --
-- ### MAIN FUNCTIONS ### --
-- ###################### --

function Scene.enter()
    Fx.s.loadSound("warning", "assets/sounds/ui/warning.wav", "ui")
    Fx.s.loadSound("intro", "assets/sounds/ui/intro.wav", "ui")
    Fx.s.playAndForget("warning")
end

function Scene.update(dt)
    if state == "warning" or state == "waiting" then
        if Fx.i:down("accept") and state == "warning" then
            hold = math.min(hold + dt, HOLD_TIME)
            if hold >= HOLD_TIME then
                state = "waiting"
            end
        else
            hold = math.max(hold - dt * 3, 0) -- decay
            if state == "waiting" and hold == 0 then
                state = "presents"
                Fx.s.playAndForget("intro")
                timer = 1.5
            end
        end
    elseif state == "presents" then
        timer = timer - dt
        if timer <= 0 then
            state = "done"
            -- DON'T switch scene directly
            Fx.t.cover(function()
                setScene("menu")
            end)
        end
    end
end

function Scene.draw()
    if state == "warning" or state == "waiting" then
        textAlpha = 255 - (hold / HOLD_TIME) * 255

        if state == "warning" then
            Fx.r.text("WARNING", 0, 80, 2, {255,0,0, textAlpha}, Game.width/2, "center")
            lineText("This is an early version of the game")
            lineText("Many assets are still a work in progress")
            lineText("Expect changes to gameplay and code as development progresses")
            lineText("-- Also --")
            lineText("Flashing lights and other effects may appear")
            lineText("")
            lineText("Hold SPACE to continue")
        end


        local cx = Game.width * 0.5
        local progress = hold / HOLD_TIME
        local fillW = BAR_WIDTH * progress
        local x = cx - BAR_WIDTH / 2
        local barY = BAR_Y + 5 - progress * 5
        local capY = barY - 2
        
        local a = (hold / HOLD_TIME) * 255
        if state == "warning" then
            Fx.r.rect(x, barY, fillW, BAR_HEIGHT)
        else
            Fx.r.rect(x, barY, BAR_WIDTH, BAR_HEIGHT, {255, 255, 255, a})
        end
        Fx.r.rect(x - 10, capY, 2, capH, {255,255,255,a})
        Fx.r.rect(x + BAR_WIDTH + 8, capY, 2, capH, {255,255,255,a})
    elseif state == "presents" or state == "done" then
        Fx.r.text("foxplort\npresents", 0, 155, 1, {255,255,255,255}, Game.width, "center")
    end

    textLine = 1
end

function Scene.debug()
    return { "State - " .. state }
end

return Scene
