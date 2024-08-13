local addonName, addonTable = ...

-- Setup the tooltip frame
local ttFrame = CreateFrame("GameTooltip", "ClickToCastTooltipFrame", UIParent, "GameTooltipTemplate")
local AddTooltipPostCall = TooltipDataProcessor.AddTooltipPostCall

-- Hook into the modifier state changed event to update the tooltip
ttFrame:SetScript("OnEvent", function(self, event, arg, ...)
    if ttFrame:IsShown() and event == "MODIFIER_STATE_CHANGED" then
        ClickToCastTooltip_GenerateTooltip(ttFrame)
    end
end)

-- Tooltip line handler which parses all the click to cast bindings to make sure we only display
-- the ones that are relevant to the current modifier state.
function tooltipLine(binding, tooltip)
    local modifier = C_ClickBindings.GetStringFromModifiers(binding.modifiers)
    local actionName = tostring(binding.actionID)
    local isShiftKeyDown = IsShiftKeyDown()
    local isAltKeyDown = IsAltKeyDown()
    local isControlKeyDown = IsControlKeyDown()

    local buttonColor = CreateColor(addonTable.db.buttonColor.r, addonTable.db.buttonColor.g,
        addonTable.db.buttonColor.b, addonTable.db.buttonColor.a)
    local actionColor = CreateColor(addonTable.db.actionColor.r, addonTable.db.actionColor.g,
        addonTable.db.actionColor.b, addonTable.db.actionColor.a)

    if binding.type == Enum.ClickBindingType.Interaction then
        if binding.actionID == Enum.ClickBindingInteraction.Target then
            actionName = "Target"
        elseif binding.actionID == Enum.ClickBindingInteraction.OpenContextMenu then
            actionName = "Open Context Menu"
        end
    elseif binding.type == Enum.ClickBindingType.Spell then
        -- actionName = GetSpellInfo(binding.actionID)
        actionName = C_Spell.GetSpellName(binding.actionID)

    elseif binding.type == Enum.ClickBindingType.Macro then
        actionName = GetMacroInfo(binding.actionID)
    end

    if (isShiftKeyDown and isAltKeyDown and isControlKeyDown) and (modifier == "ALT-SHIFT-CTRL") then
        tooltip:AddLine(buttonColor:WrapTextInColorCode(binding.button) .. " - " ..
                            actionColor:WrapTextInColorCode(actionName))
    elseif (isShiftKeyDown and isAltKeyDown) and (modifier == "ALT-SHIFT") and not isControlKeyDown then
        tooltip:AddLine(buttonColor:WrapTextInColorCode(binding.button) .. " - " ..
                            actionColor:WrapTextInColorCode(actionName))
    elseif (isControlKeyDown and isAltKeyDown) and (modifier == "ALT-CTRL") and not isShiftKeyDown then
        tooltip:AddLine(buttonColor:WrapTextInColorCode(binding.button) .. " - " ..
                            actionColor:WrapTextInColorCode(actionName))
    elseif (isShiftKeyDown and isControlKeyDown) and (modifier == "SHIFT-CTRL") and not isAltKeyDown then
        tooltip:AddLine(buttonColor:WrapTextInColorCode(binding.button) .. " - " ..
                            actionColor:WrapTextInColorCode(actionName))
    elseif isShiftKeyDown and (modifier == "SHIFT") and not (isAltKeyDown or isControlKeyDown) then
        tooltip:AddLine(buttonColor:WrapTextInColorCode(binding.button) .. " - " ..
                            actionColor:WrapTextInColorCode(actionName))
    elseif isAltKeyDown and (modifier == "ALT") and not (isShiftKeyDown or isControlKeyDown) then
        tooltip:AddLine(buttonColor:WrapTextInColorCode(binding.button) .. " - " ..
                            actionColor:WrapTextInColorCode(actionName))
    elseif isControlKeyDown and (modifier == "CTRL") and not (isShiftKeyDown or isAltKeyDown) then
        tooltip:AddLine(buttonColor:WrapTextInColorCode(binding.button) .. " - " ..
                            actionColor:WrapTextInColorCode(actionName))
    elseif (not isAltKeyDown and not isControlKeyDown and not isShiftKeyDown) and (modifier == "") then
        tooltip:AddLine(buttonColor:WrapTextInColorCode(binding.button) .. " - " ..
                            actionColor:WrapTextInColorCode(actionName))
    end
end

-- Base tooltip handler which generates the tooltip by calling the various functions required.
function ClickToCastTooltip_GenerateTooltip(tooltip)
    local clickBindings = C_ClickBindings.GetProfileInfo();

    if (addonTable.db.showHeader) then
        tooltip:AddLine("---------------------")
        tooltip:AddLine("Active Keybinds:")
    end
    for _, binding in ipairs(clickBindings) do
        tooltipLine(binding, tooltip)
    end
end

-- Register the event handler
ttFrame:RegisterEvent("MODIFIER_STATE_CHANGED")

-- Update when modifier state changes
if AddTooltipPostCall then
    AddTooltipPostCall(Enum.TooltipDataType.Unit, ClickToCastTooltip_GenerateTooltip)
else
    ttFrame:HookScript("OnTooltipSetUnit", "OnTooltipSetUnit", ClickToCastTooltip_GenerateTooltip)
end
