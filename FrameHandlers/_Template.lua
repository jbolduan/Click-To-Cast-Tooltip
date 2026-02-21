local _, addonTable = ...

-- ============================================================================
-- TEMPLATE: New Frame Handler
-- Copy this file and modify it to add support for a new unit frame addon
-- ============================================================================
--[[
    HOW TO ADD SUPPORT FOR A NEW ADDON:
    
    1. Copy this file to FrameHandlers/YourAddonName.lua
    2. Update the handler name and detection logic in IsEnabled()
    3. Add the static frame names your addon uses
    4. Implement ScanAndHook() to hook all frame patterns
    5. Add the file to Click-To-Cast-Tooltip.toc under "# Frame Handlers"
    
    The handler will automatically be scanned every 5 seconds and on
    GROUP_ROSTER_UPDATE, RAID_ROSTER_UPDATE, and PLAYER_ENTERING_WORLD events.
]]

local FrameHooker = addonTable.FrameHooker

local TemplateHandler = {
    -- REQUIRED: Unique name for this handler
    name = "TemplateAddon",
    
    -- OPTIONAL: List of static frame names (frames that always exist)
    staticFrames = {
        -- "AddonName_PlayerFrame",
        -- "AddonName_TargetFrame",
    }
}

--- REQUIRED: Checks if the addon is loaded and available
-- Return true only if the addon is detected
-- @return boolean: True if the addon is detected
function TemplateHandler:IsEnabled()
    -- Example detection methods:
    
    -- Method 1: Check for a global table
    -- return type(AddonName) == "table"
    
    -- Method 2: Check for a saved variable
    -- return type(AddonNameDB) == "table"
    
    -- Method 3: Check if a key frame exists
    -- return _G["AddonName_MainFrame"] ~= nil
    
    return false  -- Disabled by default in template
end

--- REQUIRED: Scans and hooks all unit frames from this addon
-- @param tooltipBuilder function: Called when mouse enters a frame
-- @param tooltipDestroyer function: Called when mouse leaves a frame
function TemplateHandler:ScanAndHook(tooltipBuilder, tooltipDestroyer)
    if not self:IsEnabled() then return end
    
    -- Hook static frames (frames that always exist with fixed names)
    FrameHooker:HookFrameList(self.staticFrames, tooltipBuilder, tooltipDestroyer, false)
    
    -- Hook numbered frames (e.g., PartyFrame1, PartyFrame2, etc.)
    -- FrameHooker:HookNumberedFrames("AddonName_PartyFrame%d", 1, 5, tooltipBuilder, tooltipDestroyer, false)
    
    -- Hook nested frames (e.g., RaidGroup1Member1 through RaidGroup8Member5)
    -- FrameHooker:HookNestedFrames("AddonName_Group%dMember%d", 1, 8, 1, 5, tooltipBuilder, tooltipDestroyer, false)
    
    -- Hook triple nested frames (rare, but supported)
    -- FrameHooker:HookTripleNestedFrames("AddonName_Raid%dGroup%dUnit%d", 1, 3, 1, 8, 1, 5, tooltipBuilder, tooltipDestroyer, false)
    
    -- The last parameter (propagateMouse) should be:
    -- true  - For Blizzard-style frames where mouse clicks need to pass through HealthBar/ManaBar
    -- false - For most addon frames that handle this themselves
end

-- REQUIRED: Register with the handler registry
-- Uncomment this line when your handler is ready
-- addonTable.HandlerRegistry:Register(TemplateHandler)
