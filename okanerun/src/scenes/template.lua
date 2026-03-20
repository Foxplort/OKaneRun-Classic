local Scene = {}

-- Whatever should happen when the scene gets loaded.
function Scene.enter()
end

-- Whatever should happen when the scene AS WELL AS assets gets loaded.
function Scene.onComplete()
end

-- Whatever should happen when the scene gets deloaded.
function Scene.exit()
end

-- Action on key just pressed. !!deprecated!!
function Scene.keypressed(k)
end

-- Every logic update.
function Scene.update(dt)
end

-- Every frame update.
function Scene.draw()
end

-- Provide more info into the Scene category of debug. Must return table of strings.
function Scene.debug()
end

return Scene
