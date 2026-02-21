local _, addonTable = ...

-- ============================================================================
-- Cell Unit Frames (CUF) Handler
-- Hooks Cell Unit Frames addon when CUF is loaded
-- ============================================================================

local FrameHooker = addonTable.FrameHooker

local CellUnitFramesHandler = {
    name = "CellUnitFrames",
    
    -- Static CUF frame names
    staticFrames = {
        "CUF_Player",
        "CUF_Focus",
        "CUF_Pet",
        "CUF_Target",
        "CUF_TargetTarget"
    }
}

--- Checks if Cell Unit Frames (CUF) is loaded and available
-- @return boolean: True if CUF is detected
function CellUnitFramesHandler:IsEnabled()
    ---@diagnostic disable-next-line: undefined-global
    return type(CUF) == "table"
end

--- Scans and hooks all CUF unit frames
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function CellUnitFramesHandler:ScanAndHook(tooltipBuilder, tooltipDestroyer)
    if not self:IsEnabled() then return end
    
    -- Static frames
    FrameHooker:HookFrameList(self.staticFrames, tooltipBuilder, tooltipDestroyer, false)
    
    -- Boss Frames
    FrameHooker:HookNumberedFrames("CUF_Boss%d", 1, 10, tooltipBuilder, tooltipDestroyer, false)
end

-- Register with the handler registry
addonTable.HandlerRegistry:Register(CellUnitFramesHandler)
