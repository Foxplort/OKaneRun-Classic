local Assets = {}

-- Registries
Assets.images = {}
Assets.sounds = {}
Assets.asset_registry = {}

-- Async and optimization state
Assets.pending_assets = 0
Assets.planned_loads = {}
Assets.planned_unloads = {}

local loader_channel = love.thread.getChannel("fore_loader")
local response_channel = love.thread.getChannel("fore_response")

local fore = nil

function Assets.init(foreRef)
    fore = foreRef
end

-- ASSET CORE API

function Assets.getImage(name) return Assets.images[name] end
function Assets.getSound(name) return Assets.sounds[name] end

function Assets.loadImage(name, path, imgtype)
    Assets.pending_assets = Assets.pending_assets + 1
    Assets.asset_registry[name] = {type = "image", path = path, imgtype = imgtype or "linear"}
    
    loader_channel:push({
        cmd = "load_image", 
        name = name, 
        path = path, 
        imgtype = imgtype or "nearest"
    })
end

function Assets.loadAudioStatic(name, path, category)
    Assets.pending_assets = Assets.pending_assets + 1
    Assets.asset_registry[name] = {type = "audio", path = path, category = category}
    
    loader_channel:push({
        cmd = "load_audio", 
        name = name, 
        path = path, 
        category = category
    })
end

function Assets.unloadImage(name)
    Assets.images[name] = nil
    Assets.asset_registry[name] = nil
end

-- ASSET THREAD DISPATCHER LOOP

function Assets.update_loading()
    local uploads_this_frame = 0
    local max_uploads = 1

    while uploads_this_frame < max_uploads do
        local msg = response_channel:pop()
        if not msg then break end

        if msg.type == "image" then
            -- Graphics backend handles creating the engine texture wrapper
            Assets.images[msg.name] = fore.draw2d.newTextureInstance(msg.data, msg.imgtype)
            Assets.pending_assets = Assets.pending_assets - 1
            uploads_this_frame = uploads_this_frame + 1

        elseif msg.type == "audio" then
            -- Audio backend handles converting binary sound data into source objects
            Assets.sounds[msg.name] = fore.audio.newStaticClipInstance(msg.name, msg.data, msg.category)
            Assets.pending_assets = Assets.pending_assets - 1
        
        elseif msg.type == "error" then
            Assets.pending_assets = Assets.pending_assets - 1
        end
    end
end

-- SMART SYSTEM

function Assets.scheduleLoad(name, path, imgtype)
    Assets.planned_loads[name] = {path = path, imgtype = imgtype or "linear"}
end

function Assets.scheduleUnload(name)
    Assets.planned_unloads[name] = true
end

function Assets.flushAssetSchedule()
    local available_paths = {}
    for existing_name, data in pairs(Assets.asset_registry) do
        available_paths[data.path] = available_paths[data.path] or {}
        table.insert(available_paths[data.path], existing_name)
    end

    for new_name, load_data in pairs(Assets.planned_loads) do
        local path = load_data.path
        local existing_names = available_paths[path]

        if existing_names and #existing_names > 0 then
            local exact_match = false
            for _, ename in ipairs(existing_names) do
                if ename == new_name then
                    exact_match = true
                    break
                end
            end

            if exact_match then
                Assets.planned_unloads[new_name] = nil
            else
                local reused_name = nil
                for i, ename in ipairs(existing_names) do
                    if Assets.planned_unloads[ename] then
                        reused_name = ename
                        table.remove(existing_names, i)
                        break
                    end
                end

                if reused_name then
                    Assets.images[new_name] = Assets.images[reused_name]
                    Assets.asset_registry[new_name] = Assets.asset_registry[reused_name]
                    
                    Assets.images[reused_name] = nil
                    Assets.asset_registry[reused_name] = nil
                    
                    Assets.planned_unloads[reused_name] = nil
                    Assets.planned_unloads[new_name] = nil
                    
                    table.insert(existing_names, new_name)
                else
                    local source_name = existing_names[1]
                    Assets.images[new_name] = Assets.images[source_name]
                    Assets.asset_registry[new_name] = {path = path, imgtype = load_data.imgtype}
                    Assets.planned_unloads[new_name] = nil
                    table.insert(existing_names, new_name)
                end
            end
        else
            Assets.loadImage(new_name, path, load_data.imgtype)
            Assets.planned_unloads[new_name] = nil
        end
    end

    for name, _ in pairs(Assets.planned_unloads) do
        Assets.unloadImage(name)
    end

    Assets.planned_loads = {}
    Assets.planned_unloads = {}
end

return Assets