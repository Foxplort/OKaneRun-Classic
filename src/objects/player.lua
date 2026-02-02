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
            },
        },
    },
    coinChain = {},
    buffs = {},
}

function Player.render()
    -- shadow
    Fx.dq.submitDraw(-99, function()
        love.graphics.stencil(function()
            for _, g in ipairs(area.ground) do
                love.graphics.rectangle("fill", g.x, g.y, g.w, g.h)
            end
        end, "replace", 1)
        love.graphics.setStencilTest("equal", 1) -- "Only draw where ground IS"


        local z = player.z.pos
        local pm = player.meta.player

        -- base shadow size from player size
        local baseW = pm.w * 1.2
        local baseH = pm.h * 0.35

        -- shrink with jump
        local shadowZ = math.max(0, player.z.pos) -- Don't go below floor
        local shrink = math.max(0.45, 1 - shadowZ / 80)

        local w = baseW * shrink
        local h = baseH * shrink

        -- fade slightly with height
        local alpha = math.max(60, 160 - z * 1.5)

        -- center under feet
        local cx = player.x.pos + pm.w * 0.5
        local cy = player.y.pos - 2

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
    Fx.dq.submitDraw(player.y.pos, function()
        local pm = player.meta.player
        local vs = player.visual
        
        -- Calculate visual dimensions
        local vw = pm.w * vs.sx
        local vh = pm.h * vs.sy

        local sortY = player.y.pos
        if player.z.pos < -5 then 
            sortY = -998
        end
        
        if player.z.pos < 0 then
            love.graphics.stencil(function()
                for _, g in ipairs(area.ground) do
                    love.graphics.rectangle("fill", g.x, g.y, g.w, g.h-player.meta.player.h)
                end
            end, "replace", 1)
            -- "notequal 1" means: Only draw where the stencil (ground) is NOT
            love.graphics.setStencilTest("notequal", 1)
        end

        Fx.r.rect(
            player.x.pos + (pm.w - vw) / 2,
            player.y.pos - player.z.pos - vh,
            vw, vh,
            {200, 200, 200, 255-math.abs(math.min(0, player.z.pos*6))}
        )

        love.graphics.setStencilTest() -- Reset stencil
    end)
end

local function playerBehindWall()
    for _, w in ipairs(area.walls) do
        if player.y.pos < w.y and
        player.y.pos > w.y - w.h - w.t and
        math.abs((player.x.pos + 10) - (w.x + w.w/2)) < w.w/2 + 12 then
            return true
        end
    end
    for _, w in ipairs(area.cores) do
        if player.y.pos < w.y and
        player.y.pos > w.y - 80 and
        math.abs((player.x.pos + 10) - (w.x + 20)) < 32 then
            return true
        end
    end
    return false
end

function Player.shiluette()
    if playerBehindWall() then
        local pm = player.meta.player
        local vs = player.visual
        local vw = pm.w * vs.sx
        local vh = pm.h * vs.sy

        -- 1) Write wall area to stencil
        love.graphics.stencil(function()
            for _, w in ipairs(area.walls) do
                love.graphics.rectangle(
                    "fill",
                    w.x,
                    w.y - w.h - w.t,
                    w.w,
                    w.h + w.t
                )
            end
            for _, w in ipairs(area.cores) do
                love.graphics.rectangle(
                    "fill",
                    w.x,
                    w.y - 80,
                    40,
                    80
                )
            end
        end, "replace", 1)

        -- 2) Only draw where walls exist
        love.graphics.setStencilTest("equal", 1)

        -- 3) Draw silhouette
        Fx.r.rect(
            player.x.pos + (pm.w - vw) / 2,
            player.y.pos - player.z.pos - vh,
            vw,
            vh,
            {0, 0, 0, 90}
        )

        -- 4) Reset
        love.graphics.setStencilTest()
    end
end

return Player
