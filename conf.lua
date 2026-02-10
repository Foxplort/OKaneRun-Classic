function love.conf(t)
    Game = {
        version = "0.1.0-dev",
        width = 640,
        height = 360,
        baseWidth = 640,
        baseHeight = 360,
        pixelBank = 64,
    }
    t.window.title = "OkaneRun [" .. Game.version .. "]"
    -- ## Window Settings ##
    t.window.width = 640*2 -- base resolution (X)
    t.window.height = 360*2 -- base resolution (Y)
    t.window.minwidth = 640 -- Limits resolution (X)
    t.window.minheight = 360 -- Limits resolution (Y)
    t.window.resizable = true -- Allows resize
    t.window.msaa = 0 -- This keeps pixels sharp when scaling
end
