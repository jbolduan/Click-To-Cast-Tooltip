local _, addonTable = ...

addonTable.clickBindingHandlers = addonTable.clickBindingHandlers or {}

local function getEllesmereUIRaidFramesNamespace()
    local ellesmereUI = _G.EllesmereUI
    local moduleNamespaces = ellesmereUI and ellesmereUI._ModuleNS
    local moduleNamespace = moduleNamespaces and moduleNamespaces.EllesmereUIRaidFrames

    if type(moduleNamespace) == "table"
        and type(moduleNamespace.CC_GetActiveBindings) == "function"
        and type(moduleNamespace.CC_GetBindingName) == "function"
        and type(moduleNamespace.CC_FormatKey) == "function" then
        return moduleNamespace
    end
end

function addonTable.clickBindingHandlers.IsEllesmereUIAvailable()
    return getEllesmereUIRaidFramesNamespace() ~= nil
end

local function isEllesmereUIFrame(frame)
    while frame do
        local frameName = frame:GetName()
        if frameName then
            if frameName:match("^EllesmereUIUnitFrames_")
                or frameName:match("^ERFGroupHeader%d+$")
                or frameName == "ERFFlatHeader"
                or frameName == "ERFPartyHeader"
                or frameName == "ERFPartySelfButton"
                or frameName:match("^ERFFriendlyBoss%d+$")
                or frameName:match("^ERFExtraFrame%d+$") then
                return true
            end
        end
        frame = frame:GetParent()
    end

    return false
end

local function parseBindingModifiers(key)
    if type(key) ~= "string" or key == "" then
        return nil
    end

    local remaining = key:upper()
    local modifiers = {
        alt = false,
        ctrl = false,
        shift = false,
        meta = false,
    }

    local prefixes = {
        {key = "ALT-", modifier = "alt"},
        {key = "CTRL-", modifier = "ctrl"},
        {key = "SHIFT-", modifier = "shift"},
        {key = "META-", modifier = "meta"},
    }

    while true do
        local matched = false
        for _, prefix in ipairs(prefixes) do
            if remaining:sub(1, #prefix.key) == prefix.key then
                modifiers[prefix.modifier] = true
                remaining = remaining:sub(#prefix.key + 1)
                matched = true
                break
            end
        end

        if not matched then
            break
        end
    end

    if remaining == "" then
        return nil
    end

    return modifiers
end

function addonTable.clickBindingHandlers.ProcessEllesmereUIBindings(context)
    local db = context.db
    if db.showEllesmereUIBindings == false or not isEllesmereUIFrame(context.hoveredFrame) then
        return
    end

    local moduleNamespace = getEllesmereUIRaidFramesNamespace()
    if not moduleNamespace then
        return
    end

    for _, binding in ipairs(moduleNamespace.CC_GetActiveBindings()) do
        local modifiers = parseBindingModifiers(binding.key)
        local metaMatches = modifiers and modifiers.meta == (context.isMetaKeyDown == true)
        local modifiersMatch = modifiers
            and modifiers.alt == context.isAltKeyDown
            and modifiers.ctrl == context.isControlKeyDown
            and modifiers.shift == context.isShiftKeyDown
            and metaMatches

        if modifiersMatch then
            local actionName = moduleNamespace.CC_GetBindingName(binding)
            local displayKey = moduleNamespace.CC_FormatKey(binding.key)
            local spellIdentifier = binding.type == "spell" and (binding.spellID or binding.spell) or nil
            local dedupeKey = "ellesmereui|" .. tostring(binding.key) .. "|"
                .. tostring(binding.type) .. "|" .. tostring(binding.spellID or binding.spell or binding.macroName or actionName)

            if actionName and actionName ~= "" and not context.shownBindings[dedupeKey] then
                context.shownBindings[dedupeKey] = true
                context.emitBinding(displayKey, actionName, spellIdentifier and "spell" or nil, spellIdentifier)
            end
        end
    end
end
