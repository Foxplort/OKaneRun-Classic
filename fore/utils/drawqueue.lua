local DrawQueue = {}
local queue = {}

function DrawQueue.submit(layer, depth, fn)
    queue[#queue + 1] = {
        layer = layer,
        depth = depth,
        fn = fn
    }
end

function DrawQueue.draw()
    table.sort(queue, function(a, b)
        if a.layer ~= b.layer then
            return a.layer < b.layer
        end
        return a.depth < b.depth
    end)

    for _, item in ipairs(queue) do
        item.fn()
    end

    queue = {}
end

return DrawQueue
