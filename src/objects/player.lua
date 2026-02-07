local Player = {}

Player.baseData = {
    x = {
        pos = 80,
        vel = 0,
    },
    y = {
        pos = 80,
        vel = 0,
    },
    z = {
        pos = 0,
        vel = 0,
    },
    jump = {
        cons = 0,
    },
    hp = {
        count = 3,
        max = 3,
    },
    coins = 0,
    visual = {
        sx = 1,
        sy = 1,
    },
    dead = false,
    meta = {
        move = {
            accel = 600,
            maxVel = 120,
            fri = 400,
        },
        jump = {
            vel = 260,
            g = 900,
            lim = 2,
        },
        player = {
            w = 20,
            h = 20,
            hitbox = {
                w = 20,
                h = 6,
                xt = 0,
                yt = -6,
                t = 15,
            },
        },
    },
    coinChain = {},
    buffs = {},
}

local function playerRenderDepth()
    local depth = GameState.player.y.pos

    for _, w in ipairs(GameState.area.walls) do
        local wallMinY = w.y - w.h - w.t
        local wallMaxY = w.y

        local overlappingXY =
            GameState.player.x.pos + GameState.player.meta.player.w > w.x and
            GameState.player.x.pos < w.x + w.w and
            GameState.player.y.pos > wallMinY and
            GameState.player.y.pos < wallMaxY

        if overlappingXY then
            local wallTopZ = w.z + w.t

            if GameState.player.z.pos >= wallTopZ then
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
    Fx.dq.submit(L.SHADOW, GameState.player.y.pos, function()
        love.graphics.stencil(function()
            for _, g in ipairs(GameState.area.ground) do
                love.graphics.rectangle("fill", g.x, g.y, g.w, g.h)
            end
        end, "replace", 1)
        love.graphics.setStencilTest("equal", 1) -- "Only draw where ground IS"


        local z = GameState.player.z.pos
        local pm = GameState.player.meta.player

        -- base shadow size from player size
        local baseW = pm.w * 1.2
        local baseH = pm.h * 0.35

        -- shrink with jump
        local shadowZ = math.max(0, GameState.player.z.pos) -- Don't go below floor
        local shrink = math.max(0.45, 1 - shadowZ / 80)

        local w = baseW * shrink
        local h = baseH * shrink

        -- fade slightly with height
        local alpha = math.max(60, 160 - z * 1.5)

        -- center under feet
        local cx = GameState.player.x.pos + pm.w * 0.5
        local cy = GameState.player.y.pos - 2

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
        local pm = GameState.player.meta.player
        local vs = GameState.player.visual
        
        -- Calculate visual dimensions
        local vw = pm.w * vs.sx
        local vh = pm.h * vs.sy

        local sortY = GameState.player.y.pos
        if GameState.player.z.pos < -5 then 
            sortY = -998
        end
        
        if GameState.player.z.pos < 0 then
            love.graphics.stencil(function()
                for _, g in ipairs(GameState.area.ground) do
                    love.graphics.rectangle("fill", g.x, g.y, g.w, g.h-GameState.player.meta.player.h)
                end
            end, "replace", 1)
            -- "notequal 1" means: Only draw where the stencil (ground) is NOT
            love.graphics.setStencilTest("notequal", 1)
        end

        Fx.r.rect(
            GameState.player.x.pos + (pm.w - vw) / 2,
            GameState.player.y.pos - GameState.player.z.pos - vh,
            vw, vh,
            {200, 200, 200, 255-math.abs(math.min(0, GameState.player.z.pos*6))}
        )

        love.graphics.setStencilTest() -- Reset stencil
    end)
end

local function playerBehindWall()
    for _, w in ipairs(GameState.area.walls) do
        local wallMinY = w.y - w.h - w.t
        local wallMaxY = w.y

        local overlappingXY =
            GameState.player.x.pos + GameState.player.meta.player.w > w.x and
            GameState.player.x.pos < w.x + w.w and
            GameState.player.y.pos > wallMinY and
            GameState.player.y.pos < wallMaxY

        if overlappingXY then
            if GameState.player.z.pos < (w.z + w.t) then
                return true
            end
        end
    end
    for _, w in ipairs(GameState.area.cores) do
        local wallMinY = w.y - 40 - 40
        local wallMaxY = w.y

        local overlappingXY =
            GameState.player.x.pos + GameState.player.meta.player.w > w.x and
            GameState.player.x.pos < w.x + 40 and
            GameState.player.y.pos > wallMinY and
            GameState.player.y.pos < wallMaxY

        if overlappingXY then
            if GameState.player.z.pos < (40) then
                return true
            end
        end
    end
    return false
end


function Player.silhuette()
    if not playerBehindWall() then return end

    local pm = GameState.player.meta.player
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
        GameState.player.x.pos + (pm.w - vw) / 2,
        GameState.player.y.pos - GameState.player.z.pos - vh,
        vw,
        vh,
        {0, 0, 0, 110}
    )

    -- Reset stencil
    love.graphics.setStencilTest()
end

return Player
