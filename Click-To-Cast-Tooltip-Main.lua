local _, addonTable = ...

-- ============================================================================
-- Click-To-Cast-Tooltip Main Entry Point (Refactored)
-- Uses modular frame handlers for easy extensibility
-- ============================================================================

-- Setup custom tooltip that will be shown at the mouse
addonTable.clickCastingTooltip:SetFrameStrata("TOOLTIP")
addonTable.clickCastingTooltip:RegisterEvent("MODIFIER_STATE_CHANGED")

-- Initialize Frame Handlers
addonTable.frameHandler.init()

-- Track which unit we've already added content for
-- This prevents duplicates when TooltipDataProcessor fires multiple times
local lastProcessedGUID = nil

-- Reset tracking when tooltip is hidden
GameTooltip:HookScript("OnHide", function(self)
    lastProcessedGUID = nil
end)

-- ============================================================================
-- Tooltip Builder Functions
-- ============================================================================

--- Builds and displays the custom tooltip at the mouse cursor.
-- @param frame Frame: The unit frame the mouse is over
local function clickToCastTooltipBuilder(frame)
    local db = ClickToCastTooltip and ClickToCastTooltip.db and ClickToCastTooltip.db.global
    local specID = GetSpecializationInfo(GetSpecialization())
    
    if not (db and type(db.showCustomTooltip) == "boolean" and db.showCustomTooltip) then
        addonTable.clickCastingTooltip:Hide()
        return
    end
    
    if specID and db and db["specToggle_" .. specID] == false then
        addonTable.clickCastingTooltip:Hide()
        return
    end
    
    -- Check if this unit frame type should show the tooltip
    if not addonTable.shouldShowForUnitFrameType(frame) then
        addonTable.clickCastingTooltip:Hide()
        return
    end
    
    local clickBindings = C_ClickBindings.GetProfileInfo()
    addonTable.clickCastingTooltip:ClearLines()
    addonTable.clickCastingTooltip:SetOwner(UIParent, "ANCHOR_NONE")

    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local anchor = "BOTTOMRIGHT"
    
    if db and type(db.tooltipAnchor) == "number" then
        anchor = addonTable.anchorMap[db.tooltipAnchor] or "BOTTOMRIGHT"
    elseif db and type(db.tooltipAnchor) == "string" then
        anchor = db.tooltipAnchor
    end
    
    addonTable.clickCastingTooltip:SetPoint(anchor, UIParent, "BOTTOMLEFT", x / scale, y / scale)
    local nonBlankLineCount = {value = 0}
    
    addonTable.updateTooltip(db, clickBindings, addonTable.clickCastingTooltip, nonBlankLineCount)
    
    if nonBlankLineCount.value > 0 then
        addonTable.frameHandler.init()
        -- Apply theme settings before showing
        if addonTable.applyTooltipTheme then
            addonTable.applyTooltipTheme()
        end
        addonTable.clickCastingTooltip:Show()
        
        addonTable.clickCastingTooltip:SetScript("OnUpdate", function(self)
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            self:ClearAllPoints()
            self:SetPoint(anchor, UIParent, "BOTTOMLEFT", x / scale, y / scale)
            self:SetAlpha(db.tooltipTransparency)
        end)
    else
        addonTable.clickCastingTooltip:Hide()
    end
end

