local _, addonTable = ...

-- ============================================================================
-- Frame Handler Registry
-- Manages registration and scanning of all frame handlers
-- ============================================================================

addonTable.HandlerRegistry = {}
local Registry = addonTable.HandlerRegistry

-- Internal list of registered handlers
local handlers = {}

--- Registers a new frame handler
-- @param handler table: Handler object with IsEnabled() and ScanAndHook() methods
function Registry:Register(handler)
    if not handler or not handler.name then
        return
    end
    
    -- Avoid duplicate registration
    for _, existing in ipairs(handlers) do
        if existing.name == handler.name then
            return
        end
    end
    
    table.insert(handlers, handler)
end

--- Scans all registered handlers and hooks their frames
-- @param tooltipBuilder function: Called on OnEnter for each frame
-- @param tooltipDestroyer function: Called on OnLeave for each frame
function Registry:ScanAll(tooltipBuilder, tooltipDestroyer)
    for _, handler in ipairs(handlers) do
        if handler:IsEnabled() then
            handler:ScanAndHook(tooltipBuilder, tooltipDestroyer)
        end
    end
end

--- Gets a list of all registered handler names
-- @return table: Array of handler name strings
function Registry:GetHandlerNames()
    local names = {}
    for _, handler in ipairs(handlers) do
        table.insert(names, handler.name)
    end
    return names
end

--- Gets the count of registered handlers
-- @return number: Number of registered handlers
function Registry:GetHandlerCount()
    return #handlers
end

--- Checks if a handler with the given name is registered
-- @param name string: The handler name to check
-- @return boolean: True if handler is registered
function Registry:IsHandlerRegistered(name)
    for _, handler in ipairs(handlers) do
        if handler.name == name then
            return true
        end
    end
    return false
end
