local _, addonTable = ...

addonTable.clickBindingHandlers = addonTable.clickBindingHandlers or {}

function addonTable.clickBindingHandlers.IsCellAvailable()
    --@diagnostic disable-next-line: undefined-global
    return Cell and Cell.vars and type(Cell.vars.clickCastings) == "table"
end

local function decodeCellBindingKey(encodedKey)
    if type(encodedKey) ~= "string" or encodedKey == "" or encodedKey == "notBound" then
        return nil, nil
    end

    local modifierPrefix, keyToken = encodedKey:match("^(.*)type%-(.+)$")
    if keyToken then
        return modifierPrefix or "", keyToken
    end

    modifierPrefix, keyToken = encodedKey:match("^(.*)type(%d+)$")
    if keyToken then
        return modifierPrefix or "", keyToken
    end

    return nil, nil
end

local function extractCellModifierFlags(modifierPrefix, keyToken)
    local prefixLower = tostring(modifierPrefix or ""):lower()
    local token = tostring(keyToken or "")

    local hasAlt = prefixLower:find("alt", 1, true) ~= nil
    local hasCtrl = prefixLower:find("ctrl", 1, true) ~= nil or prefixLower:find("control", 1, true) ~= nil
    local hasShift = prefixLower:find("shift", 1, true) ~= nil
    local hasMeta = prefixLower:find("meta", 1, true) ~= nil

    local cleanedToken = token
    local changed = true
    while changed and cleanedToken ~= "" do
        changed = false
        local lower = cleanedToken:lower()

        if lower:find("^alt") then
            hasAlt = true
            cleanedToken = cleanedToken:sub(4)
            changed = true
        elseif lower:find("^control") then
            hasCtrl = true
            cleanedToken = cleanedToken:sub(8)
            changed = true
        elseif lower:find("^ctrl") then
            hasCtrl = true
            cleanedToken = cleanedToken:sub(5)
            changed = true
        elseif lower:find("^shift") then
            hasShift = true
            cleanedToken = cleanedToken:sub(6)
            changed = true
        elseif lower:find("^meta") then
            hasMeta = true
            cleanedToken = cleanedToken:sub(5)
            changed = true
        end

        if changed then
            cleanedToken = cleanedToken:gsub("^%-+", "")
        end
    end

    if cleanedToken == "" then
        cleanedToken = token
    end

    return hasAlt, hasCtrl, hasShift, hasMeta, cleanedToken
end

local function buildCellButtonDisplay(modifierPrefix, keyToken)
    local hasAlt, hasCtrl, hasShift, hasMeta, normalizedKey = extractCellModifierFlags(modifierPrefix, keyToken)

    local keyDisplay = normalizedKey
    local numericButton = tonumber(normalizedKey)
    if numericButton then
        if numericButton == 1 then
            keyDisplay = "LeftButton"
        elseif numericButton == 2 then
            keyDisplay = "RightButton"
        elseif numericButton == 3 then
            keyDisplay = "MiddleButton"
        else
            keyDisplay = "Button" .. numericButton
        end
    else
        local upperKey = tostring(normalizedKey):upper()
        if upperKey == "SCROLLUP" then
            keyDisplay = "MouseWheelUp"
        elseif upperKey == "SCROLLDOWN" then
            keyDisplay = "MouseWheelDown"
        else
            local buttonNumber = upperKey:match("BUTTON(%d+)")
            if buttonNumber then
                local buttonIndex = tonumber(buttonNumber)
                if buttonIndex == 1 then
                    keyDisplay = "LeftButton"
                elseif buttonIndex == 2 then
                    keyDisplay = "RightButton"
                elseif buttonIndex == 3 then
                    keyDisplay = "MiddleButton"
                else
                    keyDisplay = "Button" .. buttonNumber
                end
            else
                keyDisplay = tostring(normalizedKey)
            end
        end
    end

    return keyDisplay, hasAlt, hasCtrl, hasShift, hasMeta
