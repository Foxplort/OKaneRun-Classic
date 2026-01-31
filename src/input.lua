local Input = {}

function Input.i(k)
    return love.keyboard.isDown(k)
end

return Input