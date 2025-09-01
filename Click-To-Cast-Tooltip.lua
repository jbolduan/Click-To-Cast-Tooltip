local addonName, addonTable = ...

-- Setup logic for adding lines to the Blizzard tooltip
local blizzardTooltip = CreateFrame("GameTooltip", "BlizzardTooltip", UIParent, "GameTooltipTemplate")
blizzardTooltip:RegisterEvent("MODIFIER_STATE_CHANGED")

-- Setup custom tooltip that will be shown at the mouse
local clickToCastTooltip = CreateFrame("GameTooltip", "ClickToCastTooltip", UIParent, "GameTooltipTemplate, BackdropTemplate")

clickToCastTooltip:SetFrameStrata("TOOLTIP")
clickToCastTooltip:RegisterEvent("MODIFIER_STATE_CHANGED")

local anchorMap = {
    [1] = "TOPLEFT",
    [2] = "TOP",
    [3] = "TOPRIGHT",
    [4] = "LEFT",
    [5] = "CENTER",
    [6] = "RIGHT",
    [7] = "BOTTOMLEFT",
    [8] = "BOTTOM",
    [9] = "BOTTOMRIGHT"
}

local lastHoveredFrame = nil

-- Adds lines to a tooltip based on click bindings and settings.
-- @param db table: Addon settings table
-- @param clickBindings table: List of click binding tables
-- @param tooltip GameTooltip: Tooltip frame to add lines to
-- @param nonBlankLineCount table: Table with .value for counting non-blank lines
-- @return nil
local function updateTooltip(db, clickBindings, tooltip, nonBlankLineCount)
    for _, binding in ipairs(clickBindings) do
        local modifier = C_ClickBindings.GetStringFromModifiers(binding.modifiers)
        local actionName = tostring(binding.actionID)
        if binding.type == Enum.ClickBindingType.Interaction then
            if binding.actionID == Enum.ClickBindingInteraction.Target then
                actionName = "Target"
            elseif binding.actionID == Enum.ClickBindingInteraction.OpenContextMenu then
                actionName = "Open Context Menu"
            end
        elseif binding.type == Enum.ClickBindingType.Spell then
            actionName = C_Spell.GetSpellName(binding.actionID)
        elseif binding.type == Enum.ClickBindingType.Macro then
            actionName = GetMacroInfo(binding.actionID)
        end
        local buttonColor = CreateColorFromHexString(db.buttonColor)
        local actionColor = CreateColorFromHexString(db.actionColor)
        local show = false
        local isShiftKeyDown = IsShiftKeyDown()
        local isAltKeyDown = IsAltKeyDown()
        local isControlKeyDown = IsControlKeyDown()
        if (isShiftKeyDown and isAltKeyDown and isControlKeyDown) and (modifier == "ALT-SHIFT-CTRL") then show = true
        elseif (isShiftKeyDown and isAltKeyDown) and (modifier == "ALT-SHIFT") and not isControlKeyDown then show = true
        elseif (isControlKeyDown and isAltKeyDown) and (modifier == "ALT-CTRL") and not isShiftKeyDown then show = true
        elseif (isShiftKeyDown and isControlKeyDown) and (modifier == "SHIFT-CTRL") and not isAltKeyDown then show = true
        elseif isShiftKeyDown and (modifier == "SHIFT") and not (isAltKeyDown or isControlKeyDown) then show = true
        elseif isAltKeyDown and (modifier == "ALT") and not (isShiftKeyDown or isControlKeyDown) then show = true
        elseif isControlKeyDown and (modifier == "CTRL") and not (isShiftKeyDown or isAltKeyDown) then show = true
        elseif (not isAltKeyDown and not isControlKeyDown and not isShiftKeyDown) and (modifier == "") then show = true
        end
        if show then
            local lineText = buttonColor:WrapTextInColorCode(binding.button) .. " - " .. actionColor:WrapTextInColorCode(actionName)
            if lineText:match("%S") then -- contains non-whitespace
                nonBlankLineCount.value = nonBlankLineCount.value + 1
                tooltip:AddLine(lineText)
            end
        end
    end
end

