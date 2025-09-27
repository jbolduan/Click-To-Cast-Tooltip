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
    local blizzardBindingsAdded = false
    
    -- Process Blizzard/WoW native bindings if enabled
    if db.showBlizzardBindings ~= false then
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
                blizzardBindingsAdded = true
            end
        end
        end
    end

    -- Add Clique bindings if available and enabled (mimicking C_ClickBindings workflow)
    ---@diagnostic disable-next-line: undefined-global
    if db.showCliqueBindings ~= false and Clique and Clique.db and Clique.db.profile and Clique.db.profile.bindings then
        ---@diagnostic disable-next-line: undefined-global
        local profile = Clique.db.profile
        local cliqueBindings = {}
        
        -- Convert Clique bindings to a format similar to C_ClickBindings
        for key, binding in pairs(profile.bindings) do
            if binding and binding.sets then
                -- Check if binding should be active (similar to modifier key logic)
                local shouldShow = false
                local inCombat = InCombatLockdown()
                
                for setName, _ in pairs(binding.sets) do
                    if setName == "default" then
                        shouldShow = true
                    elseif setName == "ooc" and not inCombat then
                        shouldShow = true
                    elseif setName == "hovercast" then
                        shouldShow = true
                    elseif setName == "global" then
                        shouldShow = true
                    end
                end
                
                if shouldShow then
                    table.insert(cliqueBindings, {
                        key = key,
                        binding = binding
                    })
                end
            end
        end
        
        -- Process Clique bindings similar to how we process C_ClickBindings
        local cliqueBindingsAdded = false
        for _, cliqueEntry in ipairs(cliqueBindings) do
            local binding = cliqueEntry.binding
            local bindingKey = cliqueEntry.key  -- This is the array index, not the actual key
            
            -- Extract action name (spell, macro, or action)
            local actionName = "Unknown"
            if binding.spell then
                actionName = binding.spell
            elseif binding.macro then
                actionName = "Macro: " .. (binding.macro or "Unknown")
            elseif binding.action then
                actionName = binding.action
            elseif binding.type == "target" then
                actionName = "Target"
            elseif binding.type == "menu" then
                actionName = "Open Menu"
            end
            
            -- Use the actual key from the binding, not the array index
            local buttonText = binding.key
            if buttonText and type(buttonText) == "string" then
                -- Parse modifier keys from the Clique key string (case insensitive)
                local lowerKey = buttonText:lower()
                local hasShift = lowerKey:find("shift") ~= nil
                local hasCtrl = lowerKey:find("ctrl") ~= nil or lowerKey:find("control") ~= nil
                local hasAlt = lowerKey:find("alt") ~= nil
                
                -- Check current modifier state
                local isShiftKeyDown = IsShiftKeyDown()
                local isAltKeyDown = IsAltKeyDown()
                local isControlKeyDown = IsControlKeyDown()
                
                -- Apply same filtering logic as WoW native bindings
                local show = false
                if (isShiftKeyDown and isAltKeyDown and isControlKeyDown) and (hasShift and hasAlt and hasCtrl) then 
                    show = true
                elseif (isShiftKeyDown and isAltKeyDown) and (hasShift and hasAlt and not hasCtrl) and not isControlKeyDown then 
                    show = true
                elseif (isControlKeyDown and isAltKeyDown) and (hasAlt and hasCtrl and not hasShift) and not isShiftKeyDown then 
                    show = true
                elseif (isShiftKeyDown and isControlKeyDown) and (hasShift and hasCtrl and not hasAlt) and not isAltKeyDown then 
                    show = true
                elseif isShiftKeyDown and (hasShift and not hasAlt and not hasCtrl) and not (isAltKeyDown or isControlKeyDown) then 
                    show = true
                elseif isAltKeyDown and (hasAlt and not hasShift and not hasCtrl) and not (isShiftKeyDown or isControlKeyDown) then 
                    show = true
                elseif isControlKeyDown and (hasCtrl and not hasShift and not hasAlt) and not (isShiftKeyDown or isAltKeyDown) then 
                    show = true
                elseif (not isAltKeyDown and not isControlKeyDown and not isShiftKeyDown) and (not hasShift and not hasAlt and not hasCtrl) then 
                    show = true
                end
                
                if show then
                    -- Add separator before first Clique binding if we have both types
                    if not cliqueBindingsAdded and blizzardBindingsAdded then
                        local dividerColor = CreateColorFromHexString(db.dividerColor or "ffffffff")
                        local separatorLine = dividerColor:WrapTextInColorCode("--- Clique ---")
                        tooltip:AddLine(separatorLine)
                        nonBlankLineCount.value = nonBlankLineCount.value + 1
                    end
                    
                    -- Convert Clique key format to readable format
                    local displayText = buttonText:gsub("BUTTON1", "Left Click")
                    displayText = displayText:gsub("BUTTON2", "Right Click")
                    displayText = displayText:gsub("BUTTON3", "Middle Click")
                    displayText = displayText:gsub("BUTTON4", "Button4")
                    displayText = displayText:gsub("BUTTON5", "Button5")
                    
                    -- Handle modifiers in the key for display
                    displayText = displayText:gsub("shift%-", "Shift-")
                    displayText = displayText:gsub("ctrl%-", "Ctrl-")
                    displayText = displayText:gsub("alt%-", "Alt-")
                    
                    local buttonColor = CreateColorFromHexString(db.buttonColor)
                    local actionColor = CreateColorFromHexString(db.actionColor)
                    local lineText = buttonColor:WrapTextInColorCode(displayText) .. " - " .. actionColor:WrapTextInColorCode(actionName)
                    
                    if lineText:match("%S") then -- contains non-whitespace
                        nonBlankLineCount.value = nonBlankLineCount.value + 1
                        tooltip:AddLine(lineText)
                        cliqueBindingsAdded = true
                    end
                end
            end
        end
    end
