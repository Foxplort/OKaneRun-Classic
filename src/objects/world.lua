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
        { x = 50, y = 50, w = 1200-100, h = 800-100 },
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
            local x3, y3 = i.x + i.w + shadowOffsetX, i.y - i.t + shadowOffsetY
            local x4, y4 = i.x + i.w + shadowOffsetX, i.y - i.h - i.t + shadowOffsetY
            local x5, y5 = i.x + shadowOffsetX, i.y - i.h - i.t + shadowOffsetY

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
    -- Real coins
    for _, c in ipairs(area.coins) do
        -- Coin
        Fx.dq.submitDraw(c.y, function()
            Fx.r.circ(c.x-1, c.y-15+1, 10, 15, {230, 140, 0}, true, 7) -- outline
            Fx.r.circ(c.x, c.y-15, 10, 15, {255, 200, 0}, true, 7) -- body
            Fx.r.circ(c.x+3, c.y-15, 3, 15, {230, 140, 0}, true, 3) -- middle
            Fx.r.circ(c.x+6, c.y-13, 5, 5, {255, 255, 160}, true, 5) -- highlight
        end)

        -- Shadow
        Fx.dq.submitDraw(-99, function()
            local z = 5
            local cw, ch = 10, 7

            -- base shadow size from [coin] size
            local baseW = cw * 1.2
            local baseH = ch * 0.35

            -- shrink with jump
            local shadowZ = math.max(0, z) -- Don't go below floor
            local shrink = math.max(0.45, 1 - shadowZ / 80)

            local w = baseW * shrink
            local h = baseH * shrink

            -- fade slightly with height
            local alpha = math.max(60, 160 - z * 1.5)

            -- center under feet
            local cx = c.x + cw * 0.5
            local cy = c.y - 2

            Fx.r.circ(
                cx - w * 0.5,
                cy - h * 0.5 + 2,
                w,
                h,
                {0, 0, 0, alpha}
            )
        end)
    end

    -- Coins that follow the player
    for _, c in ipairs(player.coinChain) do
        -- Coin
        Fx.dq.submitDraw(c.y, function()
            if c.z < -1 then
                love.graphics.stencil(function()
                    for _, g in ipairs(area.ground) do
                        love.graphics.rectangle("fill", g.x, g.y, g.w, g.h-15)
                    end
                end, "replace", 1)
                -- "notequal 1" means: Only draw where the stencil (ground) is NOT
                love.graphics.setStencilTest("notequal", 1)
            end

            local alpha = 255-math.abs(math.min(0, c.z*6))

            Fx.r.circ(
                c.x + 2.5 - 1,
                c.y - c.z - 15 + 1,
                10, 15,
                {230, 140, 0, alpha},
                true, 7
            )

            Fx.r.circ(
                c.x + 2.5,
                c.y - c.z - 15,
                10, 15,
                {255, 200, 0, alpha},
                true, 7
            )

            Fx.r.circ(c.x+3+2.5, c.y-c.z-15, 3, 15, {230, 140, 0, alpha}, true, 3)
            Fx.r.circ(c.x+6+2.5, c.y-c.z-13, 5, 5, {255, 255, 160, alpha}, true, 5)

            love.graphics.setStencilTest() -- Reset stencil
        end)

        -- Shadow
        Fx.dq.submitDraw(-99, function()
            if c.z < -1 then
                local z = c.z
                local cw, ch = 10, 7

                -- base shadow size from [coin] size
                local baseW = cw * 1.2
                local baseH = ch * 0.35

                -- shrink with jump
                local shadowZ = math.max(0, z) -- Don't go below floor
                local shrink = math.max(0.45, 1 - shadowZ / 80)

                local w = baseW * shrink
                local h = baseH * shrink

                -- fade slightly with height
                local alpha = math.max(60, 160 - z * 1.5)

                -- center under feet
                local cx = c.x + cw * 0.5
                local cy = c.y - 2

                Fx.r.circ(
                    cx - w * 0.5 + 2.5,
                    cy - h * 0.5 + 2,
                    w,
                    h,
                    {0, 0, 0, alpha}
                )
            end
        end)
    end
end

function World.renderCores()
    for _, i in ipairs(area.cores) do
        local h, w, t = 40, 40, 40

        Fx.dq.submitDraw(-99, function()
            -- Draw shadow behind the wall
            local shadowOffsetX = t * 0.6
            local shadowOffsetY = t * 0.35

            -- Corners of the skewed shadow
            local x1, y1 = i.x, i.y - h
            local x2, y2 = i.x + w, i.y
            local x3, y3 = i.x + w + shadowOffsetX, i.y - t + shadowOffsetY
            local x4, y4 = i.x + w + shadowOffsetX, i.y - h - t + shadowOffsetY
            local x5, y5 = i.x + shadowOffsetX, i.y - h - t + shadowOffsetY

            Fx.r.polygon(
                {x1, y1, x2, y2, x3, y3, x4, y4, x5, y5},
                {0, 0, 0, 90}
            )

            -- ambient occlusion
            Fx.r.rect(
                i.x,
                i.y - 2,
                w,
                4,
                {0, 0, 0, 90}
            )
        end)
        Fx.dq.submitDraw(i.y, function()
            -- wall
            Fx.r.rect(
                i.x,
                i.y - h - t,
                w,
                h + t,
                {0, 190, 80}
            )

            -- roof
            Fx.r.rect(
                i.x,
                i.y - h - t,
                w,
                h,
                {0, 90, 60}
            )

            -- Highlight
            Fx.r.rect(i.x, i.y - t, w, 1, {200, 255, 240, 60})
            -- Shadow
            Fx.r.rect(i.x + w - 1, i.y - t, 1, t, {0, 0, 0, 80}) -- Right Side
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