-- Builds and displays the custom tooltip at the mouse cursor.
-- @param frame Frame: The unit frame the mouse is over
local function clickToCastTooltipBuilder(frame)
    local db = ClickToCastTooltip and ClickToCastTooltip.db and ClickToCastTooltip.db.global
    local specID = GetSpecializationInfo(GetSpecialization())
    if not (db and type(db.showCustomTooltip) == "boolean" and db.showCustomTooltip) then
        clickToCastTooltip:Hide()
        return
    end
    if specID and db and db["specToggle_" .. specID] == false then
        clickToCastTooltip:Hide()
        return
    end
    local clickBindings = C_ClickBindings.GetProfileInfo()
    clickToCastTooltip:ClearLines()
    clickToCastTooltip:SetOwner(UIParent, "ANCHOR_NONE")

    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local anchor = "BOTTOMRIGHT"
    if db and type(db.tooltipAnchor) == "number" then
        anchor = anchorMap[db.tooltipAnchor] or "BOTTOMRIGHT"
    elseif db and type(db.tooltipAnchor) == "string" then
        anchor = db.tooltipAnchor
    end
    clickToCastTooltip:SetPoint(anchor, UIParent, "BOTTOMLEFT", x / scale, y / scale)
    local nonBlankLineCount = {value = 0}
    
    updateTooltip(db, clickBindings, clickToCastTooltip, nonBlankLineCount)
    if nonBlankLineCount.value > 0 then
        clickToCastTooltip:Show()
        clickToCastTooltip:SetScript("OnUpdate", function(self)
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            self:ClearAllPoints()
            self:SetPoint(anchor, UIParent, "BOTTOMLEFT", x / scale, y / scale)
            self:SetAlpha(db.tooltipTransparency)
        end)
    else
        clickToCastTooltip:Hide()
    end
end

-- Builds and displays the Blizzard tooltip with click binding info.
-- @param tooltip GameTooltip: The Blizzard tooltip frame
local function blizzardTooltipBuilder(tooltip)
    -- Setup logic for adding lines to the Blizzard tooltip
    local db = ClickToCastTooltip and ClickToCastTooltip.db and ClickToCastTooltip.db.global

    if (db and db.showTooltip == false) then
        return
    end

    local clickBindings = C_ClickBindings.GetProfileInfo()
    local nonBlankLineCount = {value = 0}

    if( db and type(db.showNewLineTop) == "boolean" and db.showNewLineTop) then
        tooltip:AddLine(" ")
    end

    if( db and type(db.showHeader) == "boolean" and db.showHeader) then
        local dividerColor = CreateColorFromHexString(db.dividerColor)
        local headerLine = dividerColor:WrapTextInColorCode("--------------------")
        tooltip:AddLine(headerLine)
    end

    updateTooltip(db, clickBindings, tooltip, nonBlankLineCount)

    if( db and type(db.showFooter) == "boolean" and db.showFooter) then
        local dividerColor = CreateColorFromHexString(db.dividerColor)
        local footerLine = dividerColor:WrapTextInColorCode("--------------------")
        tooltip:AddLine(footerLine)
    end

    if( db and type(db.showNewLineBottom) == "boolean" and db.showNewLineBottom) then
        tooltip:AddLine(" ")
    end
end

-- Hides and cleans up the custom tooltip.
-- @param frame Frame: The unit frame the mouse is leaving
local function clickToCastTooltipDestroyer(frame)
    -- Clear OnUpdate before hiding to prevent recursive Hide calls
    clickToCastTooltip:SetScript("OnUpdate", nil)
    if clickToCastTooltip:IsShown() then
        clickToCastTooltip:Hide()
    end
end

local unitFramePrefixes = {
    "PlayerFrame",
    "TargetFrame",
    "FocusFrame",
    "PetFrame",
    "PartyMemberFrame",
    "Boss",
    "ArenaEnemyFrame",
    --"CompactRaidFrame",
    -- "SUFUnit",
    -- "PitBull4_Frames_",
    -- "Grid2LayoutHeader",
    -- "VuhDoPanel",
    -- "oUF_"
}

-- Checks if a frame name matches known unit frame prefixes.
-- @param name string: The frame name to check
-- @return boolean: True if the name matches a unit frame
local function isUnitFrameName(name)
    if not name then return false end
    for _, prefix in ipairs(unitFramePrefixes) do
        if name:find(prefix, 1, true) == 1 then
            return true
        end
    end
    return false
end