end

local function resolveCellAction(bindingType, bindingAction)
    local bindingTypeText = tostring(bindingType or "")

    if bindingTypeText == "spell" then
        local spellIdentifier = bindingAction
        local spellID = nil

        if type(bindingAction) == "number" then
            spellID = bindingAction
        elseif type(bindingAction) == "string" then
            local spellIDText = bindingAction:match("^(%d+):%d+$") or bindingAction:match("^(%d+)$")
            spellID = spellIDText and tonumber(spellIDText) or nil
        end

        if spellID then
            spellIdentifier = spellID
        end

        local actionName = tostring(bindingAction or "Spell")
        if spellID and C_Spell and C_Spell.GetSpellInfo then
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            if spellInfo and spellInfo.name then
                actionName = spellInfo.name
            end
        end

        return actionName, "spell", spellIdentifier
    end

    if bindingTypeText == "macro" then
        return tostring(bindingAction or "Macro"), nil, nil
    end

    if bindingTypeText == "custom" then
        return "Custom Macro", nil, nil
    end

    if bindingTypeText == "item" then
        local itemSlot = tonumber(bindingAction)
        if itemSlot then
            local itemLink = GetInventoryItemLink("player", itemSlot)
            if itemLink then
                return itemLink, nil, nil
            end
        end
        return tostring(bindingAction or "Item"), nil, nil
    end

    local generalActions = {
        target = "Target",
        focus = "Focus",
        assist = "Assist",
        menu = "Open Menu",
        tooglemenu = "Toggle Menu",
        togglemenu = "Toggle Menu",
        togglemenu_nocombat = "Toggle Menu (No Combat)",
    }

    local mappedAction = generalActions[bindingTypeText]
    return mappedAction or bindingTypeText, nil, nil
end

function addonTable.clickBindingHandlers.ProcessCellBindings(context)
    local db = context.db

    --@diagnostic disable-next-line: undefined-global
    if db.showCellBindings == false or not (Cell and Cell.vars and type(Cell.vars.clickCastings) == "table") then
        return
    end

    --@diagnostic disable-next-line: undefined-global
    local cellClickCastings = Cell.vars.clickCastings
    --@diagnostic disable-next-line: undefined-global
    local cellSpecID = Cell.vars.playerSpecID
    local useCommon = cellClickCastings.useCommon == true
    local activeCellBindings = nil

    if useCommon and type(cellClickCastings.common) == "table" then
        activeCellBindings = cellClickCastings.common
    elseif cellSpecID and type(cellClickCastings[cellSpecID]) == "table" then
        activeCellBindings = cellClickCastings[cellSpecID]
    end

    if not activeCellBindings then
        return
    end

    for _, binding in pairs(activeCellBindings) do
        if type(binding) == "table" then
            local encodedKey = binding[1]
            local bindingType = binding[2]
            local bindingAction = binding[3]

            local modifierPrefix, keyToken = decodeCellBindingKey(encodedKey)
            if modifierPrefix and keyToken and bindingType then
                local displayButton, hasAlt, hasCtrl, hasShift, hasMeta = buildCellButtonDisplay(modifierPrefix, keyToken)

                local modifiersMatch = (hasShift == context.isShiftKeyDown)
                    and (hasCtrl == context.isControlKeyDown)
                    and (hasAlt == context.isAltKeyDown)
                    and (hasMeta == false)

                if modifiersMatch then
                    local actionName, actionBindingType, spellIdentifier = resolveCellAction(bindingType, bindingAction)
                    local dedupeKey = "cell|" .. tostring(encodedKey) .. "|" .. tostring(bindingType) .. "|" .. tostring(bindingAction)

                    if actionName and actionName ~= "" and not context.shownBindings[dedupeKey] then
                        context.shownBindings[dedupeKey] = true
                        context.emitBinding(displayButton, actionName, actionBindingType, spellIdentifier)
                    end
                end
            end
        end
    end
end
