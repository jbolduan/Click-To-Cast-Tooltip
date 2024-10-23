local addonName, addonTable = ...

-- These are the default settings for new installs of the addon.
local defaults = {
    buttonColor = "ffff0000",
    actionColor = "ff00ff00",
    dividerColor = "ffffffff",
    showHeader = false,
    showFooter = false,
    showTooltip = true,
    showNewLineTop = false,
    showNewLineBottom = false
}

function setDefaultSettings(tbl, defaults, force)
    if (force) then
        for key, value in next, defaults do
            if (type(tbl[key]) == "table") then
                setDefaultSettings(tbl[key], defaults[key], force)
            else
                print("Setting default value for key: " .. key)
                ClickToCastTooltipDB[key] = value
            end
        end
    else
        for key, value in next, defaults do
            if (type(tbl[key]) == "table") then
                setDefaultSettings(tbl[key], defaults[key])
            elseif tbl[key] == nil then
                -- print("Setting default value for key: " .. key)
                DEFAULT_CHAT_FRAME:AddMessage("Setting default value for key: " .. key)
                ClickToCastTooltipDB[key] = value
            end
        end
    end
end

ClickToCastTooltipDB = ClickToCastTooltipDB or CopyTable(defaults)
do
    -- Set any values to default if they're currently blank.
    setDefaultSettings(ClickToCastTooltipDB, defaults)

    if (type(ClickToCastTooltipDB.buttonColor) == "table") then
        ClickToCastTooltipDB.buttonColor = defaults.buttonColor
    end

    if (type(ClickToCastTooltipDB.actionColor) == "table") then
        ClickToCastTooltipDB.actionColor = defaults.actionColor
    end

    if (type(ClickToCastTooltipDB.dividerColor) == "table") then
        ClickToCastTooltipDB.dividerColor = defaults.dividerColor
    end
end

local function OnSettingsChanged(_, setting, value)
    local variable = setting:GetVariable()
    ClickToCastTooltipDB[variable] = value
    print("Setting changed: " .. setting:GetVariable(), value)
end

local category, layout = Settings.RegisterVerticalLayoutCategory(addonName)

-- Create checkbox which will allow the user to toggle the tooltip on and off.
do
    local variable = "showTooltip"
    local variableTbl = ClickToCastTooltipDB
    local variableKey = "toggle"
    local name = "Show tooltip"
    local tooltip = "Show the click to cast binding when hovering over a unit frame."
    local defaultValue = true

    local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue),
        name, defaultValue)
    Settings.CreateCheckbox(category, setting, tooltip)
    Settings.SetOnValueChangedCallback(variable, OnSettingsChanged)
end

layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Dashed Header/Footer"))

-- Create checkbox which will allow the user to toggle the header on the tooltip.
do
    local variable = "showHeader"
    local variableTbl = ClickToCastTooltipDB
    local variableKey = "toggle"
    local name = "Show dashed header above the tooltip."
    local tooltip = "Show the dashed line header on the tooltip."
    local defaultValue = true

    local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue),
        name, defaultValue)
    Settings.CreateCheckbox(category, setting, tooltip)
    Settings.SetOnValueChangedCallback(variable, OnSettingsChanged)
end

-- Create checkbox which will allow the user to toggle the footer on the tooltip.
do
    local variable = "showFooter"
    local variableTbl = ClickToCastTooltipDB
    local variableKey = "toggle"
    local name = "Show dashed footer below the tooltip."
    local tooltip = "Show the dashed line footer on the tooltip."
    local defaultValue = true

    local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue),
        name, defaultValue)
    Settings.CreateCheckbox(category, setting, tooltip)
    Settings.SetOnValueChangedCallback(variable, OnSettingsChanged)
end

layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Empty Line Header/Footer"))

-- Create checkbox which will allow the user to toggle the new line at the top of the tooltip.
do
    local variable = "showNewLineTop"
    local variableTbl = ClickToCastTooltipDB
    local variableKey = "toggle"
    local name = "Show new line above the tooltip."
    local tooltip = "Show a new line at the top of the tooltip."
    local defaultValue = false

    local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue),
        name, defaultValue)
    Settings.CreateCheckbox(category, setting, tooltip)
    Settings.SetOnValueChangedCallback(variable, OnSettingsChanged)
end

-- Create checkbox which will allow the user to toggle the new line at the bottom of the tooltip.
do
    local variable = "showNewLineBottom"
    local variableTbl = ClickToCastTooltipDB
    local variableKey = "toggle"
    local name = "Show new line below the tooltip."
    local tooltip = "Show a new line at the bottom of the tooltip."
    local defaultValue = false

    local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue),
        name, defaultValue)
    Settings.CreateCheckbox(category, setting, tooltip)
    Settings.SetOnValueChangedCallback(variable, OnSettingsChanged)
end

layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Tooltip Colors"))

-- Create a button which will allow the user to change the color of the click to cast button text.
do
    local button = CreateSettingsButtonInitializer("Button Text Color", "Button Text Color", function()
        ShowColorPicker("buttonColor", ButtonColorCallback)
    end, "Change the color of the button text on the tooltip.", true)

    layout:AddInitializer(button)
