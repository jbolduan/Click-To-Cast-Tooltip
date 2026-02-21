local _, addonTable = ...

-- ============================================================================
-- Grid2 Frame Handler
-- Hooks Grid2 addon unit frames when Grid2 is loaded
-- ============================================================================

local FrameHooker = addonTable.FrameHooker

local Grid2Handler = {
    name = "Grid2"
}

--- Checks if Grid2 is loaded and available
-- Grid2 doesn't have a simple global, so we check for frames directly
-- @return boolean: True if Grid2 frames are detected
function Grid2Handler:IsEnabled()
    return _G["Grid2LayoutHeader1UnitButton1"] ~= nil
end

--- Scans and hooks all Grid2 unit frames
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function Grid2Handler:ScanAndHook(tooltipBuilder, tooltipDestroyer)
    -- Grid2 Layout Frames: 8 headers x 5 buttons
    FrameHooker:HookNestedFrames("Grid2LayoutHeader%dUnitButton%d", 1, 8, 1, 5, tooltipBuilder, tooltipDestroyer, false)
end

-- Register with the handler registry
addonTable.HandlerRegistry:Register(Grid2Handler)