local hookedFrames = setmetatable({}, {__mode = "k"})
-- Scans all frames and hooks OnEnter/OnLeave for Blizzard unit frames.
local function scanAndHookUnitFrames()
    local frame = EnumerateFrames()
    while frame do
        if frame and frame.GetObjectType and type(frame.GetName) == "function" and not hookedFrames[frame] and frame.HookScript then
            local success, name = pcall(frame.GetName, frame)
            if success and name and isUnitFrameName(name) then
                frame:HookScript("OnEnter", function()
                    lastHoveredFrame = frame
                    clickToCastTooltipBuilder(frame)
                end)
                frame:HookScript("OnLeave", function()
                    clickToCastTooltipDestroyer(frame)
                    if lastHoveredFrame == frame then
                        lastHoveredFrame = nil
                    end
                end)
                hookedFrames[frame] = true
            end
        end
        frame = EnumerateFrames(frame)
    end
end

-- Hook into explicit ElvUI frames if ElvUI is detected
local elvUIUnitFrames = {
    "ElvUF_Player",
    "ElvUF_Target",
    "ElvUF_Focus",
    "ElvUF_Pet"
}

-- Scans and hooks OnEnter/OnLeave for ElvUI unit frames if ElvUI is loaded.
local function scanAndHookElvUIUnitFrames()
    ---@diagnostic disable-next-line: undefined-global
    if type(ElvUI) == "table" then

        -- Hook specific ElvUI unit frames
        for _, frameName in ipairs(elvUIUnitFrames) do
            local frame = _G[frameName]
            if frame and frame.HookScript and not hookedFrames[frame] then
                frame:HookScript("OnEnter", function()
                    lastHoveredFrame = frame
                    clickToCastTooltipBuilder(frame)
                end)
                frame:HookScript("OnLeave", function()
                    clickToCastTooltipDestroyer(frame)
                    if lastHoveredFrame == frame then
                        lastHoveredFrame = nil
                    end
                end)
                hookedFrames[frame] = true
            end
        end

        -- Party frames
        for group = 1, 4 do
            for btn = 1, 5 do
                local frame = _G["ElvUF_PartyGroup"..group.."UnitButton"..btn]
                if frame and frame.HookScript and not hookedFrames[frame] then
                    frame:HookScript("OnEnter", function(self)
                        lastHoveredFrame = frame
                        clickToCastTooltipBuilder(self)
                    end)
                    frame:HookScript("OnLeave", function(self)
                        clickToCastTooltipDestroyer(self)
                        if lastHoveredFrame == frame then
                            lastHoveredFrame = nil
                        end
                    end)
                    hookedFrames[frame] = true
                end
            end
        end

        -- Raid frames
        for raid = 1, 3 do
            for group = 1, 8 do
                for btn = 1, 5 do
                    local frame = _G["ElvUF_Raid" .. raid .. "Group"..group.."UnitButton"..btn]
                    if frame and frame.HookScript and not hookedFrames[frame] then
                        frame:HookScript("OnEnter", function(self)
                            lastHoveredFrame = frame
                            clickToCastTooltipBuilder(self)
                        end)
                        frame:HookScript("OnLeave", function(self)
                            clickToCastTooltipDestroyer(self)
                            if lastHoveredFrame == frame then
                                lastHoveredFrame = nil
                            end
                        end)
                        hookedFrames[frame] = true
                    end
                end
            end
        end
    end
end

-- Event handler for the tooltip when the modifier state changes
clickToCastTooltip:SetScript("OnEvent", function(self, event, ...)
    if event == "MODIFIER_STATE_CHANGED" then
        if lastHoveredFrame and lastHoveredFrame:IsMouseOver() then
            clickToCastTooltipBuilder(lastHoveredFrame)
        end
    end
end)

blizzardTooltip:SetScript("OnEvent", function(self, event, arg, ...)
    if blizzardTooltip:IsShown() and event == "MODIFIER_STATE_CHANGED" then
        blizzardTooltipBuilder()
    end
end)


TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, blizzardTooltipBuilder)

local scanFrame = CreateFrame("Frame")
scanFrame:EnableMouse(false)
scanFrame:SetFrameStrata("TOOLTIP")
local scanInterval, elapsed = 5, 0 -- seconds
scanFrame:HookScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed >= scanInterval then
        elapsed = 0
        scanAndHookUnitFrames()
        scanAndHookElvUIUnitFrames()
    end
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GROUP_ROSTER_UPDATE" 
                or event == "PLAYER_ENTERING_WORLD"
                or event == "RAID_ROSTER_UPDATE" then
        scanAndHookUnitFrames()
        scanAndHookElvUIUnitFrames()
    end
end)