--- Builds and displays the Blizzard tooltip with click binding info.
-- @param tooltip GameTooltip: The Blizzard tooltip frame
local function blizzardTooltipBuilder(tooltip)
    -- Guard against nil tooltip or non-GameTooltip frames
    if not tooltip or tooltip ~= GameTooltip then
        return
    end
    
    -- Only show on hooked unit frames, not world units
    -- Check if we're actually hovering over a tracked unit frame
    if not addonTable.lastHoveredFrame or not addonTable.lastHoveredFrame:IsMouseOver() then
        return
    end
    
    -- Get the unit being displayed
    local _, unit = tooltip:GetUnit()
    if not unit then
        return
    end
    
    -- Use pcall to handle tainted unit values during secure execution (e.g., in dungeons)
    local success, unitGUID = pcall(UnitGUID, unit)
    if not success then
        return
    end
    
    -- Prevent duplicate content - only add once per unit
    if unitGUID and unitGUID == lastProcessedGUID then
        return
    end
    lastProcessedGUID = unitGUID
    
    local db = ClickToCastTooltip and ClickToCastTooltip.db and ClickToCastTooltip.db.global

    if db and db.showTooltip == false then
        return
    end
    
    -- Check if this unit frame type should show the tooltip
    if not addonTable.shouldShowForUnitFrameType(addonTable.lastHoveredFrame) then
        return
    end

    local clickBindings = C_ClickBindings.GetProfileInfo()
    local nonBlankLineCount = {value = 0}

    if db and type(db.showNewLineTop) == "boolean" and db.showNewLineTop then
        tooltip:AddLine(" ")
    end

    if db and type(db.showHeader) == "boolean" and db.showHeader then
        local dividerColor = CreateColorFromHexString(db.dividerColor)
        local headerLine = dividerColor:WrapTextInColorCode("--------------------")
        tooltip:AddLine(headerLine)
    end

    addonTable.updateTooltip(db, clickBindings, tooltip, nonBlankLineCount)

    if db and type(db.showFooter) == "boolean" and db.showFooter then
        local dividerColor = CreateColorFromHexString(db.dividerColor)
        local footerLine = dividerColor:WrapTextInColorCode("--------------------")
        tooltip:AddLine(footerLine)
    end

    if db and type(db.showNewLineBottom) == "boolean" and db.showNewLineBottom then
        tooltip:AddLine(" ")
    end
end

--- Hides and cleans up the custom tooltip.
-- @param frame Frame: The unit frame the mouse is leaving
local function clickToCastTooltipDestroyer(frame)
    -- Only hide if we're leaving the currently tracked frame
    -- This prevents hiding when moving between adjacent frames (e.g., party members)
    if frame and addonTable.lastHoveredFrame and frame ~= addonTable.lastHoveredFrame then
        return
    end
    
    addonTable.clickCastingTooltip:SetScript("OnUpdate", nil)
    if addonTable.clickCastingTooltip:IsShown() then
        addonTable.clickCastingTooltip:Hide()
    end
end

-- ============================================================================
-- Event Handlers
-- ============================================================================

-- Event handler for the tooltip when the modifier state changes
addonTable.clickCastingTooltip:SetScript("OnEvent", function(self, event, ...)
    if event == "MODIFIER_STATE_CHANGED" then
        if addonTable.lastHoveredFrame and addonTable.lastHoveredFrame:IsMouseOver() then
            clickToCastTooltipBuilder(addonTable.lastHoveredFrame)
        end
    end
end)

-- Register with Blizzard's tooltip processor
-- Note: Blizzard tooltip can't be refreshed on modifier change without duplicating content
-- The custom floating tooltip handles modifier changes instead
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, blizzardTooltipBuilder)

-- ============================================================================
-- Frame Scanning
-- ============================================================================

--- Scans all registered frame handlers and hooks their frames
local function scanAllFrames()
    addonTable.HandlerRegistry:ScanAll(clickToCastTooltipBuilder, clickToCastTooltipDestroyer)
end

-- Periodic scan frame (every 5 seconds)
local scanFrame = CreateFrame("Frame")
scanFrame:EnableMouse(false)
scanFrame:SetFrameStrata("TOOLTIP")
local scanInterval, elapsed = 5, 0

scanFrame:HookScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed >= scanInterval then
        elapsed = 0
        scanAllFrames()
    end
end)

-- Event-based scanning
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GROUP_ROSTER_UPDATE" 
        or event == "PLAYER_ENTERING_WORLD"
        or event == "RAID_ROSTER_UPDATE" then
        scanAllFrames()
    end
end)
