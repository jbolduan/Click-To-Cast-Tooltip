local addonName, addonTable = ...

-- ============================================================================
-- Core Initialization
-- Sets up shared tables, constants, and utility functions used across the addon
-- ============================================================================

-- Shared state tables
addonTable.hookedFrames = setmetatable({}, {__mode = "k"})  -- Weak table for hooked frames
addonTable.frameHandlers = {}  -- Registered frame handlers
addonTable.lastHoveredFrame = nil  -- Currently hovered frame reference

-- Anchor position mapping for tooltip placement
addonTable.anchorMap = {
    [1] = "TOPLEFT",    [2] = "TOP",    [3] = "TOPRIGHT",
    [4] = "LEFT",       [5] = "CENTER", [6] = "RIGHT",
    [7] = "BOTTOMLEFT", [8] = "BOTTOM", [9] = "BOTTOMRIGHT",
    [10] = "SCREEN"
}

-- Create the Blizzard tooltip reference
addonTable.blizzardToolTip = GameTooltip

-- Create the custom floating tooltip
addonTable.clickCastingTooltip = CreateFrame("GameTooltip", "ClickToCastCustomTooltip", UIParent, "GameTooltipTemplate")

-- Timer reference for frame clear scheduling
local clearTimer = nil

--- Schedules clearing the last hovered frame reference after mouse leaves
-- @param frame Frame: The frame that was just left
function addonTable.scheduleFrameClear(frame)
    if clearTimer then
        clearTimer:Cancel()
    end
    clearTimer = C_Timer.NewTimer(0.1, function()
        if frame and not frame:IsMouseOver() then
            addonTable.lastHoveredFrame = nil
        end
    end)
end

-- Frame handler initialization (placeholder for backward compatibility)
addonTable.frameHandler = {
    init = function()
        -- This can be used for any initialization logic
    end
}

