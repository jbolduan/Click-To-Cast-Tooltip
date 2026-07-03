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

local function hookHeaderButtons(headerName, maxButtons, tooltipBuilder, tooltipDestroyer)
    local header = _G[headerName]
    if not header then
        return
    end

    for i = 1, maxButtons do
        FrameHooker:HookFrameObject(header[i], tooltipBuilder, tooltipDestroyer, false)
    end
end

function EllesmereUIHandler:HookPartyAndRaidFrames(tooltipBuilder, tooltipDestroyer)
    -- Upstream EllesmereUIRaidFrames globals:
    -- ERFGroupHeader1..8 (5 units each), ERFFlatHeader (40 units), ERFPartyHeader (5 units),
    -- plus ERFPartySelfButton, ERFFriendlyBoss1..5 and ERFExtraFrame1..5.
    for i = 1, 8 do
        hookHeaderButtons("ERFGroupHeader" .. i, 5, tooltipBuilder, tooltipDestroyer)
    end
    hookHeaderButtons("ERFFlatHeader", 40, tooltipBuilder, tooltipDestroyer)
    hookHeaderButtons("ERFPartyHeader", 5, tooltipBuilder, tooltipDestroyer)

    FrameHooker:HookFrame("ERFPartySelfButton", tooltipBuilder, tooltipDestroyer, false)
    FrameHooker:HookNumberedFrames("ERFFriendlyBoss%d", 1, 5, tooltipBuilder, tooltipDestroyer, false)
    FrameHooker:HookNumberedFrames("ERFExtraFrame%d", 1, 5, tooltipBuilder, tooltipDestroyer, false)
end

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

    -- Party and raid frames can vary by Ellesmere layout/version. Hook all matching group frames.
    self:HookPartyAndRaidFrames(tooltipBuilder, tooltipDestroyer)
end

-- Register with the handler registry
addonTable.HandlerRegistry:Register(EllesmereUIHandler)
