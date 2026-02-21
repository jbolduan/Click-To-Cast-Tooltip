local _, addonTable = ...

-- ============================================================================
-- Unhalted Unit Frames Handler
-- Hooks UUF addon unit frames when UnhaltedUnitFrames is loaded
-- ============================================================================

local FrameHooker = addonTable.FrameHooker

local UUFHandler = {
    name = "UnhaltedUnitFrames",
    
    -- Static UUF unit frame names
    staticFrames = {
        "UUF_Player",
        "UUF_Target",
        "UUF_TargetTarget",
        "UUF_Focus",
        "UUF_FocusTarget",
        "UUF_Pet"
    }
}

--- Checks if Unhalted Unit Frames is loaded and available
-- @return boolean: True if UUF is detected
function UUFHandler:IsEnabled()
    -- Check if the addon is loaded and the player frame exists
    return C_AddOns.IsAddOnLoaded("UnhaltedUnitFrames") and _G["UUF_Player"] ~= nil
end

--- Scans and hooks all UUF unit frames
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function UUFHandler:ScanAndHook(tooltipBuilder, tooltipDestroyer)
    if not self:IsEnabled() then return end
    
    -- Static unit frames
    FrameHooker:HookFrameList(self.staticFrames, tooltipBuilder, tooltipDestroyer, false)
    
    -- Boss frames: UUF_Boss1 through UUF_Boss5
    FrameHooker:HookNumberedFrames("UUF_Boss%d", 1, 5, tooltipBuilder, tooltipDestroyer, false)
end

-- Register with the handler registry
addonTable.HandlerRegistry:Register(UUFHandler)