end

do
    local button = CreateSettingsButtonInitializer("Action Text Color", "Action Text Color", function()
        ShowColorPicker("actionColor", ActionColorCallback)
    end, "Change the color of the action text on the tooltip.", true)

    layout:AddInitializer(button)
end

do
    local button = CreateSettingsButtonInitializer("Divider Color", "Divider Color", function()
        ShowColorPicker("dividerColor", DividerColorCallback)
    end, "Change the color of the divider on the tooltip.", true)

    layout:AddInitializer(button)
end

do
    local button = CreateSettingsButtonInitializer("Reset Colors", "Reset Colors", function()
        ClickToCastTooltipDB.buttonColor = defaults.buttonColor
        ClickToCastTooltipDB.actionColor = defaults.actionColor
        ClickToCastTooltipDB.dividerColor = defaults.dividerColor
    end, "Reset the colors to their default values.", true)

    layout:AddInitializer(button)
end

Settings.RegisterAddOnCategory(category)

-- -- Shows the color picker with the callback function
function ShowColorPicker(colorToChange, changedCallback)
    if (colorToChange == nil) then
        throw "Color to change is nil"
    elseif (colorToChange == "buttonColor") then
        buttonColor = CreateColorFromHexString(ClickToCastTooltipDB.buttonColor)
        r, g, b, a = buttonColor.r, buttonColor.g, buttonColor.b, buttonColor.a
    elseif (colorToChange == "actionColor") then
        actionColor = CreateColorFromHexString(ClickToCastTooltipDB.actionColor)
        r, g, b, a = actionColor.r, actionColor.g, actionColor.b, actionColor.a
    elseif (colorToChange == "dividerColor") then
        dividerColor = CreateColorFromHexString(ClickToCastTooltipDB.dividerColor)
        r, g, b, a = dividerColor.r, dividerColor.g, dividerColor.b, dividerColor.a
    end

    if (ColorPickerFrame.SetupColorPickerAndShow == nil) then
        ColorPickerFrame.func = changedCallback
        ColorPickerFrame.hasOpacity = (a ~= nil)
        ColorPickerFrame.opacityFunc = changedCallback
        ColorPickerFrame.opacity = a
        ColorPickerFrame.previousValues = {r, g, b, a}
        ColorPickerFrame.cancelFunc = changedCallback
        ColorPickerFrame.extraInfo = changedCallback
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame:Show()
    else
        local info = {}
        info.swatchFunc = changedCallback
        info.cancelFunc = ColorPickerCancel
        info.hasOpacity = (a ~= nil)
        info.previousValues = {r, g, b, a}
        info.r, info.g, info.b, info.opacity = r, g, b, a
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end
end

-- Function to be called when color picker is canceled
function ColorPickerCancel()
    -- Do nothing
end

-- Callback function to protect the color picker from no selection being made
function ButtonColorCallback(restore)
    local newR, newG, newB, newA

    if restore then
        -- The user bailed , we extreact the old color from the table created by ShowColorPicker.
        newR, newG, newB, newA = unpack(restore)
    else
        -- Something changed
        newA, newR, newG, newB = ColorPickerFrame:GetColorAlpha(), ColorPickerFrame:GetColorRGB()
    end

    ClickToCastTooltipDB.buttonColor = string.format("%02x%02x%02x%02x", newA * 255, newR * 255, newG * 255, newB * 255)
    print("Button color changed to: " .. tostring(ClickToCastTooltipDB.buttonColor))
end

function ActionColorCallback(restore)
    local newR, newG, newB, newA

    if restore then
        -- The user bailed , we extreact the old color from the table created by ShowColorPicker.
        newR, newG, newB, newA = unpack(restore)
    else
        -- Something changed
        newA, newR, newG, newB = ColorPickerFrame:GetColorAlpha(), ColorPickerFrame:GetColorRGB()
    end

    ClickToCastTooltipDB.actionColor = string.format("%02x%02x%02x%02x", newA * 255, newR * 255, newG * 255, newB * 255)
end

function DividerColorCallback(restore)
    local newR, newG, newB, newA

    if restore then
        -- The user bailed , we extreact the old color from the table created by ShowColorPicker.
        newR, newG, newB, newA = unpack(restore)
    else
        -- Something changed
        newA, newR, newG, newB = ColorPickerFrame:GetColorAlpha(), ColorPickerFrame:GetColorRGB()
    end

    ClickToCastTooltipDB.dividerColor =
        string.format("%02x%02x%02x%02x", newA * 255, newR * 255, newG * 255, newB * 255)
end

-- Add the supported slash commands
SLASH_CLICKTOCASTTT1 = "/clicktocasttooltip"
SLASH_CLICKTOCASTTT2 = "/ctctt"

-- Handle the slash commands
SlashCmdList["CLICKTOCASTTT"] = function(msg)
    Settings.OpenToCategory(category.ID)
end
