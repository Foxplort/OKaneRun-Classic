local Camera = {}

-- Core properties
local worldCam = {
    x = 0, y = 0,
    targetX = 0, targetY = 0,
    zoom = 1.0,
    targetZoom = 1.0,
    active = true
}

-- Categories
local categories = {
    world = {
        active = true,
        followWorld = true,
        zoom = 1.0,
        targetZoom = 1.0,
        shake = { amount = 0, x = 0, y = 0 },
        offsetX = 0, offsetY = 0,
        parallax = 1.0
    },
    ui = {
        active = true,
        followWorld = false,
        zoom = 1.0,
        targetZoom = 1.0,
        shake = { amount = 0, x = 0, y = 0 },
        offsetX = 0, offsetY = 0,
        parallax = 0
    }
}

-- Screen dimensions
local halfW = fore.conf.width / 2
local halfH = fore.conf.height / 2

-- Movement
local followSpeed = 8
local zoomSpeed = 8

-- Boundaries
local worldWidth, worldHeight
local boundMode = "soft"
local boundPadding = 0

-- Deadzone
local deadzone = { width = 20, height = 20, enabled = false }

-- Look-ahead
local lookAhead = {
    enabled = false,
    strength = 0.3,
    maxOffset = 100,
    velX = 0, velY = 0
}

-- Smoothing mode
local smoothMode = "exponential"

-- Helper
local function randf(a)
    return (love.math.random() * 2 - 1) * a
end

-- Create a new camera category
function Camera.createCategory(name, config)
    config = config or {}
    categories[name] = {
        active = config.active ~= nil and config.active or true,
        followWorld = config.followWorld ~= nil and config.followWorld or true,
        zoom = config.zoom or 1.0,
        targetZoom = config.zoom or 1.0,
        shake = { amount = 0, x = 0, y = 0 },
        offsetX = config.offsetX or 0,
        offsetY = config.offsetY or 0,
        parallax = config.parallax or 1.0
    }
    return name
end

-- Remove a category
function Camera.removeCategory(name)
    categories[name] = nil
end

-- Get category data
function Camera.getCategory(name)
    return categories[name]
end

function Camera.init(worldW, worldH)
    worldWidth, worldHeight = worldW, worldH
end

function Camera.setBounds(width, height, mode, padding)
    worldWidth, worldHeight = width, height
    boundMode = mode or boundMode
    boundPadding = padding or 0
end

function Camera.setDeadzone(width, height, enabled)
    deadzone.width = width or deadzone.width
    deadzone.height = height or deadzone.height
    deadzone.enabled = enabled ~= nil and enabled or true
end

function Camera.setLookAhead(strength, maxOffset, enabled)
    lookAhead.strength = strength or lookAhead.strength
    lookAhead.maxOffset = maxOffset or lookAhead.maxOffset
    lookAhead.enabled = enabled ~= nil and enabled or true
end

function Camera.setSmoothing(speed, mode)
    followSpeed = speed or followSpeed
    smoothMode = mode or smoothMode
end

-- World zoom controls
function Camera.setZoom(level, smooth)
    worldCam.targetZoom = math.max(0.1, math.min(3, level))
    if not smooth then
        worldCam.zoom = worldCam.targetZoom
    end
end

function Camera.zoomIn(amount, smooth)
    amount = amount or 0.1
    worldCam.targetZoom = math.min(3, worldCam.targetZoom + amount)
    if not smooth then
        worldCam.zoom = worldCam.targetZoom
    end
end

function Camera.zoomOut(amount, smooth)
    amount = amount or 0.1
    worldCam.targetZoom = math.max(0.1, worldCam.targetZoom - amount)
    if not smooth then
        worldCam.zoom = worldCam.targetZoom
    end
end

-- Category zoom controls
function Camera.setCategoryZoom(name, level, smooth)
    local cat = categories[name]
    if cat then
        cat.targetZoom = math.max(0.1, math.min(3, level))
        if not smooth then
            cat.zoom = cat.targetZoom
        end
    end
end

function Camera.setCategoryOffset(name, x, y)
    local cat = categories[name]
    if cat then
        cat.offsetX = x or cat.offsetX
        cat.offsetY = y or cat.offsetY
    end
end

function Camera.setCategoryParallax(name, factor)
    local cat = categories[name]
    if cat then
        cat.parallax = factor
    end
end

