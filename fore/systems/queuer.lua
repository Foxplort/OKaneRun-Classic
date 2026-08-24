local DrawQueue = {}

local entries = {}
local count = 0
local pos = {} -- sorted position indices

function DrawQueue.submit(layer, depth, fn, data)
    count = count + 1
    local e = entries[count]
    if not e then
        e = { layer = 0, depth = 0, fn = nil, data = nil }
        entries[count] = e
    end
    e.layer = layer
    e.depth = depth
    e.fn = fn
    e.data = data
end

function DrawQueue.draw()
    -- Build position array for the active slice only
    for i = 1, count do
        pos[i] = i
    end

    -- Insertion sort on positions (fast for small N, no allocation)
    for i = 2, count do
        local pi = pos[i]
        local ei = entries[pi]
        local j = i - 1
        while j >= 1 do
            local pj = pos[j]
            local ej = entries[pj]
            local swap = false
            if ei.layer ~= ej.layer then
                swap = ei.layer < ej.layer
            else
                swap = ei.depth < ej.depth
            end
            if swap then
                pos[j + 1] = pj
                j = j - 1
            else
                break
            end
        end
        pos[j + 1] = pi
    end

    -- Execute in sorted order
    for i = 1, count do
        local e = entries[pos[i]]
        if e.data then
            e.fn(e.data)
        else
            e.fn()
        end
    end

    count = 0
end

return DrawQueue
