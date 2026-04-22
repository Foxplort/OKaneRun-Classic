local GameEditor = {}

function GameEditor.init(fore)
    if not fore.editor then return end
    
    local Objects = require("okanerun.src.data.objects")
    
    for id, def in pairs(Objects) do
        local config = {
            shape = def.editor and def.editor.gizmo or "rectangle",
            color = def.editor and def.editor.color or {0.5, 0.5, 0.5, 1.0},
            defaultParams = {},
            -- Pass the render directly allowing editor rendering
            gameDraw = def.render
        }
        
        -- Pull out default parameters dynamically
        if def.fields then
            for _, f in ipairs(def.fields) do
                if f.default ~= nil then
                    config.defaultParams[f.name] = f.default
                end
            end
        end
        
        fore.editor.registerType(id, config)
    end

    fore.editor.registerGlobalToggle("showHitboxes", false)
    fore.editor.registerGlobalToggle("simpleView", false)
end

return GameEditor