--- Updates tooltip with click binding information
-- This function is called by both the Blizzard tooltip and custom tooltip
-- @param db table: Database settings
-- @param clickBindings table: Click binding profile info
-- @param tooltip GameTooltip: The tooltip frame to update
-- @param nonBlankLineCount table: Counter object with .value property
function addonTable.updateTooltip(db, clickBindings, tooltip, nonBlankLineCount)
    -- Guard against nil tooltip
    if not tooltip then
        return
    end
    
    local buttonColor = CreateColorFromHexString(db.buttonColor or "ffff0000")
    local actionColor = CreateColorFromHexString(db.actionColor or "ff00ff00")
    
    -- Track shown bindings to prevent duplicates
    local shownBindings = {}
    
    -- Get current modifier key state
    local isShiftKeyDown = IsShiftKeyDown()
    local isAltKeyDown = IsAltKeyDown()
    local isControlKeyDown = IsControlKeyDown()
    
    -- Show Blizzard bindings if enabled
    if db.showBlizzardBindings ~= false and clickBindings then
        for _, binding in ipairs(clickBindings) do
            -- Get modifier string from binding
            local modifier = C_ClickBindings.GetStringFromModifiers(binding.modifiers)
            
            -- Get action name based on binding type
            local actionName = tostring(binding.actionID)
            if binding.type == Enum.ClickBindingType.Interaction then
                if binding.actionID == Enum.ClickBindingInteraction.Target then
                    actionName = "Target"
                elseif binding.actionID == Enum.ClickBindingInteraction.OpenContextMenu then
                    actionName = "Open Context Menu"
                end
            elseif binding.type == Enum.ClickBindingType.Spell then
                -- Resolve spec-specific overrides
                local overrideID = binding.actionID
                if C_SpellBook and C_SpellBook.FindSpellOverrideByID then
                    overrideID = C_SpellBook.FindSpellOverrideByID(binding.actionID) or binding.actionID
                end
                
                if C_Spell and C_Spell.GetSpellInfo then
                    local spellInfo = C_Spell.GetSpellInfo(overrideID)
                    actionName = spellInfo and spellInfo.name or actionName
                end
                
                if actionName == tostring(binding.actionID) and C_Spell and C_Spell.GetSpellName then
                    actionName = C_Spell.GetSpellName(overrideID)
                end
            elseif binding.type == Enum.ClickBindingType.Macro then
                actionName = GetMacroInfo(binding.actionID) or "Macro"
            end
            
            -- Check if this binding should show based on current modifiers
            local show = false
            if (isShiftKeyDown and not isAltKeyDown and not isControlKeyDown) and (modifier == "SHIFT") then show = true
            elseif (not isShiftKeyDown and isAltKeyDown and not isControlKeyDown) and (modifier == "ALT") then show = true
            elseif (not isShiftKeyDown and not isAltKeyDown and isControlKeyDown) and (modifier == "CTRL") then show = true
            elseif (isShiftKeyDown and isAltKeyDown and not isControlKeyDown) and (modifier == "SHIFT-ALT" or modifier == "ALT-SHIFT") then show = true
            elseif (isShiftKeyDown and not isAltKeyDown and isControlKeyDown) and (modifier == "SHIFT-CTRL" or modifier == "CTRL-SHIFT") then show = true
            elseif (not isShiftKeyDown and isAltKeyDown and isControlKeyDown) and (modifier == "ALT-CTRL" or modifier == "CTRL-ALT") then show = true
            elseif (isShiftKeyDown and isAltKeyDown and isControlKeyDown) and (modifier == "SHIFT-ALT-CTRL" or modifier == "SHIFT-CTRL-ALT" or modifier == "ALT-SHIFT-CTRL" or modifier == "ALT-CTRL-SHIFT" or modifier == "CTRL-SHIFT-ALT" or modifier == "CTRL-ALT-SHIFT") then show = true
            elseif (not isAltKeyDown and not isControlKeyDown and not isShiftKeyDown) and (modifier == "") then show = true
            end
            
            if show then
                -- Create unique key for deduplication
                local bindingKey = binding.button .. "|" .. modifier .. "|" .. tostring(binding.actionID)
                if not shownBindings[bindingKey] then
                    shownBindings[bindingKey] = true
                    
                    local lineText = buttonColor:WrapTextInColorCode(binding.button) .. " - " .. actionColor:WrapTextInColorCode(actionName)
                    if lineText:match("%S") then
                        nonBlankLineCount.value = nonBlankLineCount.value + 1
                        tooltip:AddLine(lineText)
                    end
                end
            end
        end
    end
    
    -- Show Clique bindings if enabled and Clique is loaded
    ---@diagnostic disable-next-line: undefined-global
    if db.showCliqueBindings ~= false and Clique and Clique.db and Clique.db.profile and Clique.db.profile.bindings then
        ---@diagnostic disable-next-line: undefined-global
        local profile = Clique.db.profile
        
        for key, binding in pairs(profile.bindings) do
            if binding and binding.sets then
                local shouldShow = false
                local inCombat = InCombatLockdown()
                
                for setName, _ in pairs(binding.sets) do
                    if setName == "default" or setName == "hovercast" or setName == "global" then
                        shouldShow = true
                    elseif setName == "ooc" and not inCombat then
                        shouldShow = true
                    end
                end
                
                if shouldShow then
                    local actionName = binding.spell or binding.macro or binding.action or "Action"
                    if binding.type == "target" then
                        actionName = "Target"
                    elseif binding.type == "menu" then
                        actionName = "Open Menu"
                    end
                    
                    local buttonText = binding.key
                    if buttonText and type(buttonText) == "string" then
                        -- Check modifiers match current state
                        local lowerKey = buttonText:lower()
                        local hasShift = lowerKey:find("shift") ~= nil
                        local hasCtrl = lowerKey:find("ctrl") ~= nil or lowerKey:find("control") ~= nil
                        local hasAlt = lowerKey:find("alt") ~= nil
                        
                        local modifiersMatch = (hasShift == isShiftKeyDown) and 
                                              (hasCtrl == isControlKeyDown) and 
                                              (hasAlt == isAltKeyDown)
                        
                        if modifiersMatch then
                            local bindingKey = "clique|" .. buttonText .. "|" .. actionName
                            if not shownBindings[bindingKey] then
                                shownBindings[bindingKey] = true
                                
                                -- Format display text
                                local displayText = buttonText:gsub("BUTTON1", "Left Click")
                                displayText = displayText:gsub("BUTTON2", "Right Click")
                                displayText = displayText:gsub("BUTTON3", "Middle Click")
                                displayText = displayText:gsub("shift%-", "Shift-")
                                displayText = displayText:gsub("ctrl%-", "Ctrl-")
                                displayText = displayText:gsub("alt%-", "Alt-")
                                
                                local lineText = buttonColor:WrapTextInColorCode(displayText) .. " - " .. actionColor:WrapTextInColorCode(actionName)
                                if lineText:match("%S") then
                                    nonBlankLineCount.value = nonBlankLineCount.value + 1
                                    tooltip:AddLine(lineText)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
