local State = {}

function State.new()
    return {
        player = nil,
        area = nil,
        score = 0,
    }
end

return State
