local _, addonTable = ...

addonTable.clickBindingHandlers = addonTable.clickBindingHandlers or {}

function addonTable.clickBindingHandlers.IsVuhDoAvailable()
    return type(_G["VuhDo"]) == "table" or type(_G["VUHDO_CONFIG"]) == "table" or type(_G["VUHDO_PANEL_SETUP"]) == "table"
end

local function normalizeVuhDoAction(action)
    if type(action) == "number" then
        return tostring(action)
    end

    if type(action) == "string" then
        local clean = action:gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" then
            return clean
        end
    end

    return "Action"
end

local function parseVuhDoModifierFlags(modifierPrefix, entryKey)
    local hasAlt = false
    local hasCtrl = false
    local hasShift = false

    local combined = tostring(modifierPrefix or "") .. tostring(entryKey or "")
    local lower = combined:lower()

    hasAlt = lower:find("alt", 1, true) ~= nil
    hasCtrl = lower:find("ctrl", 1, true) ~= nil or lower:find("control", 1, true) ~= nil
    hasShift = lower:find("shift", 1, true) ~= nil

    return hasAlt, hasCtrl, hasShift
end

local function normalizeVuhDoButtonToken(buttonToken, entryKey)
    local token = tostring(buttonToken or entryKey or "")
    local lower = token:lower()

    if lower == "" then
        return ""
    end

    if lower == "1" or lower == "button1" or lower == "leftbutton" then
        return "LeftButton"
    elseif lower == "2" or lower == "button2" or lower == "rightbutton" then
        return "RightButton"
    elseif lower == "3" or lower == "button3" or lower == "middlebutton" then
        return "MiddleButton"
    elseif lower == "4" or lower == "button4" then
        return "Button4"
    elseif lower == "5" or lower == "button5" then
        return "Button5"
    elseif lower == "-w1" or lower == "mousewheelup" or lower == "scrollup" or lower == "wheelup" then
        return "MouseWheelUp"
    elseif lower == "-w2" or lower == "mousewheeldown" or lower == "scrolldown" or lower == "wheeldown" then
        return "MouseWheelDown"
    elseif lower == "-w3" or lower == "-w4" then
        return "MouseWheelUp"
    elseif lower == "-w5" or lower == "-w6" then
        return "MouseWheelDown"
    end

    return token
end

local function resolveVuhDoAction(actionValue)
    if actionValue == nil then
        return "Action", nil, nil
    end

    if type(actionValue) == "number" then
        local spellName = nil
        if C_Spell and C_Spell.GetSpellInfo then
            local spellInfo = C_Spell.GetSpellInfo(actionValue)
            spellName = spellInfo and spellInfo.name or nil
        end

        return spellName or tostring(actionValue), "spell", actionValue
    end

    local actionText = tostring(actionValue)
    if actionText == "" then
        return "Action", nil, nil
    end

    local lower = actionText:lower()
    local actionMap = {
        target = "Target",
        focus = "Focus",
        assist = "Assist",
        menu = "Open Menu",
        dropdown = "Open Menu",
        togglemenu = "Toggle Menu",
        tooglemenu = "Toggle Menu",
        toast = "Toast",
    }

    if actionMap[lower] then
        return actionMap[lower], nil, nil
    end

    local spellID = actionText:match("^(%d+)$") or actionText:match("^(%d+):%d+$")
    if spellID then
        local numericSpellID = tonumber(spellID)
        local spellName = nil
        if C_Spell and C_Spell.GetSpellInfo then
            local spellInfo = C_Spell.GetSpellInfo(numericSpellID)
            spellName = spellInfo and spellInfo.name or nil
        end
        return spellName or actionText, "spell", numericSpellID
    end

    return normalizeVuhDoAction(actionText), nil, nil
end

local function addVuhDoBindingSet(bindingSet, context)
    if type(bindingSet) ~= "table" then
        return
    end

    for bindingKey, bindingInfo in pairs(bindingSet) do
        if type(bindingInfo) == "table" then
            local actionValue = bindingInfo[3]
            local buttonToken = bindingInfo[2] or bindingKey
            local modifierPrefix = bindingInfo[1] or ""
            local buttonText = normalizeVuhDoButtonToken(buttonToken, bindingKey)

            if buttonText ~= "" and actionValue ~= nil and tostring(actionValue) ~= "" then
                local hasAlt, hasCtrl, hasShift = parseVuhDoModifierFlags(modifierPrefix, bindingKey)
                local modifiersMatch = (hasShift == context.isShiftKeyDown)
                    and (hasCtrl == context.isControlKeyDown)
                    and (hasAlt == context.isAltKeyDown)

                if modifiersMatch then
                    local actionName, actionType, spellIdentifier = resolveVuhDoAction(actionValue)
                    local bindingID = "vuhdo|" .. buttonText .. "|" .. actionName
                    if not context.shownBindings[bindingID] then
                        context.shownBindings[bindingID] = true
                        context.emitBinding(buttonText, actionName, actionType, spellIdentifier)
                    end
                end
            end
        end
    end
end

local function isVuhDoFrame(frame)
    if not frame then
        return false
    end

    local frameName = frame:GetName() or ""
    return frameName:match("^Vd%d+H%d+$")
        or frameName:match("^Vd%d+H%d+Tg$")
        or frameName:match("^Vd%d+H%d+Tot$")
end

function addonTable.clickBindingHandlers.ProcessVuhDoBindings(context)
    local db = context.db
    if db.showVuhDoBindings == false or not addonTable.clickBindingHandlers.IsVuhDoAvailable() then
        return
    end

    if not isVuhDoFrame(context.hoveredFrame) then
        return
    end

    local spellAssignments = _G["VUHDO_SPELL_ASSIGNMENTS"]
    local hostileAssignments = _G["VUHDO_HOSTILE_SPELL_ASSIGNMENTS"]
    local keyboardAssignments = _G["VUHDO_SPELLS_KEYBOARD"]

    addVuhDoBindingSet(spellAssignments, context)
    addVuhDoBindingSet(hostileAssignments, context)

    if type(keyboardAssignments) == "table" then
        addVuhDoBindingSet(keyboardAssignments["WHEEL"], context)
        addVuhDoBindingSet(keyboardAssignments["HOSTILE_WHEEL"], context)
    end
end
