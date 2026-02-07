local Collision = {}

function Collision.getPlayerHitbox()
    local hb = GameState.player.meta.player.hitbox
    return {
        x = GameState.player.x.pos + hb.xt,
        y = GameState.player.y.pos + hb.yt,
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
    return {
        x = g.x,
        y = g.y,
        w = g.w,
        h = g.h,
    }
end

return Collision