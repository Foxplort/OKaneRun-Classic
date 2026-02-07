local Player = {}

local function playerRenderDepth()
    local depth = GameState.player.pos.y

    for _, w in ipairs(GameState.area.walls) do
        local wallMinY = w.y - w.h - w.t
        local wallMaxY = w.y

        local overlappingXY =
            GameState.player.pos.x + GameState.player.base.body.w > w.x and
            GameState.player.pos.x < w.x + w.w and
            GameState.player.pos.y > wallMinY and
            GameState.player.pos.y < wallMaxY

        if overlappingXY then
            local wallTopZ = w.z + w.t

            if GameState.player.pos.z >= wallTopZ then
                -- Player stands on the wall - force in front
                depth = math.max(depth, w.y + 1)
            else
                -- Player is behind the wall - force behind
                depth = math.min(depth, w.y - 1)
            end
        end
    end

    return depth
end


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
        local pm = GameState.player.base.body

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
            {0, 0, 0, alpha}
        )

        love.graphics.setStencilTest()
    end)



    -- player
    Fx.dq.submit(L.ACTOR, playerRenderDepth(), function()
        local pm = GameState.player.base.body
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
                    love.graphics.rectangle("fill", g.x, g.y, g.w, g.h-GameState.player.base.body.h)
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

local function playerBehindWall()
    for _, w in ipairs(GameState.area.walls) do
        local wallMinY = w.y - w.h - w.t
        local wallMaxY = w.y

        local overlappingXY =
            GameState.player.pos.x + GameState.player.base.body.w > w.x and
            GameState.player.pos.x < w.x + w.w and
            GameState.player.pos.y > wallMinY and
            GameState.player.pos.y < wallMaxY

        if overlappingXY then
            if GameState.player.pos.z < (w.z + w.t) then
                return true
            end
        end
    end
    for _, w in ipairs(GameState.area.cores) do
        local wallMinY = w.y - 40 - 40
        local wallMaxY = w.y

        local overlappingXY =
            GameState.player.pos.x + GameState.player.base.body.w > w.x and
            GameState.player.pos.x < w.x + 40 and
            GameState.player.pos.y > wallMinY and
            GameState.player.pos.y < wallMaxY

        if overlappingXY then
            if GameState.player.pos.z < (40) then
                return true
            end
        end
    end
    return false
end


function Player.silhuette()
    if not playerBehindWall() then return end

    local pm = GameState.player.base.body
    local vs = GameState.player.visual
    local vw = pm.w * vs.sx
    local vh = pm.h * vs.sy

    -- Write wall shapes to stencil
    love.graphics.stencil(function()
        for _, w in ipairs(GameState.area.walls) do
            love.graphics.rectangle(
                "fill",
                w.x,
                w.y - w.h - w.t - w.z,
                w.w,
                w.h + w.t
            )
        end
        for _, c in ipairs(GameState.area.cores) do
            love.graphics.rectangle(
                "fill",
                c.x,
                c.y - 40 - 40,
                40,
                40 + 40
            )
        end
    end, "replace", 1)

    -- Draw ONLY where walls exist
    love.graphics.setStencilTest("equal", 1)

    -- Draw silhouette
    Fx.r.rect(
        GameState.player.pos.x + (pm.w - vw) / 2,
        GameState.player.pos.y - GameState.player.pos.z - vh,
        vw,
        vh,
        {0, 0, 0, 110}
    )

    -- Reset stencil
    love.graphics.setStencilTest()
end

return Player
