local _, addonTable = ...

-- ============================================================================
-- ElvUI Frame Handler
-- Hooks ElvUI unit frames when ElvUI addon is loaded
-- ============================================================================

local FrameHooker = addonTable.FrameHooker

local ElvUIHandler = {
    name = "ElvUI",
    
    -- Static ElvUI unit frame names
    staticFrames = {
        "ElvUF_Player",
        "ElvUF_Target",
        "ElvUF_TargetTarget",
        "ElvUF_TargetTargetTarget",
        "ElvUF_Focus",
        "ElvUF_FocusTarget",
        "ElvUF_Pet",
        "ElvUF_PetTarget",
        "ElvUF_AssistUnitButton1"
    }
}

--- Checks if ElvUI is loaded and available
-- @return boolean: True if ElvUI is detected
function ElvUIHandler:IsEnabled()
    ---@diagnostic disable-next-line: undefined-global
    return type(ElvUI) == "table"
end

--- Scans and hooks all ElvUI unit frames
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function ElvUIHandler:ScanAndHook(tooltipBuilder, tooltipDestroyer)
    if not self:IsEnabled() then return end
    
    -- Static unit frames
    FrameHooker:HookFrameList(self.staticFrames, tooltipBuilder, tooltipDestroyer, false)
    
    -- Party frames: ElvUF_PartyGroup1UnitButton1 through ElvUF_PartyGroup4UnitButton5
    FrameHooker:HookNestedFrames("ElvUF_PartyGroup%dUnitButton%d", 1, 4, 1, 5, tooltipBuilder, tooltipDestroyer, false)
    
    -- Raid frames for each raid layout (1-3)
    for raid = 1, 3 do
        local pattern = "ElvUF_Raid" .. raid .. "Group%dUnitButton%d"
        FrameHooker:HookNestedFrames(pattern, 1, 8, 1, 5, tooltipBuilder, tooltipDestroyer, false)
    end
    
    -- Raid pet frames
    FrameHooker:HookNumberedFrames("ElvUF_RaidpetGroup1UnitButton%d", 1, 9, tooltipBuilder, tooltipDestroyer, false)
    
    -- Arena frames
    FrameHooker:HookNumberedFrames("ElvUF_Arena%d", 1, 5, tooltipBuilder, tooltipDestroyer, false)
    
    -- Boss frames
    FrameHooker:HookNumberedFrames("ElvUF_Boss%d", 1, 8, tooltipBuilder, tooltipDestroyer, false)
end

-- Register with the handler registry
addonTable.HandlerRegistry:Register(ElvUIHandler)
