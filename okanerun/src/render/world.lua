local Objects = require("okanerun.src.data.objects")

local World = {}

function World.renderCoins()
    -- Real coins
    for _, c in ipairs(GameState.area.coins) do
        Objects["coin"].render(c, false)
    end

    -- Coins that follow the player
    for _, c in ipairs(GameState.player.coinChain) do
        -- Coin
        fore.queuer.submit(L.ACTOR, c.y, function()
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

            fore.graphics.circ(
                c.x + 2.5 - 1,
                c.y - c.z - 15 + 1,
                10, 15,
                {230, 140, 0, alpha},
                true, 7
            )

            fore.graphics.circ(
                c.x + 2.5,
                c.y - c.z - 15,
                10, 15,
                {255, 200, 0, alpha},
                true, 7
            )

            fore.graphics.circ(c.x+4+2.5, c.y-c.z-13, 2, 10, {230, 140, 0, alpha}, true, 4)
            fore.graphics.circ(c.x+6+2.5, c.y-c.z-13, 4, 5, {255, 255, 160, alpha}, true, 5)
            fore.graphics.circ(c.x+7.5+2.5, c.y-c.z-12, 2, 3, {255, 255, 255, alpha}, true, 5)

            love.graphics.setStencilTest() -- Reset stencil
        end)

        -- Shadow
        fore.queuer.submit(L.SHADOW, c.y, function()
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

                fore.graphics.circ(
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
        Objects["core"].render(i, false)
    end
end

function World.renderGround()
    for _, g in ipairs(GameState.area.ground) do
        Objects["ground"].render(g, false)
    end
end

return World
