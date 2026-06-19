local Hooks = {}

function Hooks.register(fore)
    love.load = function() fore:load() end
    love.update = function(dt) fore:update(dt) end
    love.draw = function() fore:draw() end

    love.keypressed = function(key)
        fore.input:setMethod("keyboard")
        fore.debug.keypressed(key)
        if fore.editor.enabled then fore.editor.keypressed(key) end
        fore.scenes:keypressed(key)
    end

    love.mousepressed = function(x, y, button, istouch)
        if istouch then return end
        fore.input:setMethod("keyboard")
        if fore.editor.enabled then fore.editor.mousepressed(x, y, button, istouch) end
    end

    love.mousemoved = function(x, y, dx, dy, istouch)
        if istouch then return end
        if math.abs(dx) > 0.1 or math.abs(dy) > 0.1 then
            fore.input:setMethod("keyboard")
        end
        if fore.editor.enabled then fore.editor.mousemoved(x, y, dx, dy, istouch) end
    end

    love.mousereleased = function(x, y, button, istouch)
        if fore.editor.enabled then fore.editor.mousereleased(x, y, button, istouch) end
    end

    love.gamepadpressed = function(joystick, button)
        fore.input:setMethod("gamepad")
    end

    love.gamepadaxis = function(joystick, axis, value)
        if math.abs(value) > fore.input.deadzone then
            fore.input:setMethod("gamepad")
        end
    end
    
    love.joystickadded = function(j)
        fore.input:addJoystick(j)
    end

    love.joystickremoved = function(j)
        fore.input:removeJoystick(j)
    end

    love.touchpressed = function(id, x, y)
        -- Convert screen coordinates to canvas coordinates if necessary
        local pW, pH, vW, vH = fore:computeInternalResolution()
        local screenW, screenH = love.graphics.getDimensions()
        local offsetX = (screenW - pW) / 2
        local offsetY = (screenH - pH) / 2
        
        local tx = (x * screenW - offsetX) / fore.data.scale
        local ty = (y * screenH - offsetY) / fore.data.scale
        
        if fore.mobileControls and fore.mobileControls:isHit(tx, ty) then
            return
        end

        fore.input:touchpressed(id, tx, ty)
    end

    love.touchreleased = function(id, x, y)
        local pW, pH, vW, vH = fore:computeInternalResolution()
        local screenW, screenH = love.graphics.getDimensions()
        local offsetX = (screenW - pW) / 2
        local offsetY = (screenH - pH) / 2
        
        local tx = (x * screenW - offsetX) / fore.data.scale
        local ty = (y * screenH - offsetY) / fore.data.scale
        
        fore.input:touchreleased(id, tx, ty)
    end

    love.wheelmoved = function(x, y)
        if fore.editor.enabled then fore.editor.wheelmoved(x, y) end
    end

    love.resize = function(w,h)
        fore.text.updateFonts()
        fore.last_font_scale = fore.data.scale
    end

    love.textinput = function(t)
        if fore.editor.enabled and fore.editor.textinput then fore.editor.textinput(t) end
    end
end

return Hooks
