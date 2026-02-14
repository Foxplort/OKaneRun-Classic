local World = {}

function World.renderCoins()
    -- Real coins
    for _, c in ipairs(GameState.area.coins) do
        -- Coin
        Fx.dq.submit(L.ACTOR, c.y, function()
            Fx.r.circ(c.x-1, c.y-15+1, 10, 15, {230, 140, 0}, true, 7) -- outline
            Fx.r.circ(c.x, c.y-15, 10, 15, {255, 200, 0}, true, 7) -- body
            Fx.r.circ(c.x+4, c.y-13, 2, 10, {230, 140, 0}, true, 4) -- middle
            Fx.r.circ(c.x+6, c.y-13, 4, 5, {255, 255, 160}, true, 5) -- highlight
            Fx.r.circ(c.x+7.5, c.y-12, 2, 3, {255, 255, 255}, true, 5) -- highlight
        end)

        -- Shadow
        Fx.dq.submit(L.SHADOW, c.y, function()
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
    for _, c in ipairs(GameState.player.coinChain) do
        -- Coin
        Fx.dq.submit(L.ACTOR, c.y, function()
            if c.z < -1 then
                love.graphics.stencil(function()
                    for _, g in ipairs(GameState.area.ground) do
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

            Fx.r.circ(c.x+4+2.5, c.y-c.z-13, 2, 10, {230, 140, 0, alpha}, true, 4)
            Fx.r.circ(c.x+6+2.5, c.y-c.z-13, 4, 5, {255, 255, 160, alpha}, true, 5)
            Fx.r.circ(c.x+7.5+2.5, c.y-c.z-12, 2, 3, {255, 255, 255, alpha}, true, 5)

            love.graphics.setStencilTest() -- Reset stencil
        end)

        -- Shadow
        Fx.dq.submit(L.SHADOW, c.y, function()
            if c.z > -1 then
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
    for _, i in ipairs(GameState.area.cores) do
        Fx.dq.submit(L.FLOOR, i.y, function()
            -- wall
            Fx.r.rect(
                i.x,
                i.y,
                i.w,
                i.h,
                {0, 190, 80}
            )
        end)
    end
end

function World.renderGround()
    for _, g in ipairs(GameState.area.ground) do
        Fx.dq.submit(L.FLOOR, g.y, function()
            -- The Floor
            Fx.r.rect(g.x, g.y, g.w, g.h, {15, 20, 28})

            for gx = g.x, g.x + g.w, 40 do
                for gy = g.y, g.y + g.h, 40 do
                    -- Draw a tiny 1x1 dot or a subtle cross
                    Fx.r.rect(gx, gy, 1, 1, {150, 200, 255, 20})
                end
            end
        end)
        Fx.dq.submit(L.FLOOR_DEC, g.y+g.w, function()
            -- The Floor
            Fx.r.rect(g.x, g.y+20, g.w, g.h+20, {15, 20, 28, 30})
            Fx.r.rect(g.x, g.y+15, g.w, g.h+15, {15, 20, 28, 30})
            Fx.r.rect(g.x, g.y+10, g.w, g.h+10, {15, 20, 28, 30})
            Fx.r.rect(g.x, g.y+5, g.w, g.h+5, {15, 20, 28, 30})
        end)
    end
end

return World
