local _, addonTable = ...

-- ============================================================================
-- Blizzard Frame Handler
-- Hooks default WoW unit frames (player, target, party, raid, etc.)
-- ============================================================================

local FrameHooker = addonTable.FrameHooker

local BlizzardHandler = {
    name = "Blizzard",
    
    -- Static frame names that are always present
    staticFrames = {
        "PlayerFrame",
        "AlternatePowerBar",
        "TargetFrame",
        "TargetFrameToT",
        "FocusFrame",
        "FocusFrameToT",
        "PetFrame",
    }
}

--- Checks if this handler should be active
-- Blizzard frames are always available
-- @return boolean: Always returns true
function BlizzardHandler:IsEnabled()
    return true
end

--- Scans and hooks all Blizzard unit frames
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function BlizzardHandler:ScanAndHook(tooltipBuilder, tooltipDestroyer)
    -- Hook static frames with mouse propagation through health/mana bars
    FrameHooker:HookFrameList(self.staticFrames, tooltipBuilder, tooltipDestroyer, true)
    
    -- Party Frames (from frame pool)
    local partyFrame = _G["PartyFrame"]
    if partyFrame and partyFrame.PartyMemberFramePool then
        FrameHooker:HookFramePool(partyFrame.PartyMemberFramePool, tooltipBuilder, tooltipDestroyer)
    end
    
    -- Compact Party Frames
    FrameHooker:HookNumberedFrames("CompactPartyFrameMember%d", 1, 5, tooltipBuilder, tooltipDestroyer, false)
    
    -- Boss Frames
    FrameHooker:HookNumberedFrames("Boss%dTargetFrame", 1, 10, tooltipBuilder, tooltipDestroyer, false)
    
    -- Compact Raid Frames (8 groups x 40 members max)
    FrameHooker:HookNestedFrames("CompactRaidGroup%dMember%d", 1, 8, 1, 40, tooltipBuilder, tooltipDestroyer, false)
    
    -- Arena Enemy Frames
    FrameHooker:HookNumberedFrames("ArenaEnemyFrame%d", 1, 5, tooltipBuilder, tooltipDestroyer, false)
end

-- Register with the handler registry
addonTable.HandlerRegistry:Register(BlizzardHandler)
