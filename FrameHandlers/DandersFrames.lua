local _, addonTable = ...

-- ============================================================================
-- DandersFrames Handler
-- Hooks DandersFrames unit frames and secure header children
-- ============================================================================

local FrameHooker = addonTable.FrameHooker

local DandersFramesHandler = {
    name = "DandersFrames",

    addonNames = {
        "DandersFrames",
    }
}

--- Checks if DandersFrames is loaded and available
-- @return boolean: True if DandersFrames is detected
function DandersFramesHandler:IsEnabled()
    ---@diagnostic disable-next-line: undefined-global
    if type(DandersFrames) == "table" then
        return true
    end

    if C_AddOns and C_AddOns.IsAddOnLoaded then
        for _, addonName in ipairs(self.addonNames) do
            if C_AddOns.IsAddOnLoaded(addonName) then
                return true
            end
        end
    end

    -- Fallback checks based on upstream frame names.
    return _G["DandersPartyHeader"] ~= nil
        or _G["DandersArenaHeader"] ~= nil
        or _G["DandersFlatRaidHeader"] ~= nil
end

--- Hooks children from a SecureGroupHeaderTemplate header
-- @param header Frame: Header object
-- @param maxChildren number: Max child count to scan
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function DandersFramesHandler:HookHeaderChildren(header, maxChildren, tooltipBuilder, tooltipDestroyer)
    if not header or not header.GetAttribute then
        return
    end

    for i = 1, maxChildren do
        local child = header:GetAttribute("child" .. i)
        if child then
            FrameHooker:HookFrameObject(child, tooltipBuilder, tooltipDestroyer, false)
        end
    end
end

--- Hooks global DandersFrames objects by marker/prefix
-- DandersFrames marks unit buttons with frame.dfIsDandersFrame = true.
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function DandersFramesHandler:HookDynamicFrames(tooltipBuilder, tooltipDestroyer)
    for frameName, frame in pairs(_G) do
        local canReadHookScript, hookScript = pcall(function()
            return frame and frame.HookScript
        end)

        if type(frameName) == "string" and type(frame) == "table" and canReadHookScript and hookScript then
            local lowerName = frameName:lower()
            local isDandersMarked = false
            local canReadMarker, markerValue = pcall(function()
                return frame.dfIsDandersFrame
            end)
            if canReadMarker and markerValue == true then
                isDandersMarked = true
            end

            local isPetFrame = lowerName:find("^dandersframes_pet_") ~= nil
            local isKnownHeaderChild = lowerName:find("^danderspartyheaderunitbutton") ~= nil
                or lowerName:find("^dandersarenaheaderunitbutton") ~= nil
                or lowerName:find("^dandersflatraidheaderunitbutton") ~= nil
                or lowerName:find("^dandersraidplayerheaderunitbutton") ~= nil
                or lowerName:find("^dandersraidgroup%d+headerunitbutton") ~= nil

            if isDandersMarked or isPetFrame or isKnownHeaderChild then
                FrameHooker:HookFrameObject(frame, tooltipBuilder, tooltipDestroyer, false)
            end
        end
    end
end

--- Scans and hooks all DandersFrames unit frames
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function DandersFramesHandler:ScanAndHook(tooltipBuilder, tooltipDestroyer)
    if not self:IsEnabled() then return end

    -- Party and arena headers (up to 5 children each).
    self:HookHeaderChildren(_G["DandersPartyHeader"], 5, tooltipBuilder, tooltipDestroyer)
    self:HookHeaderChildren(_G["DandersArenaHeader"], 5, tooltipBuilder, tooltipDestroyer)

    -- Grouped raid headers (8 groups x 5 players).
    for group = 1, 8 do
        local groupHeader = _G[string.format("DandersRaidGroup%dHeader", group)]
        self:HookHeaderChildren(groupHeader, 5, tooltipBuilder, tooltipDestroyer)
    end

    -- Flat raid mode and separate raid-player header.
    self:HookHeaderChildren(_G["DandersFlatRaidHeader"], 40, tooltipBuilder, tooltipDestroyer)
    self:HookHeaderChildren(_G["DandersRaidPlayerHeader"], 1, tooltipBuilder, tooltipDestroyer)

    -- Fallback for marker-based and pet frame discovery.
    self:HookDynamicFrames(tooltipBuilder, tooltipDestroyer)
end

-- Register with the handler registry
addonTable.HandlerRegistry:Register(DandersFramesHandler)