end

-- Initialize ElvUI tooltip styling
local function initializeElvUITooltip()
    ---@diagnostic disable-next-line: undefined-global
    if ElvUI and ElvUI[1] then
        ---@diagnostic disable-next-line: undefined-global
        local E, L, V, P, G = unpack(ElvUI)
        local TT = E:GetModule("Tooltip")
        TT:SetStyle(clickToCastTooltip)
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
        initializeElvUITooltip()
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

--#region Blizzard Frames

local blizzardFrames = {
    "PlayerFrame",
    "TargetFrame",
    "TargetFrameToT",
    "FocusFrame",
    "FocusFrameToT",
    "PetFrame",
    -- "PitBull4_Frames_",
    -- "oUF_"
}

local hookedFrames = setmetatable({}, {__mode = "k"})
-- Scans all frames and hooks OnEnter/OnLeave for Blizzard unit frames.
local function scanAndHookUnitFrames()
    -- Iterate through static Blizzard Frames
    for _, frameName in ipairs(blizzardFrames) do
        local frame = _G[frameName]
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

    -- Party Frames
    local partyFrame = _G["PartyFrame"]
    if partyFrame then
        for memberFrame in partyFrame.PartyMemberFramePool:EnumerateActive() do
            if memberFrame and memberFrame.HookScript and not hookedFrames[memberFrame] then
                memberFrame:HookScript("OnEnter", function(self)
                    lastHoveredFrame = memberFrame
                    clickToCastTooltipBuilder(self)
                end)
                memberFrame:HookScript("OnLeave", function(self)
                    clickToCastTooltipDestroyer(self)
                    if lastHoveredFrame == memberFrame then
                        lastHoveredFrame = nil
                    end
                end)
                hookedFrames[memberFrame] = true
            end
        end
    end

    -- Compact Party Frames
    for i = 1, 5 do
        local frame = _G["CompactPartyFrameMember" .. i]
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

    -- Boss Frames
    for i = 1, 10 do
        local frame = _G["Boss" .. i .. "TargetFrame"]
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

    -- Compact Raid Frames
    for i = 1, 8 do
        for j = 1, 40 do
            local frame = _G["CompactRaidGroup" .. i .. "Member" .. j]
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

    -- Enemy Arena Frames
    -- I don't know if this will work and have not tested.
    for i = 1, 5 do
        local frame = _G["ArenaEnemyFrame" .. i]
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
end

--#endregion

--#region ElvUI Frames

