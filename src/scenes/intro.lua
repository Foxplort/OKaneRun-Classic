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

function Scene.update(dt)
    if state == "warning" or state == "waiting" then
        if love.keyboard.isDown("space", "return") and state == "warning" then
            hold = math.min(hold + dt, HOLD_TIME)
            if hold >= HOLD_TIME then
                state = "waiting"
            end
        else
            hold = math.max(hold - dt * 3, 0) -- decay
            if state == "waiting" and hold == 0 then
                state = "presents"
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

        local a = (hold / HOLD_TIME) * 255
        if state == "warning" then
            local w = (hold / HOLD_TIME) * 160
            Fx.r.rect(240, 230, w, 2)
        else
            Fx.r.rect(240, 230, 160, 2, {255, 255, 255, a})
        end
        Fx.r.rect(230, 228, 2, 6, {255, 255, 255, a})
        Fx.r.rect(408, 228, 2, 6, {255, 255, 255, a})
    elseif state == "presents" or state == "done" then
        Fx.r.text("foxplort\npresents", 0, 155, 1, {255,255,255,255}, Game.width, "center")
    end

    textLine = 1
end

return Scene
