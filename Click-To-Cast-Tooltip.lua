local ttFrame = CreateFrame("GameTooltip", "ClickToCastTooltipFrame", UIParent, "GameTooltipTemplate")
local AddTooltipPostCall = TooltipDataProcessor.AddTooltipPostCall

ttFrame:SetScript("OnEvent", function(self, event, arg, ...)
    if ttFrame:IsShown() and event == "MODIFIER_STATE_CHANGED" then
        ClickToCastTooltip_GenerateTooltip(ttFrame)
    end
end)

function tooltipLine(binding, tooltip)
    local modifier = C_ClickBindings.GetStringFromModifiers(binding.modifiers)
    local actionName = tostring(binding.actionID)
    local isShiftKeyDown = IsShiftKeyDown()
    local isAltKeyDown = IsAltKeyDown()
    local isControlKeyDown = IsControlKeyDown()

    if binding.type == Enum.ClickBindingType.Interaction then
        if binding.actionID == Enum.ClickBindingInteraction.Target then
            actionName = "Target"
        elseif binding.actionID == Enum.ClickBindingInteraction.OpenContextMenu then
            actionName = "Open Context Menu"
        end
    elseif binding.type == Enum.ClickBindingType.Spell then
        actionName = GetSpellInfo(binding.actionID)
    elseif binding.type == Enum.ClickBindingType.Macro then
        actionName = GetMacroInfo(binding.actionID)
    end

    if (isShiftKeyDown and isAltKeyDown and isControlKeyDown) and (modifier == "ALT-SHIFT-CTRL") then
        tooltip:AddLine(binding.button .. " - " .. actionName)
    elseif (isShiftKeyDown and isAltKeyDown) and (modifier == "ALT-SHIFT") and not isControlKeyDown then
        tooltip:AddLine(binding.button .. " - " .. actionName)
    elseif (isControlKeyDown and isAltKeyDown) and (modifier == "ALT-CTRL") and not isShiftKeyDown then
        tooltip:AddLine(binding.button .. " - " .. actionName)
    elseif (isShiftKeyDown and isControlKeyDown) and (modifier == "SHIFT-CTRL") and not isAltKeyDown then
        tooltip:AddLine(binding.button .. " - " .. actionName)
    elseif isShiftKeyDown and (modifier == "SHIFT") and not (isAltKeyDown or isControlKeyDown) then
        tooltip:AddLine(binding.button .. " - " .. actionName)
    elseif isAltKeyDown and (modifier == "ALT") and not (isShiftKeyDown or isControlKeyDown) then
        tooltip:AddLine(binding.button .. " - " .. actionName)
    elseif isControlKeyDown and (modifier == "CTRL") and not (isShiftKeyDown or isAltKeyDown) then
        tooltip:AddLine(binding.button .. " - " .. actionName)
    end
end

function ClickToCastTooltip_GenerateTooltip(tooltip)
    local clickBindings = C_ClickBindings.GetProfileInfo();

    tooltip:AddLine("---------------------")
    tooltip:AddLine("Active Keybinds:")
    for _, binding in ipairs(clickBindings) do
        tooltipLine(binding, tooltip)
    end
end

ttFrame:RegisterEvent("MODIFIER_STATE_CHANGED")

if AddTooltipPostCall then
    AddTooltipPostCall(Enum.TooltipDataType.Unit, ClickToCastTooltip_GenerateTooltip)
else
    ttFrame:HookScript("OnTooltipSetUnit", "OnTooltipSetUnit", ClickToCastTooltip_GenerateTooltip)
end