function Camera.update(targetX_, targetY_, dt, velX, velY)
    -- Recalculate half dimensions with world zoom
    halfW = fore.conf.width / 2 / worldCam.zoom
    halfH = fore.conf.height / 2 / worldCam.zoom
    
    worldCam.targetX, worldCam.targetY = targetX_, targetY_
    
    -- Look-ahead
    if lookAhead.enabled and velX and velY then
        lookAhead.velX = fore.math.lerp(lookAhead.velX, velX, dt * 5)
        lookAhead.velY = fore.math.lerp(lookAhead.velY, velY, dt * 5)
        
        local offsetX = fore.math.clamp(lookAhead.velX * lookAhead.strength, -lookAhead.maxOffset, lookAhead.maxOffset)
        local offsetY = fore.math.clamp(lookAhead.velY * lookAhead.strength, -lookAhead.maxOffset, lookAhead.maxOffset)
        
        worldCam.targetX = worldCam.targetX + offsetX
        worldCam.targetY = worldCam.targetY + offsetY
    end
    
    -- Update category shake
    for name, cat in pairs(categories) do
        if cat.active then
            cat.shake.amount = fore.math.approach(cat.shake.amount, 0, 40 * dt)
            cat.shake.x = randf(cat.shake.amount)
            cat.shake.y = randf(cat.shake.amount)
            
            -- Update category zoom
            cat.zoom = fore.math.lerp(cat.zoom, cat.targetZoom, 1 - math.exp(-zoomSpeed * dt))
        end
    end
    
    -- Smooth world camera follow
    if smoothMode == "exponential" then
        local follow = 1 - math.exp(-followSpeed * dt)
        worldCam.x = fore.math.lerp(worldCam.x, worldCam.targetX, follow)
        worldCam.y = fore.math.lerp(worldCam.y, worldCam.targetY, follow)
    else
        local distX = worldCam.targetX - worldCam.x
        local distY = worldCam.targetY - worldCam.y
        local maxMove = followSpeed * dt * 60
        worldCam.x = worldCam.x + fore.math.clamp(distX, -maxMove, maxMove)
        worldCam.y = worldCam.y + fore.math.clamp(distY, -maxMove, maxMove)
    end
    
    -- Deadzone
    if deadzone.enabled then
        local dx = worldCam.x - worldCam.targetX
        local dy = worldCam.y - worldCam.targetY
        
        if math.abs(dx) < deadzone.width then
            worldCam.x = worldCam.targetX
        end
        if math.abs(dy) < deadzone.height then
            worldCam.y = worldCam.targetY
        end
    end
    
    -- World boundaries
    if boundMode ~= "none" and worldWidth and worldHeight then
        local minX = halfW - boundPadding
        local maxX = worldWidth - halfW + boundPadding
        local minY = halfH - boundPadding
        local maxY = worldHeight - halfH + boundPadding
        
        if boundMode == "hard" then
            worldCam.x = fore.math.clamp(worldCam.x, minX, maxX)
            worldCam.y = fore.math.clamp(worldCam.y, minY, maxY)
        elseif boundMode == "soft" then
            if worldCam.x < minX then
                worldCam.x = fore.math.lerp(worldCam.x, minX, dt * 5)
            elseif worldCam.x > maxX then
                worldCam.x = fore.math.lerp(worldCam.x, maxX, dt * 5)
            end
            
            if worldCam.y < minY then
                worldCam.y = fore.math.lerp(worldCam.y, minY, dt * 5)
            elseif worldCam.y > maxY then
                worldCam.y = fore.math.lerp(worldCam.y, maxY, dt * 5)
            end
        end
    end
    
    -- Update world zoom
    worldCam.zoom = fore.math.lerp(worldCam.zoom, worldCam.targetZoom, 1 - math.exp(-zoomSpeed * dt))
end

function Camera.push(category)
    local cat = categories[category]
    if not cat or not cat.active then
        love.graphics.push()
        return
    end
    
    love.graphics.push()
    
    -- Apply world zoom
    if cat.followWorld then
        love.graphics.scale(worldCam.zoom, worldCam.zoom)
    end
    
    -- Apply category zoom
    love.graphics.scale(cat.zoom, cat.zoom)
    
    -- Apply shake
    love.graphics.translate(cat.shake.x, cat.shake.y)
    
    -- Apply category offset
    love.graphics.translate(cat.offsetX, cat.offsetY)
    
    -- Apply world camera movement with parallax
    if cat.followWorld then
        local moveX = -(worldCam.x - halfW) * cat.parallax
        local moveY = -(worldCam.y - halfH) * cat.parallax
        love.graphics.translate(moveX, moveY)
    end
end

function Camera.pop()
    love.graphics.pop()
end

function Camera.addShake(category, amount)
    local cat = categories[category]
    if cat then
        cat.shake.amount = cat.shake.amount + amount
    end
end

function Camera.resetShake(category)
    local cat = categories[category]
    if cat then
        cat.shake.amount = 0
    end
end

-- Coordinate conversion
function Camera.screenToWorld(screenX, screenY, category)
    local cat = categories[category or "world"]
    local effectiveZoom = worldCam.zoom * (cat and cat.zoom or 1)
    
    local worldX = (screenX / effectiveZoom) + worldCam.x - halfW
    local worldY = (screenY / effectiveZoom) + worldCam.y - halfH
    
    if cat and cat.parallax ~= 1 then
        worldX = worldX / cat.parallax
        worldY = worldY / cat.parallax
    end
    
    return worldX, worldY
end

function Camera.worldToScreen(worldX, worldY, category)
    local cat = categories[category or "world"]
    local effectiveZoom = worldCam.zoom * (cat and cat.zoom or 1)
    
    local screenX = (worldX - worldCam.x + halfW) * effectiveZoom
    local screenY = (worldY - worldCam.y + halfH) * effectiveZoom
    
    return screenX, screenY
end

function Camera.isVisible(x, y, margin, category)
    margin = margin or 0
    local cat = categories[category or "world"]
    local zoom = worldCam.zoom * (cat and cat.zoom or 1)
    
    local left = worldCam.x - halfW * zoom - margin
    local right = worldCam.x + halfW * zoom + margin
    local top = worldCam.y - halfH * zoom - margin
    local bottom = worldCam.y + halfH * zoom + margin
    
    return x >= left and x <= right and y >= top and y <= bottom
end

function Camera.getBounds(category)
    local cat = categories[category or "world"]
    local zoom = worldCam.zoom * (cat and cat.zoom or 1)
    
    return {
        left = worldCam.x - halfW * zoom,
        right = worldCam.x + halfW * zoom,
        top = worldCam.y - halfH * zoom,
        bottom = worldCam.y + halfH * zoom,
        width = halfW * 2 * zoom,
        height = halfH * 2 * zoom
    }
end

function Camera.getPosition()
    return worldCam.x, worldCam.y
end

function Camera.getWorldZoom()
    return worldCam.zoom
end

function Camera.setPosition(x, y, instant)
    if instant then
        worldCam.x, worldCam.y = x, y
    else
        worldCam.targetX, worldCam.targetY = x, y
    end
end

return Camera
