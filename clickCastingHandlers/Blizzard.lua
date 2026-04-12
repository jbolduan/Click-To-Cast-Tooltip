local _, addonTable = ...

addonTable.clickBindingHandlers = addonTable.clickBindingHandlers or {}

function addonTable.clickBindingHandlers.IsBlizzardAvailable()
    return C_ClickBindings and C_ClickBindings.GetProfileInfo ~= nil
end

function addonTable.clickBindingHandlers.ProcessBlizzardBindings(context)
    local db = context.db
    local clickBindings = context.clickBindings

    if db.showBlizzardBindings == false or not clickBindings then
        return
    end

    for _, binding in ipairs(clickBindings) do
        local modifier = C_ClickBindings.GetStringFromModifiers(binding.modifiers)

        local actionName = tostring(binding.actionID)
        local actionBindingType = nil
        local spellIdentifier = nil

        if binding.type == Enum.ClickBindingType.Interaction then
            if binding.actionID == Enum.ClickBindingInteraction.Target then
                actionName = "Target"
            elseif binding.actionID == Enum.ClickBindingInteraction.OpenContextMenu then
                actionName = "Open Context Menu"
            end
        elseif binding.type == Enum.ClickBindingType.Spell then
            actionBindingType = "spell"
            local overrideID = binding.actionID
            if C_SpellBook and C_SpellBook.FindSpellOverrideByID then
                overrideID = C_SpellBook.FindSpellOverrideByID(binding.actionID) or binding.actionID
            end
            spellIdentifier = overrideID

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

        local show = false
        if (context.isShiftKeyDown and not context.isAltKeyDown and not context.isControlKeyDown) and (modifier == "SHIFT") then show = true
        elseif (not context.isShiftKeyDown and context.isAltKeyDown and not context.isControlKeyDown) and (modifier == "ALT") then show = true
        elseif (not context.isShiftKeyDown and not context.isAltKeyDown and context.isControlKeyDown) and (modifier == "CTRL") then show = true
        elseif (context.isShiftKeyDown and context.isAltKeyDown and not context.isControlKeyDown) and (modifier == "SHIFT-ALT" or modifier == "ALT-SHIFT") then show = true
        elseif (context.isShiftKeyDown and not context.isAltKeyDown and context.isControlKeyDown) and (modifier == "SHIFT-CTRL" or modifier == "CTRL-SHIFT") then show = true
        elseif (not context.isShiftKeyDown and context.isAltKeyDown and context.isControlKeyDown) and (modifier == "ALT-CTRL" or modifier == "CTRL-ALT") then show = true
        elseif (context.isShiftKeyDown and context.isAltKeyDown and context.isControlKeyDown) and (modifier == "SHIFT-ALT-CTRL" or modifier == "SHIFT-CTRL-ALT" or modifier == "ALT-SHIFT-CTRL" or modifier == "ALT-CTRL-SHIFT" or modifier == "CTRL-SHIFT-ALT" or modifier == "CTRL-ALT-SHIFT") then show = true
        elseif (not context.isAltKeyDown and not context.isControlKeyDown and not context.isShiftKeyDown) and (modifier == "") then show = true
        end

        if show then
            local bindingKey = binding.button .. "|" .. modifier .. "|" .. tostring(binding.actionID)
            if not context.shownBindings[bindingKey] then
                context.shownBindings[bindingKey] = true
                context.emitBinding(binding.button, actionName, actionBindingType, spellIdentifier)
            end
        end
    end
end
