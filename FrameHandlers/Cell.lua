local _, addonTable = ...

-- ============================================================================
-- Cell Frame Handler
-- Hooks Cell addon unit frames when Cell is loaded
-- ============================================================================

local FrameHooker = addonTable.FrameHooker

local CellHandler = {
    name = "Cell",
    
    -- Static Cell frame names
    staticFrames = {
        "CellSoloFramePet",
        "CellSoloFramePlayer"
    }
}

--- Checks if Cell is loaded and available
-- @return boolean: True if Cell is detected
function CellHandler:IsEnabled()
    ---@diagnostic disable-next-line: undefined-global
    return type(Cell) == "table"
end

--- Scans and hooks all Cell unit frames
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function CellHandler:ScanAndHook(tooltipBuilder, tooltipDestroyer)
    if not self:IsEnabled() then return end
    
    -- Static frames
    FrameHooker:HookFrameList(self.staticFrames, tooltipBuilder, tooltipDestroyer, false)
    
    -- Arena Pet Frames
    FrameHooker:HookNumberedFrames("CellArenaPet%d", 1, 3, tooltipBuilder, tooltipDestroyer, false)
    
    -- NPC Frames
    FrameHooker:HookNumberedFrames("CellNPCFrameButton%d", 1, 8, tooltipBuilder, tooltipDestroyer, false)
    
    -- Party Frames
    FrameHooker:HookNumberedFrames("CellPartyFrameHeaderUnitButton%d", 1, 5, tooltipBuilder, tooltipDestroyer, false)
    
    -- Party Pet Frames
    FrameHooker:HookNumberedFrames("CellPartyFrameUnitButton%dPet", 1, 8, tooltipBuilder, tooltipDestroyer, false)
    
    -- Pet Frames Separate
    FrameHooker:HookNumberedFrames("CellPetFrameHeaderUnitButton%d", 1, 20, tooltipBuilder, tooltipDestroyer, false)
    
    -- Quick Assist Frames
    FrameHooker:HookNumberedFrames("CellQuickAssistHeaderUnitButton%d", 1, 40, tooltipBuilder, tooltipDestroyer, false)
    
    -- Raid0 Frames (combined layout)
    FrameHooker:HookNumberedFrames("CellRaidFrameHeader0UnitButton%d", 1, 40, tooltipBuilder, tooltipDestroyer, false)
    
    -- Raid Frames (grouped layout: 8 groups x 5 members)
    FrameHooker:HookNestedFrames("CellRaidFrameHeader%dUnitButton%d", 1, 8, 1, 5, tooltipBuilder, tooltipDestroyer, false)
    
    -- Spotlight Frames
    FrameHooker:HookNumberedFrames("CellSpotlightFrameUnitButton%d", 1, 15, tooltipBuilder, tooltipDestroyer, false)
end

-- Register with the handler registry
addonTable.HandlerRegistry:Register(CellHandler)
