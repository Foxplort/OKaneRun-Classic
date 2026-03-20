local Player = {}

local function makeTail(playerData, count, spacing)
    local tail = {}
    for i = 1, count do
        -- Make segments closer together near the tip for smoother curves
        local segmentSpacing = spacing
        if i > count * 0.7 then segmentSpacing = spacing * 0.6 end
        
        tail[i] = {
            x = playerData.pos.x,
            y = playerData.pos.y,
            px = playerData.pos.x,
            py = playerData.pos.y,
            spacing = segmentSpacing
        }
    end
    return tail
end

function Player.new()
    local playerData = {
        -- RUNTIME STATE (never buffed)
        pos = { x = 80, y = 80, z = 0 },
        vel = { x = 0, y = 0, z = 0 },

        jump = {
            cons = 0,
        },

        hp = {
            count = 3,
            max = 3,
        },

        coins = 0,
        dead = false,
        coreProgress = 0,

        visual = {
            sx = 1,
            sy = 1,
        },
        afterimages = {},

        coinChain = {},
        effects = {},
        camZoom = 0.9,
        effectRef = {},

        dash = {
            cooldown = 0,
            cdMax = 1.75,
            power = 400,
            time = 0.75,
            timer = 0,
            dir = {x=0,y=0}
        },

        -- BASE STATS (immutable)
        base = {
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
            body = {
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

        -- MODIFIERS (effects touch ONLY this)
        mod = {
            move = {
                accel = { add = 0, mul = 1 },
                maxVel = { add = 0, mul = 1 },
                fri = { add = 0, mul = 1 },
            },
            jump = {
                vel = { add = 0, mul = 1 },
                g = { add = 0, mul = 1 },
                lim = { add = 0, mul = 1 },
            },
        },

        -- DERIVED (computed every frame)
        stat = {}
    }

    playerData.tail = makeTail(playerData, 12, 3)

    return playerData
end

return Player
