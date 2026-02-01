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
            h = 15,
            t = 10,
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
        -- I don't want them to flood anything outside of this loop
        local px = player.x.pos + player.meta.player.w * 0.5
        local py = player.y.pos

        Fx.dq.submitDraw(i.y - 1, function()
            -- direction from player to wall
            local wx = i.x + i.w * 0.5
            local wy = i.y

            local dx = wx - px
            local dy = wy - py

            local len = math.sqrt(dx*dx + dy*dy)
            if len > 0 then
                dx = dx / len
                dy = dy / len
            end

            local jumpFactor = math.max(0.2, 1 - math.max(player.z.pos, 0) / 80)

            local shadowLen = 7 * jumpFactor
            local sx = dx * shadowLen
            local sy = math.min(0, dy * shadowLen)

            local skew = (i.x - px) * 0.02
            skew = math.max(-6, math.min(6, skew))

            local alpha = 80 * jumpFactor

            -- shadow
            Fx.r.rect(
                i.x + sx + skew,
                i.y - i.h - i.t + sy,
                i.w,
                i.h + i.t,
                {0, 0, 0, alpha}
            )

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

            -- Inner Highlight (Top Edge)
            Fx.r.rect(i.x, i.y - i.t - 2, i.w, 2, {0, 100, 200, 50}) 
            -- Inner Shadow (Right Edge)
            Fx.r.rect(i.x + i.w - 2, i.y - i.h - i.t, 2, i.h + i.t, {0, 25, 50, 50})
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
