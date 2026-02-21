local Input = {}

Input.actions = {
    accept = {
        keys = { "space", "return" },
        buttons = { "a" }
    },
    cancel = {
        keys = { "backspace", "escape" },
        buttons = { "b" }
    },
    debug = {
        keys = { "k", "f3" },
        buttons = { "back" }
    },
    debugEffect = {
        keys = { "b", "f4" },
        buttons = { "rightstick" }
    },
    debugRestart = {
        keys = { "f6" }
    },
    fullscreen = {
        keys = { "f11"}
    },
    jump = {
        keys = { "space", "up" },
        buttons = { "a" }
    },
    dash = {
        keys = { "lshift", "rshift" },
        buttons = { "b" }
    },
    attack = {
        keys = { "e", "z" },
        buttons = { "x" }
    },
    left = {
        keys = { "a", "left" },
        buttons = { "dpleft" },
        axes = { { axis = "leftx", dir = -1 } }
    },
    right = {
        keys = { "d", "right" },
        buttons = { "dpright" },
        axes = { { axis = "leftx", dir = 1 } }
    },
    up = {
        keys = { "w", "up" },
        buttons = { "dpup" },
        axes = { { axis = "lefty", dir = -1 } }
    },
    down = {
        keys = { "s", "down" },
        buttons = { "dpdown" },
        axes = { { axis = "lefty", dir = 1 } }
    },
}

Input.state = {}
Input.prev = {}

Input.joysticks = {} 

-- ############## --
-- ### UPDATE ### --
-- ############## --

function Input.update()
    Input.prev = Input.state
    Input.state = {}

    for action, bind in pairs(Input.actions) do
        local down = false

        -- keyboard
        if bind.keys then
            for _, k in ipairs(bind.keys) do
                if love.keyboard.isDown(k) then
                    down = true
                    break
                end
            end
        end

        -- gamepad buttons
        if not down and bind.buttons then
            for _, pad in ipairs(Input.joysticks) do
                for _, b in ipairs(bind.buttons) do
                    if pad:isGamepadDown(b) then
                        down = true
                        break
                    end
                end
                if down then break end
            end
        end

        -- axes (digitalized)
        if not down and bind.axes then
            for _, pad in ipairs(Input.joysticks) do
                for _, a in ipairs(bind.axes) do
                    local v = pad:getGamepadAxis(a.axis)
                    if a.dir < 0 and v < -0.4 then down = true end
                    if a.dir > 0 and v > 0.4 then down = true end
                end
                if down then break end
            end
        end

        Input.state[action] = down
    end
end

-- ############### --
-- ### QUERIES ### --
-- ############### --

function Input.down(action)
    return Input.state[action]
end

function Input.pressed(action)
    return Input.state[action] and not Input.prev[action]
end

function Input.released(action)
    return not Input.state[action] and Input.prev[action]
end

return Input
