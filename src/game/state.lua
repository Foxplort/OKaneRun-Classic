local State = {}

State.player = nil
State.area = nil
State.particles = {}

State.camera = {
    x = 0,
    y = 0,
    shake = 0,
    uiShake = 0
}

function State.init(player, area)
    State.player = player
    State.area = area
end

return State
