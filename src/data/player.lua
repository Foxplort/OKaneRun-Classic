local Player = {
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

    visual = {
        sx = 1,
        sy = 1,
    },

    coinChain = {},
    effects = {},

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

return Player
