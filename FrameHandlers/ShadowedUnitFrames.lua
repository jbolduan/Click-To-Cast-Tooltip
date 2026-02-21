local _, addonTable = ...

-- ============================================================================
-- Shadowed Unit Frames Handler
-- Hooks SUF addon unit frames when ShadowedUF is loaded
-- ============================================================================

local FrameHooker = addonTable.FrameHooker

local SUFHandler = {
    name = "ShadowedUnitFrames",
    
    -- Static SUF frame names
    staticFrames = {
        "SUFUnitplayer",
        "SUFUnitpet",
        "SUFUnittarget",
        "SUFUnittargettarget",
        "SUFUnittargettargettarget",
        "SUFUnitfocus",
        "SUFUnitfocustarget",
        "SUFHeadermainassistUnitButton1",
        "SUFHeadermaintankUnitButton1"
    }
}

--- Checks if Shadowed Unit Frames is loaded and available
-- @return boolean: True if SUF is detected
function SUFHandler:IsEnabled()
    ---@diagnostic disable-next-line: undefined-global
    return type(ShadowedUFDB) == "table"
end

--- Scans and hooks all SUF unit frames
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function SUFHandler:ScanAndHook(tooltipBuilder, tooltipDestroyer)
    if not self:IsEnabled() then return end
    
    -- Static frames
    FrameHooker:HookFrameList(self.staticFrames, tooltipBuilder, tooltipDestroyer, false)
    
    -- Party Frames
    FrameHooker:HookNumberedFrames("SUFHeaderpartyUnitButton%d", 1, 5, tooltipBuilder, tooltipDestroyer, false)
    
    -- Raid Frames
    FrameHooker:HookNumberedFrames("SUFHeaderraidUnitButton%d", 1, 40, tooltipBuilder, tooltipDestroyer, false)
end

-- Register with the handler registry
addonTable.HandlerRegistry:Register(SUFHandler)
