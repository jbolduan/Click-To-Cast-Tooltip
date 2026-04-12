local _, addonTable = ...

addonTable.clickBindingHandlers = addonTable.clickBindingHandlers or {}

function addonTable.clickBindingHandlers.IsCliqueAvailable()
    --@diagnostic disable-next-line: undefined-global
    return Clique and Clique.db and Clique.db.profile and Clique.db.profile.bindings
end

function addonTable.clickBindingHandlers.ProcessCliqueBindings(context)
    local db = context.db

    --@diagnostic disable-next-line: undefined-global
    if db.showCliqueBindings == false or not (Clique and Clique.db and Clique.db.profile and Clique.db.profile.bindings) then
        return
    end

    --@diagnostic disable-next-line: undefined-global
    local profile = Clique.db.profile

    for _, binding in pairs(profile.bindings) do
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
                local actionBindingType = nil
                local spellIdentifier = nil

                if binding.type == "target" then
                    actionName = "Target"
                elseif binding.type == "menu" then
                    actionName = "Open Menu"
                elseif binding.spell then
                    actionBindingType = "spell"
                    spellIdentifier = binding.spell
                end

                local buttonText = binding.key
                if buttonText and type(buttonText) == "string" then
                    local lowerKey = buttonText:lower()
                    local hasShift = lowerKey:find("shift") ~= nil
                    local hasCtrl = lowerKey:find("ctrl") ~= nil or lowerKey:find("control") ~= nil
                    local hasAlt = lowerKey:find("alt") ~= nil

                    local modifiersMatch = (hasShift == context.isShiftKeyDown)
                        and (hasCtrl == context.isControlKeyDown)
                        and (hasAlt == context.isAltKeyDown)

                    if modifiersMatch then
                        local bindingKey = "clique|" .. buttonText .. "|" .. actionName
                        if not context.shownBindings[bindingKey] then
                            context.shownBindings[bindingKey] = true
                            context.emitBinding(buttonText, actionName, actionBindingType, spellIdentifier)
                        end
                    end
                end
            end
        end
    end
end