-- Hook into explicit ElvUI frames if ElvUI is detected
local elvUIUnitFrames = {
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

        -- Raid pet frames

        for i = 1, 9 do 
            local frame = _G["ElvUF_RaidpetGroup1UnitButton" .. i]
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

        -- Arena Frames
        for i = 1, 5 do
            local frame = _G["ElvUF_Arena" .. i]
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

        -- Boss Frames
        for i = 1, 8 do
            local frame = _G["ElvUF_Boss" .. i]
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

--#endregion

--#region Cell Frames

local cellFrames = {
    "CellSoloFramePet",
    "CellSoloFramePlayer"
}

local function scanAndHookCellFrames()
    
    ---@diagnostic disable-next-line: undefined-global
    if type(Cell) == "table" then

        -- Static frame names
        for _, frameName in ipairs(cellFrames) do
            local frame = _G[frameName]
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

        -- Arena Pet Frames
        for i = 1, 3 do
            local frame = _G["CellArenaPet" .. i]
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

        -- NPC Frames
        for i = 1, 8 do
            local frame = _G["CellNPCFrameButton" .. i]
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

        -- Party Frames
        for i = 1, 5 do
            local frame = _G["CellPartyFrameHeaderUnitButton" .. i]
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

        -- Party Pet Frames
        for i = 1, 8 do
            local frame = _G["CellPartyFrameUnitButton" .. i .. "Pet"]
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

        -- Pet Frames Separate
        for i = 1, 20 do
            local frame = _G["CellPetFrameHeaderUnitButton" .. i]
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

        -- Quick Assist Frames
        for i = 1, 40 do
            local frame = _G["CellQuickAssistHeaderUnitButton" .. i]
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

        -- Raid0 Frames
        for i = 1, 40 do
            local frame = _G["CellRaidFrameHeader0UnitButton" .. i]
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

        -- Raid Frames
        for raid = 1, 8 do
            for i = 1, 5 do
                local frame = _G["CellRaidFrameHeader" .. raid .. "UnitButton" .. i]
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

        -- Cell Spotlight Unit Frames
        for i = 1, 15 do
            local frame = _G["CellSpotlightFrameUnitButton" .. i]
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

local cellUnitFrames = {
    "CUF_Player",
    "CUF_Focus",
    "CUF_Pet",
    "CUF_Target",
    "CUF_TargetTarget"
}

local function scanAndHookCellUnitFrames()
    ---@diagnostic disable-next-line: undefined-global
    if type(CUF) == "table" then
        for _, frameName in ipairs(cellUnitFrames) do
            local frame = _G[frameName]
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

        for i = 1, 10 do
            local frame = _G["CUF_Boss" .. i]
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

--#endregion

--#region Grid2 Frames

local function scanAndHookGrid2UnitFrames()
    ---@diagnostic disable-next-line: undefined-global
    for i = 1, 8 do
        for j = 1, 5 do
            local frame = _G["Grid2LayoutHeader" .. i .. "UnitButton" .. j]
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

--#endregion

--#region Shadowed Unit Frames

local sUF = {
    "SUFUnitplayer",
    "SUFUnitpet",
    "SUFUnittarget",
    "SUFUnittargettarget",
    "SUFUnittargettargettarget",
    "SUFUnitfocus",
    "SUFUnitfocustarget",
    "SUFHeadermainassistUnitButton1",
    "SUFHeadermaintankUnitButton1"
}

local function scanAndHookShadowedUnitFrames()
    ---@diagnostic disable-next-line: undefined-global
    if type(ShadowedUFDB) == "table" then
        for _, frameName in ipairs(sUF) do
            local frame = _G[frameName]
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

        -- Party Frames
        for i = 1, 5 do
            local frame = _G["SUFHeaderpartyUnitButton" .. i]
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

        -- Raid Frames
        for i = 1, 40 do
            local frame = _G["SUFHeaderraidUnitButton" .. i]
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

--#endregion

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
        scanAndHookCellFrames()
        scanAndHookCellUnitFrames()
        scanAndHookGrid2UnitFrames()
        scanAndHookShadowedUnitFrames()
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
        scanAndHookCellFrames()
        scanAndHookCellUnitFrames()
        scanAndHookGrid2UnitFrames()
        scanAndHookShadowedUnitFrames()
    end
end)
