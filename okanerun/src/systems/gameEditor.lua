local GameEditor = {}

function GameEditor.init(fore)
    if not fore.editor then return end
    
    fore.editor.registerType("spawn", {
        shape = "point",
        color = {0.2, 1.0, 0.2, 1.0},
        defaultParams = {}
    })
    
    fore.editor.registerType("coins", {
        shape = "point",
        color = {1.0, 0.8, 0.1, 1.0},
        defaultParams = {}
    })
    
    fore.editor.registerType("cores", {
        shape = "rectangle",
        color = {1.0, 0.2, 0.2, 0.6},
        defaultParams = {}
    })
    
    fore.editor.registerType("ground", {
        shape = "rectangle",
        color = {0.5, 0.5, 0.5, 1.0},
        defaultParams = {}
    })

    fore.editor.registerGlobalToggle("showHitboxes", false)
end

return GameEditor
