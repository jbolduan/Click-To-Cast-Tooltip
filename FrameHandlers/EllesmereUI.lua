local _, addonTable = ...

-- ============================================================================
-- EllesmereUI Unit Frames Handler
-- Hooks EllesmereUI addon unit frames when EllesmereUIUnitFrames is loaded
-- ============================================================================

local FrameHooker = addonTable.FrameHooker

local EllesmereUIHandler = {
    name = "EllesmereUI",

    -- Static EllesmereUI unit frame names (spawned by oUF:Spawn)
    staticFrames = {
        "EllesmereUIUnitFrames_Player",
        "EllesmereUIUnitFrames_Target",
        "EllesmereUIUnitFrames_Focus",
        "EllesmereUIUnitFrames_Pet",
        "EllesmereUIUnitFrames_TargetTarget",
        "EllesmereUIUnitFrames_FocusTarget",
        "EllesmereUIUnitFrames_Boss1",
        "EllesmereUIUnitFrames_Boss2",
        "EllesmereUIUnitFrames_Boss3",
        "EllesmereUIUnitFrames_Boss4",
        "EllesmereUIUnitFrames_Boss5",
    }
}

--- Checks if EllesmereUI Unit Frames is loaded and available
-- @return boolean: True if EllesmereUI is detected
function EllesmereUIHandler:IsEnabled()
    ---@diagnostic disable-next-line: undefined-global
    return type(EllesmereUI) == "table"
end

--- Scans and hooks all EllesmereUI unit frames
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function EllesmereUIHandler:ScanAndHook(tooltipBuilder, tooltipDestroyer)
    if not self:IsEnabled() then return end

    -- Static frames (player, target, focus, pet, targettarget, focustarget, boss 1-5)
    FrameHooker:HookFrameList(self.staticFrames, tooltipBuilder, tooltipDestroyer, false)
end

-- Register with the handler registry
addonTable.HandlerRegistry:Register(EllesmereUIHandler)
