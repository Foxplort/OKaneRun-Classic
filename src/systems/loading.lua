local Loading = {}

-- VARIABLES
local active = false
local timer = 0
local switchTime = 0.05  -- How long to display each loading image
local rotation = 0       -- Current rotation for the sprite
local currentImage = 1   -- Which image to display (1 = loading1, 2 = loading2, etc.)

-- Initialize the loading animation
function Loading.start()
    active = true
    timer = 0
    rotation = 0
    currentImage = 1
end

-- Update the loading animation
function Loading.update(dt)
    if not active then return end

    -- Update the timer to control image switching
    timer = timer + dt

    -- Switch between the loading images
    if timer >= switchTime then
        timer = 0
        currentImage = currentImage + 1
        if currentImage > 4 then
            currentImage = 1
            rotation = rotation + math.pi / 2  -- Rotate by 90 degrees (in radians)
        end
    end
end

-- Draw the loading icon
function Loading.draw()
    if not active then return end

    local iw, ih = Fx.r.getImage("loading1"):getDimensions()  -- Get dimensions of the first frame
    local x, y = Game.width - iw - 10, Game.height - ih - 10  -- Position in the bottom-right corner

    -- Draw the current loading frame with rotation
    Fx.r.imageScaled( "loading"..currentImage, x, y, 1, 1, rotation, iw / 2, ih / 2)
end

-- Stop the loading animation
function Loading.stop()
    active = false
end

return Loading
