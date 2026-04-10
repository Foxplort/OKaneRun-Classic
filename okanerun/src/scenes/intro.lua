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
local yChange = 0

-- ######################## --
-- ### HELPER FUNCTIONS ### --
-- ######################## --

local function lineText(text)
    c = {255, 255, 255, textAlpha}
    fore.graphics.text(text, 0, 125 + 15 * (textLine-1) - yChange, 1, c, fore.data.width, "center")
    textLine = textLine+1
end

-- ###################### --
-- ### MAIN FUNCTIONS ### --
-- ###################### --

function Scene.enter()
    fore.audio.load("warning", "okanerun/assets/sounds/ui/warning.wav", false, "sfx")
    fore.audio.load("intro", "okanerun/assets/sounds/ui/intro.wav", false, "sfx")

    if fore.data.phone then
        BAR_HEIGHT = 3
        capH = BAR_HEIGHT + 4
    end
end

function Scene.onComplete()
    fore.audio.playOnce("warning")
end

function Scene.update(dt)
    yChange = (fore.conf.height - fore.data.height)/2
    if state == "warning" or state == "waiting" then
        local isAccepting = fore.input:down("accept") or (fore.input:getMethod() == "touch" and fore.input:isTouching())
        
        if isAccepting and state == "warning" then
            hold = math.min(hold + dt, HOLD_TIME)
            if hold >= HOLD_TIME then
                state = "waiting"
            end
        else
            hold = math.max(hold - dt * 3, 0) -- decay
            if state == "waiting" and hold == 0 then
                state = "presents"
                fore.audio.playOnce("intro")
                timer = 1.5
            end
        end
    elseif state == "presents" then
        timer = timer - dt
        if timer <= 0 then
            state = "done"
            -- DON'T switch scene directly
            fore.transition.start("spike", function()
                fore.scenes:goTo("menu")
            end, nil, 0, 0.6)
        end
    end
end

function Scene.draw()
    if state == "warning" or state == "waiting" then
        textAlpha = 255 - (hold / HOLD_TIME) * 255

        if state == "warning" then
            fore.graphics.text("WARNING", 0, 90-yChange, 2, {255,0,0, textAlpha}, fore.data.width, "center")
            lineText("This is an early arcade prototype released as-is.")
            lineText("Systems are simple and not fully balanced.")
            lineText("-- Also --")
            lineText("Flashing lights and other effects may appear")
            lineText("")
            if fore.data.phone then
                lineText("Hold to continue")
            elseif fore.input:getMethod() == "keyboard" then
                lineText("Hold SPACE to continue")
            elseif fore.input:getMethod() == "gamepad" then
                lineText("Hold A to continue")
            end
        end


        local cx = fore.data.width * 0.5
        local progress = hold / HOLD_TIME
        local fillW = BAR_WIDTH * progress
        local x = cx - BAR_WIDTH / 2
        local barY = BAR_Y + 5 - progress * 5
        local capY = barY - 2
        
        local a = (hold / HOLD_TIME) * 255
        if state == "warning" then
            fore.graphics.rect(x, barY, fillW, BAR_HEIGHT)
        else
            fore.graphics.rect(x, barY, BAR_WIDTH, BAR_HEIGHT, {255, 255, 255, a})
        end
        fore.graphics.rect(x - 10, capY, 2, capH, {255,255,255,a})
        fore.graphics.rect(x + BAR_WIDTH + 8, capY, 2, capH, {255,255,255,a})
    elseif state == "presents" or state == "done" then
        fore.graphics.text("foxplort\npresents", 0, 155, 1, {255,255,255,255}, fore.data.width, "center")
    end

    textLine = 1
end

function Scene.debug()
    return { "State - " .. state }
end

return Scene
