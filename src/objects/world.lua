local World = {}

World.testArea = {
    mapWidth = 1200,
    mapHeight = 800,
    walls = {
        {
            x = 200,
            y = 120,
            w = 30,
            h = 30,
            t = 30,
        },
        {
            x = 300,
            y = 170,
            w = 60,
            h = 20,
            t = 40,
        },
        {
            x = 600,
            y = 230,
            w = 40,
            h = 40,
            t = 120,
        },
        {
            x = 200,
            y = 450,
            w = 10,
            h = 10,
            t = 10,
        },
        {
            x = 800,
            y = 320,
            w = 20,
            h = 20,
            t = 20,
        },
    },
    ground = {
        { x = 50, y = 50, w = 1200-100, h = 800-100 }
    },
    coins = {
        {
            x = 200,
            y = 200,
        },
        {
            x = 220,
            y = 200,
        },
        {
            x = 240,
            y = 200,
        },
        {
            x = 260,
            y = 200,
        },
    },
    cores = {
        {
            x = 600,
            y = 400,
        },
    },
}

function World.renderWalls()
    for _, i in pairs(area.walls) do
        Fx.dq.submitDraw(-99, function()
            -- Draw shadow behind the wall
            local shadowOffsetX = i.t * 0.6
            local shadowOffsetY = i.t * 0.35

            -- Corners of the skewed shadow
            local x1, y1 = i.x, i.y - i.h
            local x2, y2 = i.x + i.w, i.y
            local x3, y3 = i.x + i.w + shadowOffsetX, i.y - i.t
            local x4, y4 = i.x + i.w + shadowOffsetX, i.y - i.h - i.t
            local x5, y5 = i.x + shadowOffsetX, i.y - i.h - i.t

            Fx.r.polygon(
                {x1, y1, x2, y2, x3, y3, x4, y4, x5, y5},
                {0, 0, 0, 90}
            )

            -- ambient occlusion
            Fx.r.rect(
                i.x,
                i.y - 2,
                i.w,
                4,
                {0, 0, 0, 90}
            )
        end)
        Fx.dq.submitDraw(i.y, function()
            -- wall
            Fx.r.rect(
                i.x,
                i.y - i.h - i.t,
                i.w,
                i.h + i.t,
                {0,100,200}
            )

            -- roof
            Fx.r.rect(
                i.x,
                i.y - i.h - i.t,
                i.w,
                i.h,
                {0,50,100}
            )

            -- Highlight
            Fx.r.rect(i.x, i.y - i.t, i.w, 1, {200, 240, 255, 60})
            -- Shadow
            Fx.r.rect(i.x + i.w - 1, i.y - i.t, 1, i.t, {0, 0, 0, 80}) -- Right Side
        end)
    end
end

function World.renderCoins()
    for _, c in ipairs(area.coins) do
        Fx.dq.submitDraw(c.y, function()
            Fx.r.circ(c.x, c.y-15, 15, 15, {255, 200, 0})
        end)
    end

    for _, c in ipairs(player.coinChain) do
        Fx.dq.submitDraw(c.y, function()
            Fx.r.circ(
                c.x + 2.5,
                c.y - c.z - 15,
                15, 15,
                {255, 200, 0}
            )
        end)
    end
end

function World.renderCores()
    for _, c in ipairs(area.cores) do
        Fx.dq.submitDraw(c.y, function()
            Fx.r.rect(c.x, c.y, 40, 40, {0, 190, 80})
        end)
    end
end

function World.renderGround()
    for _, g in ipairs(area.ground) do
        Fx.dq.submitDraw(-999, function()
            -- The Floor
            Fx.r.rect(g.x, g.y, g.w, g.h, {15, 20, 28})

            for gx = g.x, g.x + g.w, 40 do
                for gy = g.y, g.y + g.h, 40 do
                    -- Draw a tiny 1x1 dot or a subtle cross
                    Fx.r.rect(gx, gy, 1, 1, {150, 200, 255, 20})
                end
            end
        end)
        Fx.dq.submitDraw(-1000, function()
            -- The Floor
            Fx.r.rect(g.x, g.y+20, g.w, g.h+20, {15, 20, 28, 30})
            Fx.r.rect(g.x, g.y+15, g.w, g.h+15, {15, 20, 28, 30})
            Fx.r.rect(g.x, g.y+10, g.w, g.h+10, {15, 20, 28, 30})
            Fx.r.rect(g.x, g.y+5, g.w, g.h+5, {15, 20, 28, 30})
        end)
    end
end

return World
