local Player = {}

function Player.render()
    -- shadow
    Fx.dq.submit(L.SHADOW, GameState.player.pos.y, function()
        love.graphics.stencil(function()
            for _, g in ipairs(GameState.area.ground) do
                love.graphics.rectangle("fill", g.x, g.y, g.w, g.h)
            end
        end, "replace", 1)
        love.graphics.setStencilTest("equal", 1) -- "Only draw where ground IS"


        local z = GameState.player.pos.z
        local pm = GameState.player.stat.body

        -- base shadow size from player size
        local baseW = pm.w * 1.2
        local baseH = pm.h * 0.35

        -- shrink with jump
        local shadowZ = math.max(0, GameState.player.pos.z) -- Don't go below floor
        local shrink = math.max(0.45, 1 - shadowZ / 80)

        local w = baseW * shrink
        local h = baseH * shrink

        -- fade slightly with height
        local alpha = math.max(60, 160 - z * 1.5)

        -- center under feet
        local cx = GameState.player.pos.x + pm.w * 0.5
        local cy = GameState.player.pos.y - 2

        Fx.r.circ(
            cx - w * 0.5,
            cy - h * 0.5 + 2,
            w,
            h,
            {0, 0, 0, alpha},
            true, 16
        )

        love.graphics.setStencilTest()
    end)

    
    -- tail (Add later with the sprite!)
    -- Fx.dq.submit(
    --     L.ACTOR,
    --     playerRenderDepth()-0.01,
    --     function()
    --         -- 5 is the base thickness, adjust as needed
    --         Fx.r.tail(GameState.player.tail, {255, 255, 255, 255-math.abs(math.min(0, GameState.player.pos.z*6))}, 2) 
    --     end
    -- )


    -- player
    Fx.dq.submit(L.ACTOR, GameState.player.pos.y, function()
        local pm = GameState.player.stat.body
        local vs = GameState.player.visual
        
        -- Calculate visual dimensions
        local vw = pm.w * vs.sx
        local vh = pm.h * vs.sy

        local sortY = GameState.player.pos.y
        if GameState.player.pos.z < -5 then 
            sortY = -998
        end
        
        if GameState.player.pos.z < 0 then
            love.graphics.stencil(function()
                for _, g in ipairs(GameState.area.ground) do
                    love.graphics.rectangle("fill", g.x, g.y, g.w, g.h-GameState.player.stat.body.h)
                end
            end, "replace", 1)
            -- "notequal 1" means: Only draw where the stencil (ground) is NOT
            love.graphics.setStencilTest("notequal", 1)
        end

        Fx.r.rect(
            GameState.player.pos.x + (pm.w - vw) / 2,
            GameState.player.pos.y - GameState.player.pos.z - vh,
            vw, vh,
            {200, 200, 200, 255-math.abs(math.min(0, GameState.player.pos.z*6))}
        )

        love.graphics.setStencilTest() -- Reset stencil
    end)
end

return Player
