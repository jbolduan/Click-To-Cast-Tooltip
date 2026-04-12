local _, addonTable = ...

-- ============================================================================
-- DandersFrames Handler
-- Hooks DandersFrames unit frames and secure header children
-- ============================================================================

local FrameHooker = addonTable.FrameHooker

local function safeTableFieldGet(tbl, key)
    if type(tbl) ~= "table" then
        return nil
    end

    local ok, value = pcall(function()
        return tbl[key]
    end)

    if ok then
        return value
    end

    return nil
end

local DandersFramesHandler = {
    name = "DandersFrames",

    addonNames = {
        "DandersFrames",
    },

    -- Incremental scan controls to avoid long-running global scans in a single frame.
    dynamicScanInterval = 20,
    dynamicScanMaxEntries = 300,
    dynamicScanMaxMs = 4,
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
    local processed = 0
    local cursor = self._dynamicScanCursor
    local startMs = debugprofilestop and debugprofilestop() or nil

    while true do
        local frameName = next(_G, cursor)
        if frameName == nil then
            self._dynamicScanCursor = nil
            return true
        end

        cursor = frameName
        processed = processed + 1

        if type(frameName) == "string" then
            local isPetFrame = frameName:find("^DandersFrames_Pet_") ~= nil
            local isKnownHeaderChild = frameName:find("^DandersPartyHeaderUnitButton") ~= nil
                or frameName:find("^DandersArenaHeaderUnitButton") ~= nil
                or frameName:find("^DandersFlatRaidHeaderUnitButton") ~= nil
                or frameName:find("^DandersRaidPlayerHeaderUnitButton") ~= nil
                or frameName:find("^DandersRaidGroup%d+HeaderUnitButton") ~= nil

            if isPetFrame or isKnownHeaderChild then
                FrameHooker:HookFrame(frameName, tooltipBuilder, tooltipDestroyer, false)
            elseif frameName:find("^Danders") ~= nil then
                local frame = _G[frameName]
                local isDandersMarked = safeTableFieldGet(frame, "dfIsDandersFrame") == true
                if isDandersMarked and safeTableFieldGet(frame, "HookScript") then
                    FrameHooker:HookFrameObject(frame, tooltipBuilder, tooltipDestroyer, false)
                end
            end
        end

        if processed >= self.dynamicScanMaxEntries then
            break
        end

        if startMs and (debugprofilestop() - startMs) >= self.dynamicScanMaxMs then
            break
        end
    end

    self._dynamicScanCursor = cursor
    return false
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
    -- Keep this incremental to avoid frame hitches from scanning all globals at once.
    local now = GetTime and GetTime() or 0
    local shouldRunDynamicScan = self._dynamicScanCursor ~= nil
        or self._nextDynamicScanAt == nil
        or now >= self._nextDynamicScanAt

    if shouldRunDynamicScan then
        local didComplete = self:HookDynamicFrames(tooltipBuilder, tooltipDestroyer)
        if didComplete then
            self._nextDynamicScanAt = now + self.dynamicScanInterval
        end
    end
end

-- Register with the handler registry
addonTable.HandlerRegistry:Register(DandersFramesHandler)
