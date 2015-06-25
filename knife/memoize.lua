local unpack = table.unpack or _G.unpack
local weakKeys = { __mode = 'k' }
local cache = setmetatable({}, weakKeys)
local resultsKey = {}
local nilKey = {}

local function getMetaCall (callable)
    local meta = getmetatable(callable)
    return meta and meta.__call
end

return function (callable)
    local metaCall = getMetaCall(callable)
    
    if type(callable) ~= 'function' and not metaCall then
        error 'Attempted to memoize a non-callable value.'
    end
    
    cache[callable] = setmetatable({}, weakKeys)

    local function run (...)
        local node = cache[callable]
        local args = { ... }
        
        for i = 1, #args do
            local key = args[i]
            if key == nil then
                key = nilKey
            end
            if not node[key] then
                node[key] = setmetatable({}, weakKeys)
            end
            node = node[key]
        end
        
        if not node[resultsKey] then 
            node[resultsKey] = { callable(...) }
        end
        
        return unpack(node[resultsKey])
    end
    
    if metaCall then 
        return function (...)
            local call = getMetaCall(callable)
            
            if call ~= metaCall then
                cache[callable] = setmetatable({}, weakKeys)
                metaCall = call
            end
            
            return run(...)
        end, cache, resultsKey, nilKey
    end
    
    return run, cache, resultsKey, nilKey
end

