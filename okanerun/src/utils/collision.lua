local Collision = {}

function Collision.getPlayerHitbox()
    local hb = GameState.player.base.body.hitbox
    return {
        x = GameState.player.pos.x + hb.xt,
        y = GameState.player.pos.y + hb.yt,
        w = hb.w,
        h = hb.h,
    }
end

function Collision.getWallHitbox(w)
    return {
        x = w.x,
        y = w.y - w.h,
        w = w.w,
        h = w.h,
    }
end

function Collision.getGroundHitbox(g)
    local Objects = require("okanerun.src.data.objects")
    return Objects["ground"].hitbox(g)
end

return Collision