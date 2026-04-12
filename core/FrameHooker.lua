local _, addonTable = ...

-- ============================================================================
-- Frame Hooker Utility
-- Provides reusable functions for hooking unit frames with OnEnter/OnLeave
-- ============================================================================

addonTable.FrameHooker = {}
local FrameHooker = addonTable.FrameHooker

local function safeHasHookScript(frame)
    if type(frame) ~= "table" then
        return false
    end

    local ok, hookScript = pcall(function()
        return frame.HookScript
    end)

    return ok and hookScript ~= nil
end

--- Propagates mouse events through health/mana bars to parent frame
-- @param frame Frame: The unit frame to check for bars
local function propagateMouseThroughBars(frame)
    if type(frame) ~= "table" then return end
    
    local checked = {}
    local function recurse(f)
        if type(f) ~= "table" or checked[f] then return end
        checked[f] = true
        
        for key, value in pairs(f) do
            if key == "HealthBar" or key == "ManaBar" or key == "AlternatePowerBar" then
                if value.SetPropagateMouseClicks then
                    value:SetPropagateMouseClicks(true)
                    value:SetPropagateMouseMotion(true)
                end
            elseif type(value) == "table" then
                recurse(value)
            end
        end
    end
    
    recurse(frame)
    
    -- Also propagate on the main frame
    if frame.SetPropagateMouseClicks then
        frame:SetPropagateMouseClicks(true)
        frame:SetPropagateMouseMotion(true)
    end
end

--- Hooks a single frame with OnEnter/OnLeave handlers
-- @param frame Frame: The frame object to hook (not a name string)
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
-- @param propagateMouse boolean: Whether to propagate mouse through child bars
-- @return boolean: True if frame was hooked, false otherwise
function FrameHooker:HookFrameObject(frame, tooltipBuilder, tooltipDestroyer, propagateMouse)
    if not safeHasHookScript(frame) or addonTable.hookedFrames[frame] then
        return false
    end
    
    frame:HookScript("OnEnter", function(self)
        addonTable.lastHoveredFrame = frame
        tooltipBuilder(self)
    end)
    
    frame:HookScript("OnLeave", function(self)
        tooltipDestroyer(self)
        addonTable.scheduleFrameClear(frame)
    end)
    
    if propagateMouse then
        propagateMouseThroughBars(frame)
    end
    
    addonTable.hookedFrames[frame] = true
    return true
end

--- Hooks a frame by its global name
-- @param frameName string: The global name of the frame
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
-- @param propagateMouse boolean: Whether to propagate mouse through child bars
-- @return boolean: True if frame was hooked, false otherwise
function FrameHooker:HookFrame(frameName, tooltipBuilder, tooltipDestroyer, propagateMouse)
    local frame = _G[frameName]
    return self:HookFrameObject(frame, tooltipBuilder, tooltipDestroyer, propagateMouse)
end

--- Hooks a list of frames by their global names
-- @param frameNames table: Array of frame name strings
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
-- @param propagateMouse boolean: Whether to propagate mouse through child bars
function FrameHooker:HookFrameList(frameNames, tooltipBuilder, tooltipDestroyer, propagateMouse)
    for _, frameName in ipairs(frameNames) do
        self:HookFrame(frameName, tooltipBuilder, tooltipDestroyer, propagateMouse)
    end
end

--- Hooks numbered frames following a pattern (e.g., "Boss%dTargetFrame" for Boss1TargetFrame, Boss2TargetFrame, etc.)
-- @param pattern string: Format string with %d placeholder for the number
-- @param startIndex number: Starting index
-- @param endIndex number: Ending index (inclusive)
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
-- @param propagateMouse boolean: Whether to propagate mouse through child bars
function FrameHooker:HookNumberedFrames(pattern, startIndex, endIndex, tooltipBuilder, tooltipDestroyer, propagateMouse)
    for i = startIndex, endIndex do
        local frameName = string.format(pattern, i)
        self:HookFrame(frameName, tooltipBuilder, tooltipDestroyer, propagateMouse)
    end
end

--- Hooks frames with two-level numbering (e.g., "CompactRaidGroup%dMember%d")
-- @param pattern string: Format string with two %d placeholders
-- @param outerStart number: Outer loop starting index
-- @param outerEnd number: Outer loop ending index
-- @param innerStart number: Inner loop starting index
-- @param innerEnd number: Inner loop ending index
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
-- @param propagateMouse boolean: Whether to propagate mouse through child bars
function FrameHooker:HookNestedFrames(pattern, outerStart, outerEnd, innerStart, innerEnd, tooltipBuilder, tooltipDestroyer, propagateMouse)
    for i = outerStart, outerEnd do
        for j = innerStart, innerEnd do
            local frameName = string.format(pattern, i, j)
            self:HookFrame(frameName, tooltipBuilder, tooltipDestroyer, propagateMouse)
        end
    end
end

--- Hooks frames with three-level numbering
-- @param pattern string: Format string with three %d placeholders
-- @param level1Start number: First level starting index
-- @param level1End number: First level ending index
-- @param level2Start number: Second level starting index
-- @param level2End number: Second level ending index
-- @param level3Start number: Third level starting index
-- @param level3End number: Third level ending index
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
-- @param propagateMouse boolean: Whether to propagate mouse through child bars
function FrameHooker:HookTripleNestedFrames(pattern, level1Start, level1End, level2Start, level2End, level3Start, level3End, tooltipBuilder, tooltipDestroyer, propagateMouse)
    for i = level1Start, level1End do
        for j = level2Start, level2End do
            for k = level3Start, level3End do
                local frameName = string.format(pattern, i, j, k)
                self:HookFrame(frameName, tooltipBuilder, tooltipDestroyer, propagateMouse)
            end
        end
    end
end

--- Hooks frames from a frame pool (used by party frames)
-- @param pool table: The frame pool to enumerate
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function FrameHooker:HookFramePool(pool, tooltipBuilder, tooltipDestroyer)
    if not pool or not pool.EnumerateActive then return end
    
    for frame in pool:EnumerateActive() do
        self:HookFrameObject(frame, tooltipBuilder, tooltipDestroyer, false)
    end
end
