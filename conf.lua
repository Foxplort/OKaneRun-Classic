function love.conf(t)
    GameVersion = "Prototype Git"
    t.window.title = "OkaneRun [" .. GameVersion .. "]"
    -- ## Window Settings ##
    t.window.width = 640*2 -- base resolution (X)
    t.window.height = 360*2 -- base resolution (Y)
    t.window.minwidth = 640 -- Limits resolution (X)
    t.window.minheight = 360 -- Limits resolution (Y)
    t.window.resizable = true -- Allows resize
    t.window.msaa = 0 -- This keeps pixels sharp when scaling

    -- ## Modules ##
    t.modules.joystick = false -- Disable what you don't need
end
