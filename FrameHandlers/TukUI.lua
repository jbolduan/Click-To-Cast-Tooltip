local _, addonTable = ...

-- ============================================================================
-- TukUI Frame Handler
-- Hooks TukUI unit frames when TukUI is loaded
-- ============================================================================

local FrameHooker = addonTable.FrameHooker

local TukUIHandler = {
    name = "TukUI",
    
    -- Static TukUI frame names
    staticFrames = {
        "TukuiPlayerFrame",
        "TukuiTargetFrame",
        "TukuiTargetTargetFrame",
        "TukuiFocusFrame",
        "TukuiFocusTargetFrame",
        "TukuiPetFrame"
    }
}

--- Checks if TukUI is loaded and available
-- @return boolean: True if TukUI is detected
function TukUIHandler:IsEnabled()
    return type(T) == "table" or type(Tukui) == "table"
end

--- Scans and hooks all TukUI unit frames
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function TukUIHandler:ScanAndHook(tooltipBuilder, tooltipDestroyer)
    if not self:IsEnabled() then return end
    
    -- Static frames
    FrameHooker:HookFrameList(self.staticFrames, tooltipBuilder, tooltipDestroyer, false)
    
    -- Party Frames
    FrameHooker:HookNumberedFrames("TukuiPartyUnitButton%d", 1, 4, tooltipBuilder, tooltipDestroyer, false)
    
    -- Raid Frames
    FrameHooker:HookNumberedFrames("TukuiRaidUnitButton%d", 1, 40, tooltipBuilder, tooltipDestroyer, false)
    
    -- Raid Pet Frames
    FrameHooker:HookNumberedFrames("TukuiRaidPetUnitButton%d", 1, 20, tooltipBuilder, tooltipDestroyer, false)
end

-- Register with the handler registry
addonTable.HandlerRegistry:Register(TukUIHandler)
