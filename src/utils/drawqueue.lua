local DrawQueue = {}

local queue = {}

function DrawQueue.submitDraw(y, fn)
    queue[#queue + 1] = {
        y = y,
        fn = fn
    }
end

function DrawQueue.draw()
    table.sort(queue, function(a, b)
        return a.y < b.y
    end)

    for _, item in ipairs(queue) do
        item.fn()
    end

    queue = {}
end

return DrawQueue
