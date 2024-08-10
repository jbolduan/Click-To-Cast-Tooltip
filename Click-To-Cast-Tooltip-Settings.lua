local addonName, addonTable = ...

local f = CreateFrame("Frame", "ClickToCastTooltipSettingsFrame", InterfaceOptionsFramePanelContainer)
f.name = "Click-To-Cast Tooltip"
local category = Settings.RegisterCanvasLayoutCategory(f, f.name)
f.settingsCategory = category
Settings.RegisterAddOnCategory(category)

local function OnSettingsChanged(_, setting, value)
    local variable = setting:GetVariable()
    addonTable[variable] = value
    print("Setting changed: " .. setting:GetVariable(), value)
end

-- These are the default settings for new installs of the addon.
local defaults = {
    buttonColor = {
        r = 1,
        g = 0,
        b = 0,
        a = 1
    },
    actionColor = {
        r = 0,
        g = 1,
        b = 0,
        a = 1
    },
    showHeader = true
}

-- Check to see if the SavedVariables are already set, if not, set them to the defaults.
function f:OnEvent(event, addOnName)
    if addOnName == "Click-To-Cast-Tooltip" then
        ClickToCastTooltipDB = ClickToCastTooltipDB or CopyTable(defaults)
        addonTable.db = ClickToCastTooltipDB

        -- If any of the default settings are missing, copy them over.
        if ((addonTable.db.buttonColor.r == nil) or (addonTable.db.buttonColor.g == nil) or
            (addonTable.db.buttonColor.b == nil) or (addonTable.db.buttonColor.a == nil)) then
            addonTable.db.buttonColor = CopyTable(defaults.buttonColor)
        end
        if ((addonTable.db.actionColor.r == nil) or (addonTable.db.actionColor.g == nil) or
            (addonTable.db.actionColor.b == nil) or (addonTable.db.actionColor.a == nil)) then
            addonTable.db.actionColor = CopyTable(defaults.actionColor)
        end
        if (addonTable.db.showHeader ~= true and addonTable.db.showHeader ~= false) then
            addonTable.db.showHeader = defaults.showHeader
        end

        self:InitializeOptions()
    end
end

-- Register the event to check for the addon being loaded.
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", f.OnEvent)

-- Create the options panel for the addon.
function f:InitializeOptions()

    -- Create a checkbox which will allow the user to toggle the header on the tooltip.
    local showHeader = CreateFrame("CheckButton", nil, f, "InterfaceOptionsCheckButtonTemplate")
    showHeader:SetPoint("TOPLEFT", 20, -20)
    showHeader.Text:SetText("Show header with divider")
    showHeader:HookScript("OnClick", function(_, btn, down)
        addonTable.db.showHeader = showHeader:GetChecked()
    end)
    showHeader:SetChecked(addonTable.db.showHeader)

    -- Create a button which will allow the user to change the color of the button text.
    local buttonColorPicker = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    buttonColorPicker:SetPoint("TopLeft", showHeader, "TopLeft", 20, -30)
    buttonColorPicker:SetSize(100, 25)
    buttonColorPicker:SetText("Button Text Color")
    buttonColorPicker:SetScript("OnClick", function()
        ShowColorPicker(addonTable.db.buttonColor.r, addonTable.db.buttonColor.g, addonTable.db.buttonColor.b,
            addonTable.db.buttonColor.a, ButtonColorCallback)
    end)

    -- Create a button which will allow the user to change the color of the action text.
    local actionColorPicker = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    actionColorPicker:SetPoint("TopLeft", buttonColorPicker, "TopLeft", 0, -30)
    actionColorPicker:SetSize(100, 25)
    actionColorPicker:SetText("Action Text Color")
    actionColorPicker:SetScript("OnClick", function()
        ShowColorPicker(addonTable.db.actionColor.r, addonTable.db.actionColor.g, addonTable.db.actionColor.b,
            addonTable.db.actionColor.a, ActionColorCallback)
    end)

    -- Create a button which will allow the user to reset the settings to the default values.
    local resetSettings = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    resetSettings:SetPoint("TopLeft", actionColorPicker, "TopLeft", 0, -30)
    resetSettings:SetSize(100, 25)
    resetSettings:SetText("Reset Settings")
    resetSettings:SetScript("OnClick", function()
        addonTable.db = CopyTable(defaults)
    end)
end

-- Shows the color picker with the callback function
function ShowColorPicker(r, g, b, a, changedCallback)
    -- print("r value: " .. r)
    -- print("g value: " .. g)
    -- print("b value: " .. b)
    -- print("a value: " .. a)

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
        info.cancelFunc = changedCallback
        info.hasOpacity = (a ~= nil)
        -- info.opacity = a
        info.previousValues = {r, g, b, a}
        info.r, info.g, info.b, info.opacity = r, g, b, a
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end
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

    addonTable.db.buttonColor.r, addonTable.db.buttonColor.g, addonTable.db.buttonColor.b, addonTable.db.buttonColor.a =
        newR, newG, newB, newA
    -- Update UI elements
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

    addonTable.db.actionColor.r, addonTable.db.actionColor.g, addonTable.db.actionColor.b, addonTable.db.actionColor.a =
        newR, newG, newB, newA
    -- Update UI elements
end

-- Add the supported slash commands
SLASH_CLICKTOCASTTT1 = "/clicktocasttooltip"
SLASH_CLICKTOCASTTT2 = "/ctctt"

-- Handle the slash commands
SlashCmdList["CLICKTOCASTTT"] = function(msg)
    if msg == "buttonColor" then
        ShowColorPicker(addonTable.db.buttonColor.r, addonTable.db.buttonColor.g, addonTable.db.buttonColor.b,
            addonTable.db.buttonColor.a, ColorCallback)
    elseif msg == "currentButtonColor" then
        print("Current Color: " .. addonTable.db.buttonColor.r .. ", " .. addonTable.db.buttonColor.g .. ", " ..
                  addonTable.db.buttonColor.b .. ", " .. addonTable.db.buttonColor.a)
    elseif msg == "actionColor" then
        ShowColorPicker(addonTable.db.actionColor.r, addonTable.db.actionColor.g, addonTable.db.actionColor.b,
            addonTable.db.actionColor.a, ColorCallback)
    elseif msg == "currentActionColor" then
        print("Current Color: " .. addonTable.db.actionColor.r .. ", " .. addonTable.db.actionColor.g .. ", " ..
                  addonTable.db.actionColor.b .. ", " .. addonTable.db.actionColor.a)
    elseif msg == "help" then
        print("Click-To-Cast-Tooltip")
        print("/ctctt buttonColor - Opens the color picker for the button text color")
        print("/ctctt currentButtonColor - Prints the current button text color")
        print("/ctctt actionColor - Opens the color picker for the action text color")
        print("/ctctt currentActionColor - Prints the current action text color")
    else
        Settings.OpenToCategory(f.settingsCategory.ID)
    end
end
